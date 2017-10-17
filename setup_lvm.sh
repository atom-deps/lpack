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

id_check

# sadly if we want to be able to run grub, we need a partition
# table, and so we are best off using nbd
modprobe nbd

needattach=0
needfile=0
if ! lsblk | grep -q "${lvdev}"; then
	needattach=1
fi

if [ ! -f "${lofile}" ]; then
	needfile=1
        truncate -s "${lvsize}" "${lofile}"
	sfdisk "${lofile}" << EOF
, 2G;
,,8e;
EOF
	sync
fi

if [ "$needattach" = "1" ]; then
	qemu-nbd -f raw -c "/dev/${lvdev}" "${lofile}"
fi

if [ "$needfile" = "1" ]; then
	pvcreate "/dev/${lvdev}p2"
	vgcreate "${vg}" "/dev/${lvdev}p2"

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
