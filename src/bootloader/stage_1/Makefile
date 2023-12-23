PROJECT_NAME = bootloader
.PHONEY: all install clean

install: ${PROJECT_ROOT}/${BUILD}/stage_1.bin

${PROJECT_ROOT}/${BUILD}/stage_1.bin: boot.asm
	${ASM} $^ -f bin -o $@

clean:
	rm -f ${PROJECT_ROOT}/${BUILD}/stage_1.bin
