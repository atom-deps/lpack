#!/bin/bash -uex
# setup_lvm.sh: set up lvm on a loopback file

# Copyright (C) 2017 Cisco Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#set -x

. $(dirname $0)/common.sh

loopdev=""
if [ -f .lpack.lvm.loopdev ]; then
    loopdev=$(cat .lpack.lvm.loopdev)
fi
dokpartx() {
    local kpartx_ret=$(sudo kpartx -vas $1)

    [ -z "$kpartx_ret" ] && {
            log "Failed to map image partitions into LVM"
            exit 1
    }

    local kpartx_ret=$(sudo kpartx -vas $1)
    local loopparts=( `echo ${kpartx_ret} | fmt -w 1 | grep ^loop` )
    loopdev=${loopparts[0]::${#loopparts[0]}-2}
    echo $loopdev > .lpack.lvm.loopdev
}


id_check

needattach=1
createdfile=0
# This is dangerous and insufficient - we need a way
# to make sure that *our* lofile is attached to this device
if [ -f .lpack.lvm.loopdev ]; then
    dev=$(cat .lpack.lvm.loopdev)
    sz=$(cat /sys/block/${dev}/size)
    if [ $sz -ne 0 ]; then
        loopdev="$dev"
        needattach=0
    fi
fi

if [ ! -f "${lofile}" ]; then
    createdfile=1
    truncate -s "${lvsize}" "${lofile}"
    sfdisk "${lofile}" << EOF
, 2G;
,,8e;
EOF
    sync
fi

if [ "$needattach" = "1" ]; then
    echo "setting up loopback file: ${lofile}"
    dokpartx "${lofile}"
fi

if [ "$createdfile" = "1" ]; then
    pvcreate "/dev/mapper/${loopdev}p2"
    vgcreate "${vg}" "/dev/mapper/${loopdev}p2"

    # create the thinpool
    # datalv
    lvcreate -n ThinDataLV -L "${thinsize}" "${vg}"
    # metadata lv
    lvcreate -n MetaDataLV -L 1G "${vg}"

    lvconvert -y --type thin-pool --poolmetadata "${vg}/MetaDataLV" "${vg}/ThinDataLV"

    # Now we can create thin lvs using:
    # lvcreate -n thin1 -V 10G --thinpool ThinDataLV "${vg}"
    # and snapshot it using:
    # lvcreate -n thin2 --snapshot ${vg}/thin1
    # lvchange -ay -K ${vg}/thin2
fi

mkdir -p "$lvbasedir"
