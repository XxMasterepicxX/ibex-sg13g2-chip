# Ibex vector table at 0x00 (mtvec = boot_addr, vectored), reset entry at 0x80.
  .section .vectors, "ax"
  .option norvc
  .global _start
vectors:
  .rept 32
  j trap
  .endr
_start:
  j reset

  .section .text
reset:
  la sp, _stack_top
  # Copy .data from its load image in IMEM to DMEM, then clear .bss.
  la a0, _data_lma
  la a1, _data_start
  la a2, _data_end
1:bge a1, a2, 2f
  lw t0, 0(a0)
  sw t0, 0(a1)
  addi a0, a0, 4
  addi a1, a1, 4
  j 1b
2:la a1, _bss_start
  la a2, _bss_end
3:bge a1, a2, 4f
  sw zero, 0(a1)
  addi a1, a1, 4
  j 3b
4:call main
  # main returns the GPIO code; bit 7 marks done.
  ori a0, a0, 0x80
  li t0, 0x00020000
  sw a0, 0(t0)
5:wfi
  j 5b

trap:
  # Any exception or interrupt is a failure: done with all failure bits set.
  li t0, 0x00020000
  li t1, 0xff
  sw t1, 0(t0)
6:j 6b
