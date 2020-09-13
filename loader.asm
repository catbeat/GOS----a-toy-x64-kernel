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

BaseOfkernel        equ 0x00
offsetOfKernel      equ 0x100000

BaseTmpOfKernel     equ 0x00
offsetTmpOfKernel   equ 0x7E00

MemStructBuffer     equ 0x7E00

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

    ; reset floppy 
    xor ah, ah
    xor dl, dl
    int 13H

    ;==== now let's do some actual work

    ;==== search for kernel bin
    mov word [SectorNo], RootStartSecNum

SearchForKernelInSectors:
    cmp word [LeftSecToSearchRoot], 0
    jz NoKernel

    ; we use 0000:8000 as the buffer for readin root content
    xor ax, ax
    mov es, ax
    mov bx, 8000H

    mov ax, word [SectorNo]
    mov cl, 1
    call ReadSectors

    mov si, KernelFileName
    mov di, 8000H

    mov cx, 10H
    cld

    SearchForKernel:
        cmp cx, 0
        jz SearchNextSector

        push cx

        ; the name only has 11 bytes
        mov cx, 11

        CompareKernelName:
            cmp cx, 0
            jz KernelFound

            lodsb

            ; if not the same, then we can skip to next entry
            cmp al, [es:di]
            jnz FileDifferent

            inc di
            dec cx

            jmp CompareKernelName

    FileDifferent:
        pop cx

        dec cx

        and di, 0ffe0H
        add di, 20H

        mov si, KernelFileName

        jmp SearchForKernel

SearchNextSector:
    dec word [LeftSecToSearchRoot]
    inc word [SectorNo]
    
    jmp SearchForKernelInSectors

KernelFound:
    mov ax, RootOccupySecNum
    and dx, 0ffe0H
    add dx, 01AH

    mov cx, word [es:di]
    push cx

    add cx, ax
    add cx, SectorBalance

    ; we temporarily loaded it into 0x7e00 and then transport to 1MB

    mov eax, BaseTmpOfKernel
    mov es, eax
    mov bx, offsetTmpOfKernel
    mov ax, cx

    LoadingKernelInTmp:
        mov cl, 1
        call ReadSectors
        
        pop ax

        ; ==== transport the current readin Sector to 1MB
        push cx
        push eax
        push edi
        push fs
        push bx

        mov eax, BaseOfkernel
        mov fs, eax
        mov cx, 200H            ; loop for 512 bytes
        mov edi, [OffsetForToloadKernel]

        ; transport the sector one by one byte
        TransportSector:
            mov al, byte [es:bx]
            mov byte [fs:edi], al

            inc edi
            inc bx

            loop TransportSector

        mov dword [OffsetForToloadKernel], edi          ; the offset for the next to-load sector of kernel

        pop bx
        pop fs
        pop edi
        pop eax
        pop cx

        call getFATEntryNextClus

        cmp ax, 0FFFH
        jz KernelIsLoaded

        push ax
        add ax, RootOccupySecNum
        add ax, SectorBalance
        jmp LoadingKernelInTmp

KernelIsLoaded:
    ; show a 'G' to separate the loading of kernel
    mov ax, 0b800H
    mov gs, ax
    mov ah, 0FH             ; white word and black background
    mov al, 'G'
    mov [gs:((80*0+39)*2)], ax

    ; as we already finished the loading, floppy drive can be shut down
    KillMotor:
        push dx
        mov dx, 03F2H
        mov al, 0
        out dx, al
        pop dx

    ; ==== get memory inf
    ; since the temporary space for kernel is no longer needed, I' ll use it to store memory inf

    ; firstly, show a msg
    mov ax, 1301H
    mov bx, 000FH
    mov dx, 0400H
    mov cx, 24

    push ax
    mov ax, ds
    mov es, ax
    pop ax

    mov bp, StartGetMemStructMsg
    int 10H

    mov ebx, 0              ; since this is the first call for int15H, continuation ebx must contain zero

MemStructGetting:
    mov ax, 0
    mov es, ax
    mov edi, MemStructBuffer

    mov eax, 0E820H
    mov ecx, 20             ; just use the least bytes
    mov edx, 0x534D4150     ; 'SMAP'

    int 15H
    jc MemStructGetFail

    add edi, 20

    cmp ebx, 0
    jne MemStructGetting    ; use the new ebx since first call has some accidents
    jmp MemStructGetDone

MemStructGetFail:
    mov ax, 1301H
    mov bx, 008CH
    mov dx, 0500H
    mov cx, 26

    push ax
    mov ax, ds
    mov es, ax
    pop ax

    mov bp, MemStructGetFailMsg
    int 10H

MemStructGetDone:
    mov ax, 1301H
    mov bx, 000FH
    mov dx, 0600H
    mov cx, 24

    push ax
    mov ax, ds
    mov es, ax
    pop ax
    
    mov bp, MemStructGetDoneMsg
    int 10H

;==== Get SVGA info
GetSVGAInfo:

    mov ax, 1301H
    mov bx, 000FH
    mov dx, 0800H
    mov cx, 23

    push ax
    mov ax, ds
    mov es, ax
    pop ax

    mov bp, StartGetSVGAVBEInfoMsg
    int 10H

    mov ax, 0
    mov es, ax

    mov di, 8000H
    mov ax, 4F00H

    int 10H

    cmp ax, 004FH       ; ret: ah = 00 means successful and al = 4F means svga is supported, es:di will get the inf
    jz .KO

    ; ==== FAIL
    mov ax, 1301H
    mov bx, 008CH
    mov dx, 0900H
    mov cx, 26

    push ax
    mov ax, ds
    mov es, ax
    pop ax

    mov bp, GetSVGAVBEInfoFailMsg

    int 10H

.KO:
    mov ax, 1301H
    mov bx, 000FH
    mov dx, 0A00H
    mov cx, 18

    push ax
    mov ax, ds
    mov es, ax
    pop ax

    mov bp, GetSVGAVBEInfoOKMsg

    int 10H

;==== get SVGA mode info

    ; firstly show a msg
    mov ax, 1301H
    mov bx, 000FH
    mov dx, 0C00H
    mov cx, 24

    push ax
    mov ax, ds
    mov es, ax
    pop ax

    mov bp, StartGetSVGAModeInfoMsg

    int 10H

    mov ax, 0
    mov es, ax
    mov si, 0x800e              ; it's the pfawModes info, an address actually

    mov esi, dword [es:si]
    mov edi, 0x8200

GetSVGAModeInfo:

    mov cx, word [es:esi]

    ; display the SVGA mode info
    push ax

    mov ax, 00H
    mov al, ch
    call DisplayALinHex

    mov ax, 00H
    mov al, cl
    call DisplayALinHex

    pop ax

    cmp cx, 0FFFFH
    jz GetSVGAModeInfoFinish

    ;query mode info
    mov ax, 4F01H               ; cx just contain the mode number
    int 10H

    cmp ax, 004FH
    jnz GetSVGAModeInfoFail

    add esi, 2
    add edi, 100H

    jmp GetSVGAModeInfo

GetSVGAModeInfoFail:
    mov ax, 1301H
    mov bx, 008CH
    mov dx, 0D00H
    mov cx, 27

    push ax
    mov ax, ds
    mov es, ax
    pop ax

    mov bp, GetSVGAModeInfoFailMsg

    int 10H

SetSVGAModeFail:
    jmp $

GetSVGAModeInfoFinish:
    mov ax, 1301H
    mov bx, 000FH
    mov dx, 0D00H
    mov cx, 19

    push ax
    mov ax, ds
    mov es, ax
    pop ax

    mov bp, GetSVGAModeInfoOKMsg

    int 10H

; set SVGA mode

    mov ax, 4F02H
    mov bx, 4180H
    int 10H

    cmp ax, 004FH
    jnz SetSVGAModeFail


; no kernel found, error!
NoKernel:
    mov ax, 1301H
    mov bx, 008CH
    mov dx, 0300H

    mov cx, 16

    push ax
    mov ax, ds
    mov es, ax
    pop ax

    mov bp, NoKernelMsg

    int 10H
    jmp $

;=============================================================

[SECTION .s16lib]

[BITS 16]
    
; ===== read sectors
; input: ax = start sec num
;        cl = num of sectors to read
;        es:bx = the address for destination buffer
; ps: here the file system is built on floppy

ReadSectors:

        push ax
        push bp
        push bx
        push dx

        mov bp, sp
        sub esp, 2
        mov byte [bp-2], cl

        push bx

        ; just divide the num of sectors on a road
        mov bl, [BPB_SecPerTrk]
        div bl

        pop bx

        inc ah          ; we get the start sector num at ah

        mov cl, ah

        ; get the magnetic head num
        mov dh, al
        and dh, 1

        ; get the magnetic road num
        shr al, 1
        mov ch, al

        ; give the drive num
        mov dl, [BS_DrvNum]
    
    reading:
        mov ah, 2
        mov al, byte [bp-2]
        int 13H
        jc reading

        add esp, 2

        pop dx
        pop bx
        pop bp
        pop ax

        ret

; ==== get the FAT entry for next cluster
; input:    ax = DIR_FstClus
; output:   ax = next cluster

getFATEntryNextClus:
        push es
        push bx
        push cx

        push ax

        mov ax, 0
        mov es, ax

        mov byte [OddOrEven], 0

        pop ax

        mov bx, 3
        mul bx
        mov bx, 2
        div bx

        cmp dx, 0
        jz EvenEntry
        mov byte [OddOrEven], 1

    ; now ax is the byte offset for the whole FAT
    EvenEntry:
        xor dx, dx
        mov bx, [BPB_BytesPerSec]
        div bx

        ; now ax is the sector num and the remainder is the offset

        mov bx, 8000H
        add ax, FAT1StartSecNum

        mov cl, 2
        call ReadSectors

        add bx, dx
        mov ax, [es:bx]

        cmp byte [OddOrEven], 0
        jz EvenEntryGoOn
        shr ax, 4

    EvenEntryGoOn:
        and ax, 0FFFH

        pop cx
        pop bx
        pop es

        ret   

; ==== display the num in al in hex mode
; mainly used by SVGA
; input: al

DisplayALinHex:

    push	ecx
	push	edx
	push	edi
	
	mov	edi,	[DisplayPosition]
	mov	ah,	0Fh
	mov	dl,	al
	shr	al,	4
	mov	ecx,	2
.begin:

	and	al,	0Fh
	cmp	al,	9
	ja	.1
	add	al,	'0'
	jmp	.2
.1:

	sub	al,	0Ah
	add	al,	'A'
.2:

	mov	[gs:edi],	ax
	add	edi,	2
	
	mov	al,	dl
	loop	.begin

	mov	[DisplayPosition],	edi

	pop	edi
	pop	edx
	pop	ecx
	
	ret


;=============================================================
StartLoaderMsg:         db "Start Loader"
KernelFileName:         db "KERNEL  BIN"
NoKernelMsg:            db "No Kernel Found!"

SectorNo:               dw 0
LeftSecToSearchRoot:    dw RootOccupySecNum
OddOrEven:              db 0

DisplayPosition         dd 0

OffsetForToloadKernel   dd offsetOfKernel

StartGetMemStructMsg    db "Start get memory struct."
MemStructGetFailMsg     db "Fail to get memory struct!"
MemStructGetDoneMsg     db "Memory Struct is loaded."

StartGetSVGAVBEInfoMsg  db "Start get SVGA VBE info"
GetSVGAVBEInfoFailMsg   db "Fail to get SVGA VBE Info!"
GetSVGAVBEInfoOKMsg     db "Get SVGA VBE Info."
StartGetSVGAModeInfoMsg db "Start get SVGA mode info"
GetSVGAModeInfoFailMsg  db "Fail to get SVGA mode info!"
GetSVGAModeInfoOKMsg    db "Get SVGA mode info."