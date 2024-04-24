#!/bin/bash
git submodule update --init --recursive --merge
# Pin yupp version to pre 1.1c4, due to infected file
cd ev3dev-c/yupp
git checkout 05ead45
