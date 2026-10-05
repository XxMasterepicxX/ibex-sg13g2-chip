/* flash_soc: 4 KB IMEM at 0x0 holds code, constants and the .data load image; 4 KB DMEM at 0x10000. */
MEMORY {
  IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
  DMEM (rw)  : ORIGIN = 0x00010000, LENGTH = 4K
}
ENTRY(_start)
SECTIONS {
  .vectors : { KEEP(*(.vectors)) } > IMEM
  .text    : { *(.text*) *(.rodata*) *(.srodata*) . = ALIGN(4); } > IMEM
  .data    : { _data_start = .; *(.data*) *(.sdata*) . = ALIGN(4); _data_end = .; } > DMEM AT > IMEM
  _data_lma = LOADADDR(.data);
  .bss     : { _bss_start = .; *(.bss*) *(.sbss*) *(COMMON) . = ALIGN(4); _bss_end = .; } > DMEM
  _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
}
