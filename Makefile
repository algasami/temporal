include global.mk

PREFIX ?= ${BUILD}

PROJECTS := bootloader kernel tools

.PHONEY: all run install install_projects clean clean_projects always

run: ${PREFIX}/main_floppy.img
	qemu-system-i386 -fda $^

install: build
	cp ${BUILD}/main_floppy.img ${PREFIX}

build: floppy_image

floppy_image: ${BUILD}/main_floppy.img

${BUILD}/main_floppy.img: install_projects
	mformat -C -v NBOS -f 1440 -i $@
	dd if=${BUILD}/stage_1.bin of=$@ conv=notrunc
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

