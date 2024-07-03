#!/bin/bash 

# Build / update the Futhark source
bash lib/make_futhark.sh &&

# Build the playground
bash playground/make_pg.sh 
