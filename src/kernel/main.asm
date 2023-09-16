org 0x0
bits 16


%define ENDL 0x0D, 0x0A


start:
    ; everything has been initialized
    ; no need to take care of segments and offsets
    mov si, msg_kernel
    call puts

.read_loop:
    call readc
    call putc
    jmp .read_loop

.halt:
    cli
    hlt

; Params:
; null
; Returns:
;   - ah is scancode
;   - al is char(byte) (0x00 if it's special)
readc:
    mov ah, 0x00
    int 0x16 ; see stanis slav
    or al, al
    jz readc 
    ret

; Params:
; - al is char
; Return:
; - none
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

msg_kernel:     db 'Execution role teleported to kernel!', ENDL
                db "  _____ ___ __  __ ___  ___  ___   _   _    ", ENDL
                db " |_   _| __|  \/  | _ \/ _ \| _ \ /_\ | |   ", ENDL
                db "   | | | _|| |\/| |  _| (_) |   // _ \| |__ ", ENDL
                db "   |_| |___|_|  |_|_|  \___/|_|_/_/ \_|____|", ENDL
                db "KERNEL INTERFACE 2023", ENDL
                db "--- INPUT BUFFER ---", ENDL, 0x00