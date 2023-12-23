export ASM 			:= nasm
export SRC 			:= src
export BUILD 		:= build
export BOOT 		:= ${SRC}/bootloader
export KERNEL 		:= ${SRC}/kernel
export PROJECT_ROOT := $(abspath .)
PROJECTS := bootloader kernel tools

.PHONEY: all run install install_projects clean clean_projects always

run: ${BUILD}/main_floppy.img
	qemu-system-i386 -fda $^

install: floppy_image

floppy_image: ${BUILD}/main_floppy.img

${BUILD}/main_floppy.img: install_projects
	mformat -C -v NBOS -f 1440 -i $@
	dd if=${BUILD}/bootloader.bin of=$@ conv=notrunc
	mcopy -i $@ ${BUILD}/stage_2.bin "::stage_2.bin"
	mcopy -i $@ ${BUILD}/kernel.bin "::kernel.bin"
	mcopy -i $@ message.txt "::message.txt"

install_projects: always
	for dir in ${PROJECTS}; do \
		${MAKE} -C ${SRC}/$$dir install; \
	done

clean: clean_projects
	rm -f ${BUILD}/main_floppy.img

clean_projects:
	for dir in ${PROJECTS}; do \
		${MAKE} -C ${SRC}/$$dir clean; \
	done


always: 
	mkdir -p ${BUILD}
	mkdir -p ${SRC}
	mkdir -p ${BOOT}
	mkdir -p ${KERNEL}

