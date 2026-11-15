// differential harness for c68k: build with -m32 and -m64 and compare output
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "c68k.h"

static unsigned char *MEM;          // 16MB, stored word-swapped like px68k
DWORD BusErrHandling = 0, BusErrAdr = 0;



static UINT8 rb(UINT32 a){ return MEM[(a & 0xffffff) ^ 1]; }
static UINT16 rw(UINT32 a){ a &= 0xfffffe; return *(UINT16*)(MEM + a); }
static void wb(UINT32 a, UINT8 d){ MEM[(a & 0xffffff) ^ 1] = d; }
static void ww(UINT32 a, UINT16 d){ a &= 0xfffffe; *(UINT16*)(MEM + a) = d; }
static INT32 irqcb(INT32 l){ return -1; }

static uint32_t crc(const unsigned char *p, size_t n){
	uint32_t c = 0xffffffff; size_t i; int k;
	for (i = 0; i < n; i++){ c ^= p[i]; for (k = 0; k < 8; k++) c = (c >> 1) ^ (0xedb88320 & -(c & 1)); }
	return ~c;
}

int main(int argc, char **argv){
	FILE *fp = fopen(argv[1], "rb"); size_t n, i; int step;
	// put the 16MB block at an "unfriendly" place on 64bit hosts
	MEM = malloc(0x1000000 + 16);
	memset(MEM, 0, 0x1000000);
	n = fread(MEM, 1, 0x100000, fp); fclose(fp);
	for (i = 0; i < n + 1; i += 2){ unsigned char t = MEM[i]; MEM[i] = MEM[i+1]; MEM[i+1] = t; }
	C68k_Init(&C68K);
	C68k_Set_ReadB(&C68K, rb); C68k_Set_ReadW(&C68K, rw);
	C68k_Set_WriteB(&C68K, wb); C68k_Set_WriteW(&C68K, ww);
	C68k_Set_Fetch(&C68K, 0x000000, 0xffffff, (uintptr_t)MEM);
	C68k_Reset(&C68K);
	C68k_Set_Reg(&C68K, C68K_A7, (rw(0) << 16) | rw(2));
	C68k_Set_Reg(&C68K, C68K_PC, (rw(4) << 16) | rw(6));
	for (step = 0; step < 40000; step++){
		C68k_Exec(&C68K, 200);
		if (step % 7 == 3) C68k_Set_IRQ(&C68K, 1 + (step % 6), HOLD_LINE);
		if (step % 50 == 0 || step > 39990){
			printf("%d pc=%08x sr=%04x", step, C68k_Get_Reg(&C68K, C68K_PC), C68k_Get_Reg(&C68K, C68K_SR));
			for (i = 0; i < 16; i++) printf(" %08x", C68K.D[i]);
			printf("\n");
		}
	}
	printf("halt=%d result=%08x%08x irqs=%08x%08x memcrc=%08x\n", C68K.HaltState, rw(0x28000), rw(0x28002), rw(0x28010), rw(0x28012), crc(MEM, 0x1000000));
	return 0;
}
