; directives (are not translated)
org 0x7c00
bits 16 ; backwards compatibility

%define ENDL 0x0D, 0x0A ; carriage return line feed (crlf)

start:
    jmp main


puts:
    push si ; source index register (working with string)
    push ax ; general purpose

    .loop:
        lodsb ; load letters from ds:si to al (0 to 7 bit) and si+=0x01
        ; ^ please refer to felix courier
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
    hlt

    .halt:
        jmp .halt

msg_init: dw "[Success] Initialized Temporal Bootloader", ENDL, 0x0

times 510-($-$$) db 0x00
dw 0xaa55
