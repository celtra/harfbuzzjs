#!/bin/bash
set -e

# Build fribidi based on https://github.com/celtra/harfbuzzjs/blob/main/fribidi.js/build.sh
(cd fribidi; rm -rf build; meson build -Ddocs=false; ninja -Cbuild)

emcc \
	-fno-exceptions \
	-fno-rtti \
	-fno-threadsafe-statics \
	-fvisibility-inlines-hidden \
	-flto \
	-Oz \
    -r \
	-Ifribidi/lib \
    -Ifribidi/build/lib \
    -Ifribidi/build/gen.tab/ \
    fribidi/lib/fribidi*.c \
	--no-entry \
    -UHAVE_CONFIG_H \
    -DHAVE_STRINGIZE -DHAVE_MEMORY_H -DHAVE_MEMSET -DHAVE_MEMMOVE -DHAVE_STRING_H \
    -DSTDC_HEADERS -DHAVE_STDLIB_H -DFRIBIDI_NO_DEPRECATED \
	-o fribidi.o


# Build harfbuzz, based (copied) on https://github.com/harfbuzz/harfbuzzjs/blob/main/build.sh

em++ \
	-std=c++11 \
	-fno-exceptions \
	-fno-rtti \
	-fno-threadsafe-statics \
	-fvisibility-inlines-hidden \
	-flto \
	-Oz \
	-I. \
	-DHB_TINY \
	-DHB_USE_INTERNAL_QSORT \
	-DHB_CONFIG_OVERRIDE_H=\"config-override.h\" \
	-DHB_EXPERIMENTAL_API \
	--no-entry \
	-r \
	-o hb.o \
	hbjs.cc

# Build raqm (a wrapper around harfbuzz and fribidi)
# Configure 
(cd libraqm-nofreetype; rm -rf build; ./autogen.sh; ./configure)

emcc \
	-fno-exceptions \
	-fno-rtti \
	-fno-threadsafe-statics \
	-fvisibility-inlines-hidden \
	-flto \
	-Oz \
	fribidi.o \
	hb.o \
	-Ifribidi/lib \
	-Iharfbuzz/src/ \
	libraqm-nofreetype/src/raqm.c \
	-DDONT_HAVE_FRIBIDI_CONFIG_H \
	-DDONT_HAVE_FRIBIDI_UNICODE_VERSION_H \
	-DUSE_FRIBIDI_EX_API \
	--no-entry \
	-sLLD_REPORT_UNDEFINED \
	-s EXPORTED_FUNCTIONS=@hbjs.symbols \
	-s INITIAL_MEMORY=100MB \
	-s WASM=1 \
	-o raqm.wasm
