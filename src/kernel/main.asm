org 0x0
bits 16


%define ENDL 0x0D, 0x0A
%define ENTER_CODE 0x1C0D


start:
    ; everything has been initialized
    ; no need to take care of segments and offsets
    mov si, msg_kernel
    call puts

.read_loop:
    call readline
    mov si, ibuff
    call puts
    call flush
    jmp .read_loop

.halt:
    cli
    hlt

readline:
    call readc
    cmp ax, ENTER_CODE
    jne readline
    call putcrlf
    ret

; readc with life teletype
; Params:
; null
; Returns:
;   - ah is scancode
;   - al is char(byte) (0x00 if it's special)
readc:
    push bx
    mov ah, 0x00
    int 0x16 ; see stanis slav

    cmp ax, ENTER_CODE
    jne .is_not_enter

    mov bx, [ibuff_pointer]
    ; * we need to use intermediate bx to index memory!
    ; speaking of implementation, it's also logical to not
    ; allow index to be indexed by memory's value!
    ; (index memory and then index memory with the former's value in ONE instruction? not possible!)
    mov [bx], byte 0x0D
    inc word bx
    mov [bx], byte 0x0A
    inc word bx
    mov [bx], byte 0x00
    mov [ibuff_pointer], word bx

    pop bx

    mov si, ibuff
    ret

.is_not_enter:
    mov bx, [ibuff_pointer]
    mov [bx], byte al
    inc word bx
    mov [bx], byte 0x00
    mov [ibuff_pointer], word bx

    pop bx

    call putc
    ret


; helper
putcrlf:
    push ax
    mov al, 0x0D
    call putc
    mov al, 0x0A
    call putc
    pop ax
    ret
putc:
    push ax
    push bx
    mov ah, 0x0E
    mov bh, 0x00
    ; bl is foreground
    int 0x10
    pop bx
    pop ax
    ret

;
; Prints a string to the screen
; Params:
;   - ds:si points to string
;
puts:
    push si
    push ax
    push bx

.loop:
    lodsb
    or al, al
    jz .done

    call putc

    jmp .loop

.done:
    pop bx
    pop ax
    pop si
    ret

flush:
    mov [ibuff_pointer], word ibuff + 2
    ret

ibuff_pointer: dw word ibuff + 2

msg_kernel:     db 'Execution role teleported to kernel!', ENDL
                db "  _____ ___ __  __ ___  ___  ___   _   _    ", ENDL
                db " |_   _| __|  \/  | _ \/ _ \| _ \ /_\ | |   ", ENDL
                db "   | | | _|| |\/| |  _| (_) |   // _ \| |__ ", ENDL
                db "   |_| |___|_|  |_|_|  \___/|_|_/_/ \_|____|", ENDL
                db "KERNEL INTERFACE 2023", ENDL
                db "--- INPUT BUFFER ---", ENDL, 0x00

ibuff:          db "> ", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00