# This contains various build processes to build toolchain
ASM 			:= nasm
BINUTILS_VERSION ?= 2.37
GCC_VERSION ?= 12.3.0

MAX_THREADS := 16

TARGET = i686-elf
TARGET_ASM = nasm
TARGET_ASMFLAGS =
TARGET_CFLAGS = -std=c99 -g #-O2
TARGET_CC = $(TARGET)-gcc
TARGET_CXX = $(TARGET)-g++
TARGET_LD = $(TARGET)-gcc
TARGET_LINKFLAGS =
TARGET_LIBS =

BUILD_PREFIX ?= $(abspath .)/build
PREFIX ?= ${BUILD_PREFIX}
FLAKE ?= false
TARGET_AGNOSTIC_PREFIX := ${PREFIX}
export PATH := ${TARGET_AGNOSTIC_PREFIX}/bin:${PATH}

# !!! MAC ONLY (UGLY FIX CURREnTLy)
UNAME_S := $(shell uname -s)
GMP_LIB := 
MPFR_LIB := 
MPC_LIB := 

ifeq (${UNAME_S}, Darwin)
	GMP_LIB += $(shell brew --prefix gmp)
	MPFR_LIB += $(shell brew --prefix mpfr)
	MPC_LIB += $(shell brew --prefix libmpc)
endif

BINUTILS_BUILD := ${BUILD_PREFIX}/binutils-build-${BINUTILS_VERSION}
BINUTILS_SRC ?= ${BUILD_PREFIX}/binutils-${BINUTILS_VERSION}
BINUTILS_FILENAME := binutils-${BINUTILS_VERSION}.tar.gz

GCC_BUILD := ${BUILD_PREFIX}/gcc-build-${GCC_VERSION}
GCC_SRC ?= ${BUILD_PREFIX}/gcc-${GCC_VERSION}
GCC_FILENAME := gcc-${GCC_VERSION}.tar.gz

.PHONEY: 	toolchain install_binutils 		\
					clean_binutils build_binutils \
					install_gcc build_gcc					\
					clean_gcc always clean build install

build: always build_binutils build_gcc
install: always install_binutils install_gcc 

toolchain: always install_binutils install_gcc

install_binutils: ${BINUTILS_BUILD}
	cd ${BINUTILS_BUILD} \
	&& ${MAKE} -j${MAX_THREADS} -C ${BINUTILS_BUILD} install

${BINUTILS_BUILD}: build_binutils

build_binutils: ${BINUTILS_SRC}
	mkdir -p ${BINUTILS_BUILD}
	cd ${BINUTILS_BUILD} && ${BINUTILS_SRC}/configure	\
						--prefix="${TARGET_AGNOSTIC_PREFIX}"		\
						--target="${TARGET}"										\
						--with-sysroot --disable-nls --disable-werror

	cd ${BINUTILS_BUILD} && ${MAKE} -j${MAX_THREADS}


${BINUTILS_SRC}: ${BUILD_PREFIX}/${BINUTILS_FILENAME}
	# ugly fix! TODO: solve the downloading problem with nix flake
ifneq (${FLAKE}, true)
	cd ${BUILD_PREFIX} && tar -xf ${BUILD_PREFIX}/${BINUTILS_FILENAME} -C ${BUILD_PREFIX}
endif

${BUILD_PREFIX}/${BINUTILS_FILENAME}:
	# ugly fix! TODO: solve the downloading problem with nix flake
	mkdir -p ${BUILD_PREFIX} 
ifneq (${FLAKE}, true)
	cd ${BUILD_PREFIX} && wget https://ftp.gnu.org/gnu/binutils/${BINUTILS_FILENAME}
endif

clean_binutils:
	rm -rf ${BINUTILS_BUILD}
	rm -rf ${BINUTILS_SRC}
	rm -rf ${BUILD_PREFIX}/${BINUTILS_FILENAME}

install_gcc: ${GCC_BUILD}
	cd ${GCC_BUILD}															\
	&& ${MAKE} -j${MAX_THREADS} install-gcc			\
	&& ${MAKE} -j${MAX_THREADS} install-target-libgcc

${GCC_BUILD}: build_gcc

build_gcc: ${GCC_SRC}
	mkdir -p ${GCC_BUILD}
ifeq (${UNAME_S},Darwin)
		cd ${GCC_BUILD} && ${GCC_SRC}/configure											\
			--target="${TARGET}" --prefix="${TARGET_AGNOSTIC_PREFIX}"	\
			--with-gmp="${GMP_LIB}" --with-mpfr="${MPFR_LIB}"					\
			--with-mpc="${MPC_LIB}" --disable-nls											\
			--disable-checking --disable-werror --enable-languages=c --without-headers
else
		cd ${GCC_BUILD} && ${GCC_SRC}/configure					\
			--target="${TARGET}" --prefix="${PREFIX}"			\
			--disable-checking --disable-werror --disable-nls --enable-languages=c --without-headers
endif

	cd ${GCC_BUILD}   												\
	&& ${MAKE} -j${MAX_THREADS} all-gcc				\
	&& ${MAKE} -j${MAX_THREADS} all-target-libgcc

${GCC_SRC}: ${BUILD_PREFIX}/${GCC_FILENAME}
	# ugly fix! TODO: solve the downloading problem with nix flake
ifneq (${FLAKE}, true)
	cd ${BUILD_PREFIX} && tar -xf ${BUILD_PREFIX}/${GCC_FILENAME} -C ${BUILD_PREFIX}
endif

${BUILD_PREFIX}/${GCC_FILENAME}:
	# ugly fix! TODO: solve the downloading problem with nix flake
	mkdir -p ${BUILD_PREFIX} 
ifneq (${FLAKE}, true)
	cd ${BUILD_PREFIX} && wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${GCC_FILENAME}
endif

clean_gcc:
	rm -rf ${GCC_BUILD}
	rm -rf ${GCC_SRC}
	rm -rf ${BUILD_PREFIX}/${GCC_FILENAME}

always:
	mkdir -p ${BUILD_PREFIX}

clean: clean_gcc clean_binutils
