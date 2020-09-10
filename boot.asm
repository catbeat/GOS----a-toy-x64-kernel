    org 0x7c00

TopStack    equ 0x7c00

start:  mov ax, cs
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, TopStack

        ; clear screen

        mov ax, 0600H
        mov bx, 0700H
        mov cx, 0000H       ; window left top at (0,0)
        mov dx, 0184fH

        int 10H     

        ; set focus

        mov ax, 0200H
        mov bx, 0000H
        mov dx, 0000H

        int 10H         

        ; show "start booting"

        mov ax, 1301H
        mov bx, 000FH
        mov dx, 0000H
        mov cx, 13

        mov bp, StartBootingMsg

        int 10H

        ; reset floppy

        xor ah, ah
        xor dl, dl
        int 13H

        jmp $

StartBootingMsg:    db "start booting"

        times (510-($-$$)) db 0
        dw 0xaa55

