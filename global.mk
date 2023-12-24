export ASM 			:= nasm
export SRC 			:= src
export BUILD 		:= build
export BOOT 		:= ${SRC}/bootloader
export KERNEL 		:= ${SRC}/kernel
export PROJECT_ROOT := $(abspath .)

export BINUTILS_VERSION := 2.37
export TARGET = i686-elf
export TARGET_ASM = nasm
export TARGET_ASMFLAGS =
export TARGET_CFLAGS = -std=c99 -g #-O2
export TARGET_CC = $(TARGET)-gcc
export TARGET_CXX = $(TARGET)-g++
export TARGET_LD = $(TARGET)-gcc
export TARGET_LINKFLAGS =
export TARGET_LIBS =

