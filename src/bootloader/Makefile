PROJECTS := stage_1 stage_2
.PHONEY: all install clean

install:
	for dir in ${PROJECTS}; do \
		${MAKE} -C $$dir install; \
	done

clean:
	for dir in ${PROJECTS}; do \
		${MAKE} -C $$dir clean; \
	done
	rm -rf ${PROJECT_ROOT}/${BUILD}/bootloader.bin

