#!/usr/bin/env bash

file=ensembleRun
rm $file.log 
python $file.py INI_FILE_HERE &> $file.log
