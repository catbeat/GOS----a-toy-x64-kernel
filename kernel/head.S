.section .text

.globl _start

_start:

    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %ss

    mov $0x7E00, %esp

    lgdt GDT_ptr(%rip)

    lidt IDT_ptr(%rip)

    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %gs
    mov %ax, %fs
    mov %ax, %ss

    movq $0x7E00, %rsp

    movq $0x101000, %rax
    movq %rax, %cr3
    movq switch_seg(%rip), %rax
    pushq $0x08
    pushq %rax
    lretq

switch_seg:
    .quad entry_for_64

entry_for_64:
    movq $0x10, %rax
    movq %rax, %ds
    movq %rax, %es
    movq %rax, %gs
    movq %rax, %ss

    movq $0xffff800000007E00, %rsp
    movq go_to_kernel(%rip), %rax
    pushq $0x08
    pushq %rax
    lretq

go_to_kernel:
    .quad Start_kernel


/* ==== page init */

.align 8
.org 0x1000

PML4:
    .quad 0x102007
    .fill 255, 8, 0
    .quad 0x102007
    .fill 255, 8, 0

.org 0x2000
PDPT:
    .quad 0x103003
    .fill 511, 8, 0

.org 0x3000
PDT:
    .quad 0x000083
    .quad 0x200083
    .quad 0x400083
    .quad 0x600083
    .quad 0x800083
    .quad 0xe0000083
    .quad 0xe0200083
    .quad 0xe0400083
    .quad 0xe0600083
    .quad 0xe0800083
    .quad 0xe0a00083
    .quad 0xe0c00083
    .quad 0xe0e00083
    .fill 499, 8, 0

.section .data

/* ==== GDT */

.globl GDT_table

GDT_table:

    .quad            0x0000000000000000   /* null descriptor */
    .quad            0x0020980000000000   /* kernel code desc */
    .quad            0x0000920000000000   /* kernel data desc */
    .quad            0x0020F80000000000   /* user code desc */
    .quad            0x0000F20000000000   /* user data desc */
    .quad            0x00cf9a000000ffff   /* kernel code 32bitmode desc */
    .quad            0x00cf92000000ffff   /* kernel data 32bitmode desc */
    .fill 10, 8, 0                          /* TSS long mode 128 bit */
GDT_end:

GDT_ptr:
GDT_limit:  .word GDT_end - GDT_table - 1
GDT_base:   .quad GDT_table

/* ==== IDT */

.globl IDT_table

IDT_table:
    .fill 512, 8, 0
IDT_end:

IDT_ptr:
IDT_limit:  .word IDT_end - IDT_table - 1
IDT_base:   .quad IDT_table

/* ==== TSS */

.globl TSS64_Table

TSS64_Table:
    .fill 13, 8, 0
TSS64_end:

TSS_ptr:
TSS_limit:  .word TSS64_end - TSS64_Table - 1
TSS_base:   .quad TSS64_Table



