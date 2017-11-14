#!/bin/bash
# takes top level working directory to search as arg eg "wd"
cwd=$(pwd)
cd $1
echo $1

var1=$(find . _FAILED_RUN |wc -l)
var2=$(find  . _SUCCESSFUL_RUN |wc -l)
var3=$(find  geotop.inpts |wc -l)
var4=$(find  _FAILED_RUN)

echo "Found" $var3 " simulations"
echo "Found" $var2 "successful simulations"
echo "Found" $var1 "failed simulations"
echo "Failed station list:" $var4
cd $cwd