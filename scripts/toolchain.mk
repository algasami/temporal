# This contains various build processes to build toolchain
include global.mk

TOOLCHAIN_PREFIX = ${PROJECT_ROOT}/toolchain/${TARGET}
export PATH := ${TOOLCHAIN_PREFIX}/bin:${PATH}

# !!! MAC ONLY (UGLY FIX CURREnTLy)
GMP_LIB := $(shell brew --prefix gmp)
MPFR_LIB := $(shell brew --prefix mpfr)
MPC_LIB := $(shell brew --prefix libmpc)

BINUTILS_BUILD := ${PROJECT_ROOT}/toolchain/binutils-build-${BINUTILS_VERSION}
BINUTILS_SRC := ${PROJECT_ROOT}/toolchain/binutils-${BINUTILS_VERSION}
BINUTILS_FILENAME := binutils-${BINUTILS_VERSION}.tar.gz

GCC_BUILD := ${PROJECT_ROOT}/toolchain/gcc-build-${GCC_VERSION}
GCC_SRC := ${PROJECT_ROOT}/toolchain/gcc-${GCC_VERSION}
GCC_FILENAME := gcc-${GCC_VERSION}.tar.gz

.PHONEY: toolchain toolchain_binutils binutils_download clean_binutils toolchain_gcc gcc_download clean_gcc always clean

toolchain: always toolchain_binutils toolchain_gcc

toolchain_binutils: ${BINUTILS_BUILD}

${BINUTILS_BUILD}: binutils_download
	mkdir -p ${BINUTILS_BUILD}
	cd ${BINUTILS_BUILD} && ${BINUTILS_SRC}/configure	\
						--prefix="${TOOLCHAIN_PREFIX}"	\
						--target="${TARGET}"			\
						--with-sysroot --disable-nls --disable-werror

	cd ${BINUTILS_BUILD}									\
	&& ${MAKE} -j${MAX_THREADS} -C ${BINUTILS_BUILD}		\
	&& ${MAKE} -j${MAX_THREADS} -C ${BINUTILS_BUILD} install

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

toolchain_gcc: ${GCC_BUILD}

${GCC_BUILD}: gcc_download
	mkdir -p ${GCC_BUILD}
	cd ${GCC_BUILD} && ${GCC_SRC}/configure					\
		--target="${TARGET}" --prefix="${TOOLCHAIN_PREFIX}"	\
		--with-gmp="${GMP_LIB}" --with-mpfr="${MPFR_LIB}"	\
		--with-mpc="${MPC_LIB}" --disable-nls				\
		--enable-languages=c,c++ --without-headers
	
	cd ${GCC_BUILD}   								\
	&& ${MAKE} -j${MAX_THREADS} all-gcc				\
	&& ${MAKE} -j${MAX_THREADS} all-target-libgcc	\
	&& ${MAKE} -j${MAX_THREADS} install-gcc			\
	&& ${MAKE} -j${MAX_THREADS} install-target-libgcc

gcc_download: ${GCC_SRC}
${GCC_SRC}: ${PROJECT_ROOT}/toolchain/${GCC_FILENAME}
	cd ${PROJECT_ROOT}/toolchain && tar -xf ${PROJECT_ROOT}/toolchain/${GCC_FILENAME} -C ${PROJECT_ROOT}/toolchain

${PROJECT_ROOT}/toolchain/${GCC_FILENAME}:
	mkdir -p ${PROJECT_ROOT}/toolchain 
	cd ${PROJECT_ROOT}/toolchain && wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${GCC_FILENAME}

clean_gcc:
	rm -rf ${GCC_BUILD}
	rm -rf ${GCC_SRC}
	rm -rf ${PROJECT_ROOT}/toolchain/${GCC_FILENAME}

always:
	mkdir -p ${PROJECT_ROOT}/toolchain

clean:
	rm -rf ${PROJECT_ROOT}/toolchain