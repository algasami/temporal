; directives (are not translated)
org 0x7c00
bits 16 ; backwards compatibility

%define ENDL 0x0D, 0x0A

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
ebr_volume_label_str:       db "TEMPORAL OS"
ebr_system_id_str:          db "FAT12   "

; bootcode goes here (down there!)

start:
    ; set up segment
    ; real location = segment * 16 + offset
    ; how to index = segment: [base + index * scale + displacement]
    mov ax, 0x00
    mov ds, ax ; data segment (zero)
    mov es, ax ; extra segment (zero)

    mov ss, ax ; stack segment (zero)
    mov sp, 0x7c00 ; set stack pointer to our start (grows **downwards**)

    ; some BIOS might do 0x7c00:0x0000 instead of 0x0000:0x7c00 (weird bugs)
    push es ; CS segment to 0
    push word .after ; IP to .after
    retf ; retf (far return) pops caller address and sets CS to the second pop (trick!)
.after:
    ; e.g. stack with 4 elements
    ; |3---|2---|1---|0---|bot-|
    ; |7BFC|7BFD|7BFE|7BFF|7C00|
    ; |----|----|----|----|----|
    ;  ^stack top(sp)      ^ stack bottom
    mov [ebr_drive_number], dl ; set drive num

    mov si, msg_init 
    call puts
    ; bios put drive number in dl
; 	AH = 08
;	DL = drive number (0=A:, 1=2nd floppy, 80h=drive 0, 81h=drive 1)
;	on return:
;	AH = status  (see INT 13,STATUS)
;	BL = CMOS drive type
;	     01 - 5¬  360K	     03 - 3«  720K
;	     02 - 5¬  1.2Mb	     04 - 3« 1.44Mb
;	CH = cylinders (0-1023 dec. see below)
;	CL = sectors per track	(see below)
;	DH = number of sides (0 based)
;	DL = number of drives attached
;	ES:DI = pointer to 11 byte Disk Base Table (DBT)
;	CF = 0 if successful
;	   = 1 if error
    push es
    mov ah, 0x08
    int 0x13
    jc floppy_error ; jump if cf
    pop es

    and cl, 0x3F                        ; remove top 2 bits
    xor ch, ch
    mov [bdb_sectors_per_track], cx     ; sector count

    inc dh
    mov [bdb_head_count], dh                 ; head count

    ; find root dir's lba
    ; lba = reserved + sectors_per_fat * fats
    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_table_count]
    xor bh, bh
    mul bx ; mul r/m16 : multiplicand = ax, product = DX:AX
    add ax, [bdb_reserved_sector_count]
    push ax ; preserve

    ; find root dir's size (sector)
    ; size = (32bytes * dir_entry_count / bytes_per_sector) ceil
    mov ax, [bdb_dir_entry_count]
    shl ax, 5
    xor dx, dx
    div word [bdb_bytes_per_sector]
    ; div r/m16: dx:ax / r/m16 = ax ... dx
    test dx, dx ; zf = dx
    jz .root_dir_after
    inc ax

.root_dir_after:

; read from disk
; Param:
;   - ax: LBA address
;   - cl: number of sectors to read (to 128)
;   - dl: driver num
;   - es:bx : memory address to store read data
    mov cl, al ; cl = sectors of root dir
    pop bx ; bx = lba of root_dir
    add ax, bx
    mov [root_dir_end], ax
    mov ax, bx
    mov dl, [ebr_drive_number]
    mov bx, read_buffer ; es:bx is now pointing at read_buffer
    call disk_read


    ; find file in read_buffer (root directories)
    xor bx, bx ; bx as counter
    mov di, read_buffer ; file_name first
.find_file_loop:
    mov si, target_file_name
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je .found_file_entry

    add di, 32
    inc bx
    cmp bx, [bdb_dir_entry_count]
    jl .find_file_loop

    jmp find_stage2_error

.found_file_entry:
    ; di is now at file dir
    mov ax, [di + 26] ; ax is at cluster low
    mov [file_cluster], ax

    mov ax, [bdb_reserved_sector_count]
    mov bx, read_buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    mov bx, KERNEL_SEGMENT
    mov es, bx
    mov bx, KERNEL_OFFSET


.read_file_loop:
    mov ax, [file_cluster]
    sub ax, 2
    xor ah, ah
    mul byte [bdb_sectors_per_cluster]
    add ax, word [root_dir_end]
    mov cl, [bdb_sectors_per_cluster]
    mov dl, [ebr_drive_number]
    call disk_read
    mov ax, [bdb_sectors_per_cluster]
    mul word [bdb_bytes_per_sector] ; don't care about DX
    add bx, ax

    ; computer location of the next cluster
    mov ax, [file_cluster]
    xor dx, dx
    mov cx, 3
    mul cx
    mov cx, 2
    div cx ; ax = result, dx = remainder

    mov si, read_buffer
    add si, ax
    mov ax, [ds:si]
    
    or dx, dx
    jz .cluster_even
    
.cluster_odd:
    shr ax, 4
    jmp .read_file_after

.cluster_even:
    and ax, 0x0FFF

.read_file_after:
    cmp ax, 0xFF8
    jae .read_finish

    mov [file_cluster], ax
    jmp .read_file_loop

.read_finish:
    ; prepare for kernel far jump (switching segments)
    mov dl, [ebr_drive_number]

    mov ax, KERNEL_SEGMENT ; setup segment
    mov ds, ax
    mov es, ax

    jmp KERNEL_SEGMENT:KERNEL_OFFSET

    jmp wait_for_reboot

    cli ; disable interrupts, no way to get out of halt!
    hlt


puts:
    push si ; source index register (working with string)
    push ax ; general purpose
    push bx

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
    pop bx
    pop ax ; pop top to ax (to make sure ax gets reset to before puts get called)
    pop si ; pop top to si (the same)
    ret ; pop the top (address of the caller from call mnemonic) to our current location


floppy_error:
    ; mov si, msg_floppy_failed
    ; call puts
    jmp wait_for_reboot

find_stage2_error:
    ; mov si, msg_dir_error
    ; call puts
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

msg_init:               db "SYS_BOOT", ENDL, 0x00
msg_floppy_failed:      db "D_ERR", ENDL, 0x00
msg_dir_error:          db "S_ERR", ENDL, 0x00
target_file_name:       db "STAGE2  BIN"
file_cluster:           dw 0
root_dir_end:           dw 0
KERNEL_SEGMENT     equ 0x2000
KERNEL_OFFSET      equ 0
times 510-($-$$) db 0x00
dw 0xaa55
read_buffer: