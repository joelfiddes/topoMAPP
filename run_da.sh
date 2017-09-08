#!/usr/bin/env bash

file=ensembleRun
rm $file.log 
python $file.py gotnorm &> $file.log
