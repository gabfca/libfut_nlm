#!/bin/bash

# Compile the Futhark source with the CUDA backend. This generates two C files: libfut_nlm.h and libfut_nlm.c
futhark cuda --library lib/futhark/libfut_nlm.fut -o lib/libfut_nlm &&


clang -O2 lib/libfut_nlm.c -c -o lib/libfut_nlm.o