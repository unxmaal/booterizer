#!/bin/bash

if [[ -e selections ]] ; then
    rm -f selections
fi 

## Display some useful info about the IRIX files
cd /irix

find . -name dist -type d | sed 's#./#from booterizer:#' | sort >> selections
find . -name "*.tardist" | sed 's#./#from booterizer:#' | sort >> selections

exit 0