.section .data

;==== GDT

.global GDT_table

GDT_table:

    .quad           dq 0x0000000000000000   ; null descriptor
    .quad           dq 0x0020980000000000   ; kernel code desc
    .quad           dq 0x0000920000000000   ; kernel data desc
    .quad           dq 0x0020F80000000000   ; user code desc
    .quad           dq 0x0000F20000000000   ; user data desc
    .quad           dq 0x00cf9a000000ffff   ; kernel code 32bitmode desc
    .quad           dq 0x00cf92000000ffff   ; kernel data 32bitmode desc
    .fill 10, 8, 0                          ; TSS long mode 128 bit
GDT_end:

GDT_ptr:
GDT_limit:  .word GDT_end - GDT_table - 1
GDT_base:   .quad GDT_table

;==== IDT

.global IDT_table

IDT_table:
    .fill 512, 8, 0
IDT_end:

IDT_ptr:
IDT_limit:  .word IDT_end - IDT_table - 1
IDT_base:   .quad IDT_table

;==== TSS

.global TSS64_Table

TSS64_Table:
    .fill 13, 8, 0
TSS64_end:

TSS_ptr:
TSS_limit:  .word TSS64_end - TSS64_Table - 1
TSS_base:   .quad TSS64_Table

;==== page init

.align 8
.org 1000H

PML4:
    .quad 0x102007
    .fill 255, 8, 0
    .quad 0x102007
    .fill 255, 8, 0

.org 2000H
PDPT:
    .quad 0x103007
    .fill 511, 8, 0

.org 3000H
PDT:
    .quad 0x000087
    .quad 0x200087
    .quad 0x400087
    .quad 0x600087
    .quad 0x800087
    .quad 0xe0000087
    .quad 0xe0200087
    .quad 0xe0400087
    .quad 0xe0600087
    .quad 0xe0800087
    .quad 0xe0a00087
    .quad 0xe0c00087
    .quad 0xe0e00087
    .fill 499, 8, 0

    



