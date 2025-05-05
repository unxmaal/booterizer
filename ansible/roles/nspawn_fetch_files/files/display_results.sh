#!/bin/bash
if [[ -d /irix ]] ; then
  IDIR=/irix
elif [[ -d /srv/irix ]] ; then
  IDIR=/srv/irix
else
  echo "IRIX media dir missing!"
  exit 1
fi

## Display some useful info about the IRIX files
cd "$IDIR"

echo "__________________  Partitioners found __________________"
find . -name "fx.*" -type f | sed 's#./#bootp():/#' | sort

echo "__________________ Paths for Inst __________________"
sed 's/from //g' selections
echo ""
echo "NOTE: MIPSPro items should only be installed AFTER your installed IRIX system has been rebooted!"

exit 0
