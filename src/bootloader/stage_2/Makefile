PROJECT_NAME = bootloader
.PHONEY: all install clean

install: ${PROJECT_ROOT}/${BUILD}/stage_2.bin

${PROJECT_ROOT}/${BUILD}/stage_2.bin: main.asm
	${ASM} $^ -f bin -o $@

clean:
	rm -f ${PROJECT_ROOT}/${BUILD}/stage_2.bin
