PROJECTS := fat
.PHONEY: all install clean

install:
	for dir in ${PROJECTS}; do \
		${MAKE} -C $$dir install; \
	done

clean:
	for dir in ${PROJECTS}; do \
		${MAKE} -C $$dir clean; \
	done

