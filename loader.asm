; this program aims to load the file of kernel

    org 10000H

    jmp Loader

%include "fat12.inc"

[SECTION gdt]

DESC_NULL:      dd 0, 0
DESC_CODE:      dd 0x0000FFFF, 0x00CF9A00
DESC_DATA:      dd 0x0000FFFF, 0x00CF9200

GDT_len         equ ($-DESC_NULL)
GDT_Ptr:        dw GDT_len-1
                dd DESC_NULL

SELEC_CODE:     equ DESC_CODE-DESC_NULL
SELEC_DATA:     equ DESC_DATA-DESC_NULL

[SECTION .s16]
[BITS 16]

Loader:

    ; ==== initialization
    ; well, here I just simply show a message and do some initial work for sp, ds, es
    mov ax, cs
    mov ds, ax
    mov es, ax

    xor ax, ax
    mov ss, ax
    mov sp, 7c00H

    mov ax, 1301H
    mov bx, 000FH
    mov dx, 0200H
    mov cx, 12

    mov bp, StartLoaderMsg
    int 10H

    ;==== open A20
    push cx
    in al, 92H
    or al, 00000010B
    out 92H, al
    pop ax

    ;==== some tricky things here
    cli 

    ; set gdt
    db 0x66
    lgdt [GDT_Ptr]

    mov	eax,	cr0
	or	eax,	1
	mov	cr0,	eax

    ; give fs the ability to for addressing above 1000000( only available in bochs)
	mov	ax,	SELEC_DATA
	mov	fs,	ax

    ; close protection mode
	mov	eax,	cr0
	and	al,	11111110b
	mov	cr0,	eax

	sti

    jmp $
    
StartLoaderMsg:     db "Start Loader"