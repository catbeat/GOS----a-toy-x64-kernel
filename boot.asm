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
        cmp word [LeftSecToSearchRoot], 0
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

            lodsb
            cmp al, byte [di]

            jnz EntryDifferent
            inc di
            dec cx
            jmp compareEntry

        EntryDifferent:
            pop cx
            dec cx

            and di, 0ffe0H
            add di, 20H
            mov si, LoadFileName
            jmp compareEntries

    nextSector:

        inc word [SectorNo]
        dec word [LeftSecToSearchRoot]
        jmp SearchLoaderInSector         

LoaderFound:

        ; basically find the start sector num for loader
        and di, 0ffe0H
        add di, 001AH

        mov ax, word [es:di]
        mov cx, RootOccupySecNum
        push ax
        add ax, cx
        add ax, SectorBalance

        ; let es:bx to 0x10000
        mov cx, ax
        mov ax, BaseSegOfLoader
        mov es, ax
        mov bx, OffsetOfLoader
        mov ax, cx              ; ax is the sector of loader to read

    LoadingLoaderSectors:
        mov cl, 1

        call ReadSectors
        add bx, 512

        pop ax
        call getFATEntryNextClus

        cmp ax, 0FFFH
        jz LoaderIsLoaded

        push ax
        add ax, SectorBalance
        add ax, RootOccupySecNum

        jmp LoadingLoaderSectors

LoaderIsLoaded:
        
        jmp BaseSegOfLoader:OffsetOfLoader

NoLoader:
        mov ax, 1301H
        mov bx, 000FH
        mov dx, 0100H

        mov cx, 15
        mov bp, LoaderErrorMsg

        int 10H
        jmp $
        
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


StartBootingMsg:    db "start booting"
LoadFileName:       db "LOADER  BIN", 0
LoaderErrorMsg:     db "No Loader Found"

SectorNo:               dw 0
LeftSecToSearchRoot:    dw RootOccupySecNum
OddOrEven:              db 0


        times (510-($-$$)) db 0
        dw 0xaa55

