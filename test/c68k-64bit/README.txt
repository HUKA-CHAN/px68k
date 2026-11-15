C68K の 64bit 化が元の 32bit 版と同じ動作をするか確かめる差分テストです。

  m68k-linux-gnu-as -m68000 --register-prefix-optional -o test.o test.s
  m68k-linux-gnu-ld -Ttext=0 --oformat binary -o test.bin test.o
  gcc -m32 -O2 -fno-strict-aliasing -w -I../../m68000 -I../../x11 -I../../win32api -I../../x68k \
      $(sdl2-config --cflags) harness.c ../../m68000/c68k.c -o h32
  gcc -m64 (同上) -o h64
  ./h32 test.bin > out32.txt ; ./h64 test.bin > out64.txt ; cmp out32.txt out64.txt

分岐 (Bcc/BSR/DBcc/JMP/JSR)、MOVEM 全形式、例外 (TRAP/CHK/ゼロ除算/不正命令/
特権違反/割り込み)、フェッチバンク境界をまたぐ実行、上位 8bit 付きアドレスを通します。
