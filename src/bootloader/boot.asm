; directives (are not translated)
org 0x7c00
bits 16 ; backwards compatibility

%define ENDL 0x0D, 0x0A ; carriage return line feed (crlf)


; fat12 header record osdev wiki fat
jmp short start ; jmp short is just 0xEB, start is 0x3C, nop is 0x90
nop ; 0x90
bdb_oem:                    db "MSWIN4.1"
bdb_bytes_per_sector:       dw 0x0200
bdb_sectors_per_cluster:    db 0x01
bdb_reserved_sector_count:  dw 0x0001
bdb_fat_table_count:        db 0x02
bdb_dir_entry_count:        dw 0x00e0
bdb_total_sector_count:     dw 0x0b40 ; 2880 * 512 byte = 1.44MB
bdb_media_descriptor_type:  db 0xf0 ; 0xf0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 0x0009
bdb_sectors_per_track:      dw 0x0012
bdb_head_count:             dw 0x0002
bdb_hidden_sector_count:    dd 0x00000000
bdb_large_sector_count:     dd 0x00000000

; extended fat12 boot record
ebr_drive_number:           db 0x00 ; floppy disk
                            db 0x00 ; reserved
ebr_signature:              db 0x29
ebr_volume_id:              db 0x26, 0x5c, 0x48, 0x2a
ebr_volume_label_str:       db "NBOS       "
ebr_system_id_str:          db "FAT12   "

; bootcode goes here (down there!)

start:
    jmp main


puts:
    push si ; source index register (working with string)
    push ax ; general purpose

    .loop:
        lodsb ; load letters from ds:si to al (0 to 7 bit) and si+=0x01
        ; ^ please refer to felix cloutier
        or al, al ; check if it's terminator (null)
        jz .done ; jump if the recent cmp result (in this case jz) is zero

        mov ah, 0x0e ; ah = 0x0e and call INT 0x10 for teletype
        ; al has already been loaded above
        mov bh, 0x00 ; set bh = pagenumber, bl = color

        int 0x10
        
        jmp .loop ; loop

    .done:
        pop ax ; pop top to ax (to make sure ax gets reset to before puts get called)
        pop si ; pop top to si (the same)
        ret ; pop the top (address of the caller from call mnemonic) to our current location


main:
    ; set up segment
    ; real location = segment * 16 + offset
    ; how to index = segment: [base + index * scale + displacement]
    mov ax, 0x00
    mov ds, ax ; data segment (zero)
    mov es, ax ; extra segment (zero)

    mov ss, ax ; stack segment (zero)
    mov sp, 0x7c00 ; set stack pointer to our start (grows **downwards**)
    ; e.g. stack with 4 elements
    ; |3---|2---|1---|0---|bot-|
    ; |7BFC|7BFD|7BFE|7BFF|7C00|
    ; |----|----|----|----|----|
    ;  ^stack top(sp)      ^ stack bottom

    mov si, msg_init ; set source index to msg_init array
    call puts
    ; test floppy disk
    ; bios put drive number in dl
    mov [ebr_drive_number], dl ; set drive num
    mov ax, 0x01 ; set lba address
    mov cl, 1 ; read one sector
    mov bx, 0x7e00 ; after the bootloadera ( +512)
    jmp .halt
    .halt:
        cli ; disable interrupts, no way to get out of halt!
        hlt
        jmp .halt

floppy_error:
    mov si, msg_floppy_failed
    call puts
    jmp wait_for_reboot


wait_for_reboot:
    mov ah, 0x00
    int 0x16
    ; word:word = dword
    jmp 0xFFFF:0x0000 ; bios location
; disk system (lba to chs)
; Param:
;   - ax : lba address
; Ret:
;   - cx [0-5b] : sector number
;   - cx [6-15b]: cylinder
;   - dh: head
lba_to_chs:
    push ax
    push dx
    xor dx, dx ; dx reset to 0, because when divided by a WORD, DX:AX becomes the dividend (we don't need DX right now)
    div word [bdb_sectors_per_track] ; ax = lba / bdb_sectors_per_track, dx = remainder
    inc dx ; dx = (lba % bdb_sectors_per_track) + 1 = sector
    mov cx, dx ; cx [0-5b] = sector

    xor dx, dx ; dx reset to 0
    div word [bdb_head_count] ; ax = lba / bdb_sectors_per_track / head = cylinder
                              ; dx = lba / bdb_sectors_per_track % head = head
    mov dh, dl ; dh = head
    mov ch, al ; ch 8-15b is cylinder
    shl ah, 6 ; left with 2 bytes and all 0 on the right (like 11000000)
    or cl, ah

    ;
    ; CX:       -------- --------
    ; cylinder: 76543210 98
    ; sector:              543210
    ;

    mov al, dh ; tmp al = dh
    pop dx ; restore dx ( we still need dh!!!)
    mov dh, al ; dh = tmp
    pop ax ; restore ax
    ret

; read from disk
; Param:
;   - ax: LBA address
;   - cl: number of sectors to read (to 128)
;   - dl: driver num
;   - es:bx : memory address to store read data
;
disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx ; save it
    call lba_to_chs ; compute chs
    pop ax ; al = number of sectors to read now

    ; https://www.stanislavs.org/helppc/int_13-2.html
    mov ah, 0x02 ; read disk mode!
    mov dl, 0x00 ; set disk to A:/

    mov di, 0x03 ; retry times

    .retry:
        pusha ; push all regs onto stack
        stc ; set carry flag
        int 0x13 ; call INT 0x13 for disk reading
        jnc .done ; jump not carry flag

        popa
        call disk_reset

        dec di ; decrease di by one
        test di, di ; check if di is 0
        jnz .retry ; jump not zero

    .fail:
        jmp floppy_error
    
    .done:
        popa
        pop di
        pop dx
        pop cx
        pop bx
        pop ax
        ret

; disk reset https://www.stanislavs.org/helppc/int_13-0.html
; param:
;   - dl: driver number
; ret:
;   - cf: 0 = success
disk_reset:
    pusha
    stc ; set carry
    mov ah, 0x00
    int 0x13
    jc floppy_error ; jump if carry flag
    popa
    ret

msg_init:               dw "[Success] Initialized Temporal Bootloader", ENDL, 0x00
msg_floppy_failed:      dw "[Failure] Floppy Disk Read Error", ENDL, 0x00

times 510-($-$$) db 0x00
dw 0xaa55
