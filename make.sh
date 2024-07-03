#!/bin/bash 

# Build / update the Futhark source
bash lib/make_futhark.sh &&

# Build the playground
bash playground/make_pg.sh 


## clang++ -std=c++2c -O2 playground/libfut_nlm_pg.cpp -l m -l cuda -l cudart -l nvrtc -o libfut_nlm_pg lib/libfut_nlm.o

##clang++ 
##
##futhark cuda --library src/libfnlm.fut &&
##clang src/libfnlm.c -c && 
##