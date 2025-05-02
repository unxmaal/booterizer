#!/bin/bash
set -e

setup(){
    if ! dpkg -s xfsprogs >/dev/null 2>&1; then
        sudo apt update
        sudo apt install xfsprogs
    fi

    sudo mkdir -p /srv/irix
}

make_irixvol(){
    sudo dd if=/dev/zero of=/srv/irix.img bs=1M count=1024
    sudo losetup -fP /srv/irix.img
    LOOPDEV=$(losetup -j /srv/irix.img | cut -d: -f1)

    if [[ -z "$LOOPDEV" ]]; then
        echo "ERROR: /srv/irix.img is not associated with a loop device."
        exit 1
    fi
}

mount_dev(){
    sudo mkfs.xfs "${LOOPDEV}"
    sudo mount -t xfs "${LOOPDEV}" /srv/irix
}

main(){
    setup
    if [[ ! -f /srv/irix.img ]] ; then
        echo "Creating XFS-formatted volume for IRIX media"
        make_irixvol
    else
        LOOPDEV=$(losetup -j /srv/irix.img | cut -d: -f1)
    fi
    echo "Formatting and mounting IRIX volume"
    mount_dev

}

main
exit $?