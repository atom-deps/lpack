#!/bin/bash -exu
# lpack_unpack.sh: unpack and OCI image into overlayfs layers.
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

# set -x

. $(dirname $0)/common.sh
id_check

if [ "${driver}" = "vfs" ]; then
	echo "No CoW fs driver registered; skipping"
	exit 0
fi

labels=`umoci ls --layout $layoutdir`

remove_whiteouts() {
	find "${dest}" -name ".wh.*" | while read line; do
		fname="$(basename $line)"
		dname="$(dirname $line)"
		delname=$(echo ${fname} | sed -e 's/.wh.//')
		rm -- "${dname}/${delname}"
		rm -- "${line}"
	done
}

unpack() {
	blob="$1/blobs/sha256/$3"
	if [ "$driver" = "btrfs" ] ;then
		dest="${btrfsmount}/$3"
	else
		dest="${lvbasedir}/$3"
	fi
	if [ ! -f "${blob}" ]; then
		echo "Missing blob in OCI image: $3"
		exit 1
	fi
	if [ -d "${dest}" ]; then
		echo "${dest} already exists"
		return
	fi
	if [ "$2" = "first" ]; then
		if [ "$driver" = "btrfs" ]; then
			btrfs subvolume create "${dest}" || true
		else
			if mountpoint -q "${dest}" > /dev/null 2>&1; then
				return
			fi
			lvcreate -n "$3" -V 10G --thinpool ThinDataLV "${vg}"
			mkfs.ext4 "/dev/${vg}/$3"
			mkdir -p "${dest}"
			mount -t ext4 "/dev/${vg}/$3" "${dest}"
		fi
	else
		if [ "$driver" = "btrfs" ]; then
			lower="${btrfsmount}/$2"
			btrfs subvolume snapshot "${lower}" "${dest}"
		else
			if mountpoint -q "${dest}" > /dev/null 2>&1; then
				return
			fi
			lvcreate -n "$3" --snapshot "${vg}/$2"
			lvchange -ay -K "${vg}/$3"
			mkdir -p "${dest}"
			mount -t ext4 "/dev/${vg}/$3" "${dest}"
			# TODO - we have to persist these mounts across reboots
		fi
	fi
	tar --acls --xattrs -C "${dest}" -xvf "${blob}"
	remove_whiteouts "${dest}"
}

for l in ${labels}; do
	layers=`umoci stat --image ${layoutdir}:${l} | grep sha256` || true
	if [ -z "${layers}" ]; then
		if [ "$driver" = "btrfs" ]; then
			btrfs subvolume create "${btrfsmount}/${l}" || true
		else
			if mountpoint -q "${lvbasedir}/$l" > /dev/null 2>&1; then
				continue
			fi
			lvcreate -n "$l" -V 10G --thinpool ThinDataLV "${vg}"
			mkfs.ext4 "/dev/${vg}/$l"
			mkdir -p "${lvbasedir}/$l"
			mount -t ext4 "/dev/${vg}/$l" "${lvbasedir}/$l"
		fi
		continue
	fi
	prev="first"
	for layer in ${layers}; do
		if [ "${layer:0:7}" = "sha256:" ]; then
			unpack "${layoutdir}" "${prev}" "${layer:7}"
			prev="${layer:7}"
		fi
	done
done
