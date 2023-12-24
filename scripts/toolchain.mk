# This contains various build processes to build toolchain
include global.mk

TOOLCHAIN_PREFIX = ${PROJECT_ROOT}/toolchain/${TARGET}
export PATH := ${TOOLCHAIN_PREFIX}/bin:${PATH}

BINUTILS_BUILD := ${PROJECT_ROOT}/toolchain/binutils-build-${BINUTILS_VERSION}
BINUTILS_SRC := ${PROJECT_ROOT}/toolchain/binutils-${BINUTILS_VERSION}
BINUTILS_FILENAME := binutils-${BINUTILS_VERSION}.tar.gz

.PHONEY: toolchain toolchain_binutils clean_binutils always clean

toolchain: always toolchain_binutils

toolchain_binutils: binutils_download
	mkdir -p ${BINUTILS_BUILD}
	cd ${BINUTILS_BUILD} && ${BINUTILS_SRC}/configure	\
						--prefix="${TOOLCHAIN_PREFIX}"								\
						--target="${TARGET}"													\
						--with-sysroot --disable-nls --disable-werror
	
	${MAKE} -j8 -C ${BINUTILS_BUILD}
	${MAKE} -j8 -C ${BINUTILS_BUILD} install

binutils_download: ${BINUTILS_SRC}
${BINUTILS_SRC}: ${PROJECT_ROOT}/toolchain/${BINUTILS_FILENAME}
	cd ${PROJECT_ROOT}/toolchain && tar -xf ${PROJECT_ROOT}/toolchain/${BINUTILS_FILENAME} -C ${PROJECT_ROOT}/toolchain

${PROJECT_ROOT}/toolchain/${BINUTILS_FILENAME}:
	mkdir -p ${PROJECT_ROOT}/toolchain 
	cd ${PROJECT_ROOT}/toolchain && wget https://ftp.gnu.org/gnu/binutils/${BINUTILS_FILENAME}

clean_binutils:
	rm -rf ${BINUTILS_BUILD}
	rm -rf ${BINUTILS_SRC}
	rm -rf ${PROJECT_ROOT}/toolchain/${BINUTILS_FILENAME}

always:
	mkdir -p ${PROJECT_ROOT}/toolchain

clean:
	rm -rf ${PROJECT_ROOT}/toolchain