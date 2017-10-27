#!/bin/bash
# unsetup_lvm.sh: remove lvm on a loopback file
#  Note - this will remove the loopback file, erasing all your data

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

# set -xe

. $(dirname $0)/common.sh

id_check

proceed="?"

if [ "$1" = "-f" -o "$1" = "--force" ]; then
    proceed="y"
fi


for d in ${lvbasedir}/*; do
    umount -l "$d" || true
done

# unmount our --make-shared private mount
umount -l "${lvbasedir}" || true

rm -rf "${lvbasedir}"

loopdev=
if [ -f .lpack.lvm.loopdev ]; then
    dev=$(cat .lpack.lvm.loopdev)
    sz=$(cat /sys/block/${dev}/size)
    if [ $sz -ne 0 ]; then
        loopdev=$dev
    fi
fi

if [ -n "${loopdev}" ]; then
    echo "calling kpartx"
    vgchange -an "${vg}"
    kpartx -vd "${lofile}"
    pvscan --cache
fi

if [ -f "${lofile}" ]; then
    if [ "${proceed}" = "?" ]; then
        read -p "This will remove your lvm backing file - are you sure (y/n)" proceed
    fi
    if [ "${proceed}" = "y" ]; then
        rm -- "${lofile}"
    fi
fi
