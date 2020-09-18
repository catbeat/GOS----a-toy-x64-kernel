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

