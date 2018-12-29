#!/bin/bash

if [[ -e selections ]] ; then
    rm -f selections
fi 

## Display some useful info about the IRIX files
cd /vagrant/irix

find . -name "fx.*" -type f | sed 's#./#from irixboot:#' | sort > selections
find . -name dist -type d | sed 's#./#from irixboot:#' | sort >> selections
find . -name "*.tardist" | sed 's#./#from irixboot:#' | sort >> selections

exit 0