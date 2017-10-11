#!/usr/bin/env bash
file=code_da
rm $file.log 
python writeConfig.py
python $file.py  &> $file.log
