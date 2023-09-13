PROJECT_NAME = bootloader
.PHONEY: all install clean

install: ${PROJECT_ROOT}/${BUILD}/${PROJECT_NAME}.bin

${PROJECT_ROOT}/${BUILD}/${PROJECT_NAME}.bin: boot.asm
	${ASM} $^ -f bin -o $@

clean:
	rm -f ${PROJECT_ROOT}/${BUILD}/${PROJECT_NAME}.bin
