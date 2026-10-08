OUTPUT_ARCH(riscv)
ENTRY(_start)
MEMORY { ROM (rx) : ORIGIN = 0, LENGTH = 8K }
SECTIONS {
 .text : { *(.text*) *(.rodata*) } > ROM
 /DISCARD/ : { *(.riscv.attributes) *(.comment) }
 ASSERT(SIZEOF(.text) <= 8192, "Programa excede Program ROM de 8 KiB")
}
