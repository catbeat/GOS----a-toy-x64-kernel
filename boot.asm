    org 0x7c00

TopStack        equ 0x7c00
BaseSegOfLoader equ 0x1000
OffsetOfLoader  equ 0x0000

RootOccupySecNum    equ 14
RootStartSecNum     equ 19
FAT1StartSecNum     equ 1
SectorBalance       equ 17 

fatInf: 
        jmp short start
        nop

    BS_OEMName:     	db	'GosBoot '          ; name of OS
	BPB_BytesPerSec:	dw	512                 ; bytes of one sector
	BPB_SecPerClus: 	db	1                   ; num of sectors of a cluster
	BPB_RsvdSecCnt: 	dw	1                   ; num of reserved sector
	BPB_NumFATs:    	db 	2                   ; num of FAT tables
	BPB_RootEntCnt: 	dw	224                 ; num of directory entry that root can hold
	BPB_TotSec16:   	dw	2880                ; total num of sectors
	BPB_Media:      	db	0xf0                ; mobile storage media
	BPB_FATSz16:    	dw	9                   ; how many sectors a FAT will use
	BPB_SecPerTrk:  	dw	18                  ; how many sectors of one magenatic road
	BPB_NumHeads:   	dw	2                   ; num of magenatic head
	BPB_HiddSec:    	dd	0                   ; num of hidder sector
	BPB_TotSec32:   	dd	0                   ; if TotSec16 is 0, then use this to store total num of sectors
	BS_DrvNum:      	db	0                   ; the drive number of int 13H
	BS_Reserved1:      	db	0                   ; no use
	BS_BootSig:     	db	0x29                ; extension boot sig
	BS_VolID:       	dd	0                   ; volumne id
	BS_VolLab:      	db	'boot loader'       ; volumne lab
	BS_FileSysType:    	db	'FAT12   '          ; file system type

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

; ==== search loader
        mov word [SectorNo], RootStartSecNum

SearchLoaderInSector:

        ; if we already look through all sectors then there is no loader in root dir
        cmp [LeftSecToSearchRoot], 0
        jz NoLoader

        ; put the readin sector to 08000
        mov ax, 0
        mov es, ax
        mov bx, 8000H
        mov ax, word [SectorNo]
        mov cl, 1
        call ReadSectors

        mov si, LoadFileName
        mov di, 8000H

        mov cx, 10H             ; since a sector has 16 dir entry to compare

        cld
    compareEntries:

        cmp cx, 0
        jz nextSector

        push cx
        mov cx, 11

        compareEntry:

            cmp cx, 0
            jz LoaderFound

            lobsb
            cmp al, byte [di]

            jnz EntryDifferent
            inc di
            jmp compareEntry

        EntryDifferent:
            pop cx
            dec cx

            and di 0ffe0H
            add di, 20H
            mov si, LoadFileName
            jmp compareEntries

    nextSector:

        inc word [SectorNo]
        dec word [LeftSecToSearchRoot]
        jmp SearchLoaderInSector         

    LoaderFound:


NoLoader:
        mov ax, 1301H
        mov bx, 000FH
        mov dx, 0100H

        mov cx, 21
        mov bp, LoaderErrorMsg

        int 10H
        jmp $
        
; ===== read sectors
; input: ax = start sec num
;        cl = num of sectors to read
;        es:bx = the address for destination buffer
; ps: here the file system is built on floppy

ReadSectors:


        push bp
        push bx

        mov bp, sp
        mov byte [bp-2], cl

        ; just divide the num of sectors on a road
        mov bl, [BPB_SecPerTrk]
        div bl

        inc ah          ; we get the start sector num at ah

        mov cl, ah

        ; get the magnetic head num
        mov dh, al
        and dh, 1

        ; get the magnetic road num
        shr al, 2
        mov ch, al

        ; give the drive num
        mov dl, [BS_DrvNum]
    
    reading:
        mov ah, 2
        mov al, byte [bp-2]
        int 13H
        jc reading

        pop bx
        pop bp

        ret



StartBootingMsg:    db "start booting"
LoadFileName:       db "LOADER_BIN", 0
LoaderErrorMsg:     db "No Loader Found"

SectorNo:               dw 0
LeftSecToSearchRoot:    dw RootOccupySecNum


        times (510-($-$$)) db 0
        dw 0xaa55

