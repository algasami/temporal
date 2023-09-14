org 0x0
bits 16


%define ENDL 0x0D, 0x0A


start:
    ; everything has been initialized
    mov si, msg_kernel
    call puts

.halt:
    cli
    hlt

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

    mov ah, 0x0E ; int 10 - E
    mov bh, 0
    int 0x10

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