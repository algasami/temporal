PROJECT_NAME = fat
.PHONEY: all install clean

install: ${PROJECT_ROOT}/${BUILD}/${PROJECT_NAME}.out

${PROJECT_ROOT}/${BUILD}/${PROJECT_NAME}.out: fat.c
	gcc $^ -o $@

clean:
	rm -f ${PROJECT_ROOT}/${BUILD}/${PROJECT_NAME}.out
