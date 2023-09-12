ASM 	:= nasm
SRC 	:= src
BUILD 	:= build
BOOT 	:= ${SRC}/bootloader
KERNEL 	:= ${SRC}/kernel

.PHONEY: all run floppy_image kernel bootloader clean always

run: floppy_image
	qemu-system-i386 -fda ${BUILD}/main_floppy.img


floppy_image: ${BUILD}/main_floppy.img

${BUILD}/main_floppy.img: bootloader kernel
	mformat -C -v NBOS -f 1440 -i ${BUILD}/main_floppy.img
	dd if=${BUILD}/bootloader.bin of=${BUILD}/main_floppy.img conv=notrunc
	mcopy -i ${BUILD}/main_floppy.img ${BUILD}/kernel.bin "::kernel.bin"


bootloader: ${BUILD}/bootloader.bin

${BUILD}/bootloader.bin: always
	${ASM} ${BOOT}/boot.asm -f bin -o ${BUILD}/bootloader.bin


kernel: ${BUILD}/kernel.bin

${BUILD}/kernel.bin: always
	${ASM} ${KERNEL}/main.asm -f bin -o ${BUILD}/kernel.bin


always: 
	mkdir -p ${BUILD}
	mkdir -p ${SRC}
	mkdir -p ${BOOT}
	mkdir -p ${KERNEL}

clean:
	rm -rf ${BUILD}/*
