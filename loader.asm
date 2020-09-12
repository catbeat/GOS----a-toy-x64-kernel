    org 10000H

Loader:
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

    jmp $
    
StartLoaderMsg:     db "Start Loader"