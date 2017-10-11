#!/usr/bin/env bash

file=ensembleRun
rm $file.log 
python $file.py NORM &> $file.log
