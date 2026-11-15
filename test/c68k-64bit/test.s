| 68000 core differential test (runs on bare c68k, no X68000 hardware)
	.text
	.org 0
vectors:
	.long 0x00100000		| SSP
	.long start			| PC
	.long h_generic, h_generic	| bus, address
	.long h_illegal			| 4 illegal
	.long h_zdiv			| 5
	.long h_chk			| 6
	.long h_trapv			| 7
	.long h_priv			| 8
	.long h_generic			| 9 trace
	.long h_linea			| 10
	.long h_linef			| 11
	.fill 12, 4, 0			| 12-23
	.long h_irq, h_irq, h_irq, h_irq, h_irq, h_irq, h_irq, h_irq	| 24-31 autovec
	.long h_trap0, h_trap1		| 32,33
	.fill 14, 4, 0
	.org 0x400
start:
	move.w	#0x2000, sr		| enable irqs, supervisor
	lea	0x00100000, sp
	moveq	#0, d7			| checksum
	lea	0x00020000, a6		| scratch ram
	move.l	#0x12345678, d0
	move.l	#0x9abcdef0, d1
	move.l	#0x0f1e2d3c, d2
	move.l	#0x55aa33cc, d3
	move.l	#0x80000001, d4
	move.l	#0x7fffffff, d5
	move.w	#1500, d6		| outer loop counter
	lea	0x00021000, a0
	lea	0x00022000, a1
	lea	0x00023000, a2
	lea	0x00024000, a3
	lea	0x00025000, a4
	lea	0x00026000, a5
	| copy ramcode to RAM at several places (incl. bank boundary + top of RAM)
	lea	ramcode(pc), a0
	lea	0x0003fff0, a1		| crosses 0x40000 bank boundary
	moveq	#(ramcode_end-ramcode)/2-1, d0
1:	move.w	(a0)+, (a1)+
	dbra	d0, 1b
	lea	ramcode(pc), a0
	lea	0x000dfff0, a1		| near top of main ram
	moveq	#(ramcode_end-ramcode)/2-1, d0
1:	move.w	(a0)+, (a1)+
	dbra	d0, 1b
	lea	0x00021000, a0
	lea	0x00022000, a1
	move.l	#0x12345678, d0

mainloop:
	| ---- arithmetic / logic
	add.l	d1, d0
	addx.l	d2, d3
	sub.w	d4, d5
	subx.b	d0, d1
	eor.l	d3, d2
	rol.l	#3, d2
	ror.w	#5, d3
	roxl.l	#1, d4
	roxr.b	#2, d5
	asl.w	#2, d0
	asr.l	#7, d1
	lsr.l	d6, d2
	mulu.w	d0, d3
	muls.w	d1, d4
	swap	d3
	ext.w	d4
	ext.l	d4
	neg.l	d5
	negx.w	d0
	not.b	d1
	abcd	d0, d1
	sbcd	d2, d3
	tas	d5
	bchg	d6, d2
	bset	#7, d3
	bclr	#31, d4
	btst	d0, d1
	sne	d5
	exg	d0, a0
	add.l	d0, d7
	exg	d0, a0
	move.w	sr, d5
	add.w	d5, d7
	| ---- division (avoid zero)
	move.l	d0, d5
	or.w	#1, d5
	move.l	d1, -(sp)
	divu.w	d5, d1
	bvc.s	1f
	addq.l	#3, d7
1:	move.l	(sp), d1
	divs.w	d5, d1
	bvc.s	1f
	addq.l	#5, d7
1:	add.l	d1, d7
	move.l	(sp)+, d1
	| ---- memory & movem (all forms)
	movem.l	d0-d7/a0-a6, -(sp)
	movem.w	d0-d3/a1-a2, (a6)
	movem.l	d2-d5/a3-a4, 0x40(a6)
	movem.w	(a6), d0-d3/a1-a2
	movem.l	0x40(a6), d2-d5/a3-a4
	movem.l	d0-d1, 0x00027000
	movem.l	0x00027000, d2-d3
	movem.l	tbl(pc), d0-d1
	add.l	d0, 0x80(a6)
	add.l	d1, 0x84(a6)
	movem.l	(sp)+, d0-d7/a0-a6
	add.l	0x80(a6), d7
	add.l	0x84(a6), d7
	movem.w	d0-d7, -(sp)
	movem.w	(sp)+, d0-d3
	movem.w	(sp)+, a2-a5
	add.l	a2, d7
	add.l	a5, d7
	lea	0x00023000, a2
	lea	0x00024000, a3
	lea	0x00025000, a4
	lea	0x00026000, a5
	move.b	d0, (a0)+
	move.w	d1, (a1)+
	move.l	d2, -(a2)
	move.l	(a2)+, d5
	add.l	d5, d7
	movep.l	d3, 0(a3)
	movep.w	1(a3), d5
	add.w	d5, d7
	cmpm.b	(a4)+, (a5)+
	scs	d5
	add.b	d5, d7
	link	a4, #-16
	move.l	d0, -4(a4)
	move.l	d1, -8(a4)
	add.l	-8(a4), d7
	unlk	a4
	pea	tbl(pc)
	move.l	(sp)+, d5
	add.l	d5, d7
	move.w	d6, d5
	and.w	#3, d5
	add.w	d5, d5
	move.w	wtbl(pc,d5.w), d5
	add.w	d5, d7
	bra.s	9f
wtbl:	.word	0x1111, 0x2222, 0x3333, 0x4444
9:
	cmpa.l	#0x00021800, a0
	bcs.s	1f
	lea	0x00021000, a0
	lea	0x00022000, a1
1:
	| ---- control flow
	bsr.w	sub_near
	bsr.w	sub_far
	bsr.w	sub_back
	jsr	sub_far(pc)
	jsr	sub_near
	lea	sub_far(pc), a5
	jsr	(a5)
	lea	0x00026000, a5
	move.w	d6, d5
	and.w	#3, d5
	add.w	d5, d5
	move.w	jtbl(pc,d5.w), d5
	jmp	jtbl(pc,d5.w)
jtbl:	.word	j0-jtbl, j1-jtbl, j2-jtbl, j3-jtbl
j0:	addq.l	#1, d7
	bra.s	jdone
j1:	addq.l	#2, d7
	bra.w	jdone
j2:	addq.l	#3, d7
	jmp	jdone
j3:	addq.l	#4, d7
	jmp	jdone(pc)
jdone:
	| conditional branches, taken and not
	cmp.l	d0, d1
	bhi.s	1f
	addq.l	#1, d7
1:	bge.w	1f
	addq.l	#2, d7
1:	bmi.s	1f
	addq.l	#4, d7
1:	bvs.w	1f
	addq.l	#8, d7
1:	moveq	#5, d5
2:	add.l	d5, d7
	dbra	d5, 2b
	moveq	#3, d5
2:	subq.w	#1, d5
	dbeq	d5, 2b
	add.w	d5, d7
	| ---- exceptions
	trap	#0
	trap	#1
	move.w	d6, d5
	and.w	#7, d5
	chk	#4, d5			| sometimes traps
	moveq	#0, d5
	move.l	d0, -(sp)
	divu.w	d5, d0			| zero divide
	move.l	(sp)+, d0
	.word	0x4afc			| illegal
	.word	0xa123			| line-a
	.word	0xf456			| line-f
	move.w	#0x7fff, d5
	addq.w	#1, d5
	trapv
	| user mode round trip (privilege violation brings us back)
	move.l	sp, d5
	move.l	#0x000f0000, a5
	move.l	a5, usp
	move.w	#0x0000, sr		| -> user mode
	addq.l	#7, d7
	move.w	#0x2000, sr		| privileged in user mode -> exception; handler restores S
	lea	0x00026000, a5
	| ---- code in RAM, crossing a fetch bank boundary, and at top of RAM
	jsr	0x0003fff0
	jsr	0x000dfff0
	| ---- 24bit address wrap (top byte ignored)
	jsr	0xff000000+sub_far
	jmp	0x55000000+hi_ret
hi_ret:
	bsr.w	sub_far
	lea	hi_done(pc), a5
	move.l	a5, d5
	and.l	#0x00ffffff, d5
	move.l	d5, a5
	jmp	(a5)
hi_done:
	lea	0x00026000, a5
	add.l	d0, d7
	rol.l	#1, d7
	add.l	d3, d7
	subq.w	#1, d6
	bne.w	mainloop

	move.l	d7, 0x00028000
	stop	#0x2700
	bra.s	.

tbl:	.long	0x01020304, 0x05060708
	.word	0x1111, 0x2222, 0x3333, 0x4444

sub_back:
	addq.l	#1, d7
	rts
sub_near:
	add.l	#0x1010, d7
	bsr.s	sub_back
	bsr.w	sub_back		| negative 16bit displacement
	rts

h_irq:	addq.l	#1, 0x00028010
	add.l	#0x100, d7
	rte
h_trap0:
	add.l	#0x33, d7
	rte
h_trap1:
	move.w	(sp), d5		| stacked SR
	add.w	d5, d7
	move.l	2(sp), d5		| stacked PC
	add.l	d5, d7
	rte
h_chk:	add.l	#0x77, d7
	rte
h_zdiv:	add.l	#0x99, d7
	rte
h_trapv: add.l	#0xbb, d7
	rte
h_illegal:
h_linea:
h_linef:
	add.l	#0xdd, d7
	addq.l	#2, 2(sp)		| skip the opcode
	rte
h_priv:	add.l	#0xff, d7
	or.w	#0x2000, (sp)		| return in supervisor mode
	addq.l	#4, 2(sp)		| skip "move #imm,sr"
	rte
h_generic:
	add.l	#0xeeee, d7
	rte

	.fill	0x3000, 1, 0x4e		| padding so that sub_far needs 16bit disp
sub_far:
	add.l	#0x2020, d7
	bsr.w	sub_back		| large negative displacement
	move.l	(sp), d5		| return address (may have top byte)
	add.l	d5, d7
	rts

ramcode:				| position independent
	add.l	#0x4040, d7
	nop
	nop
	nop
	nop
	nop
	nop
	moveq	#3, d5
1:	add.l	d5, d7			| loop spans the bank boundary
	nop
	nop
	bsr.s	2f
	dbra	d5, 1b
	lea	1b(pc), a5
	add.l	a5, d7
	rts
2:	addq.l	#1, d7
	rts
ramcode_end:
