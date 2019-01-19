#!/bin/bash

## Display some useful info about the IRIX files
cd /irix

echo "__________________  Partitioners found __________________"
find . -name "fx.*" -type f | sed 's#./#bootp():/#' | sort 

echo "__________________ Paths for Inst __________________"
sed 's/from //g' selections
echo ""

exit 0