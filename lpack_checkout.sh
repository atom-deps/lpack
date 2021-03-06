#!/bin/bash -e
# lpack_checkout.sh: 'checkout' an OCI layer.  The checked-out layer
#  will be in ./overlay/mounted.  Once updated, you can check it in
#  using "lpack_checkin.sh [newtag]"
#
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

if [ $# = 0 ]; then
	echo "Usage: $0 tag"
	exit 1
fi

if [ "$driver" != "btrfs" -a "$driver" != "lvm" ]; then
	exit 0
fi

if [ "${driver}" = "btrfs" ]; then
	if [ ! -d "${btrfsmount}" ]; then
		echo "${btrfsmount} does not exist: did you forget to 'lpack unpack'?"
		exit 1
	fi
	if [ -d "${btrfsmount}/mounted" ]; then
		echo "\"$(cat ${basedir}/btrfs.mounted_tag)\" is already checked out"
		echo "Please check it in first."
		exit 1
	fi
else
	if mountpoint "${lvbasedir}/mounted" > /dev/null 2>&1; then
		echo "\"$(cat ${basedir}/lvm.mounted_tag)\" is already checked out"
		echo "Please check it in first."
		exit 1
	fi
fi

tag="$(gettag $1)"
if [ -z "${tag}" ]; then
    echo "Tag not found"
    exit 1
fi

if [ "${driver}" = "btrfs" ]; then
	echo "$1" > "${basedir}/btrfs.mounted_tag"
	echo "${tag}" > "${basedir}/btrfs.mounted_sha"
	lower="${btrfsmount}/${tag}"
	dest="${btrfsmount}/mounted"
	btrfs subvolume snapshot "${lower}" "${dest}"
	echo "$1 is checked out and mounted under ${btrfsmount}/mounted"
else
	echo "$1" > "${basedir}/lvm.mounted_tag"
	echo "${tag}" > "${basedir}/lvm.mounted_sha"
	dest="${lvbasedir}/mounted"
	lower="${vg}/${tag}"
	lvcreate -n "mounted" --snapshot "${lower}"
	lvchange -ay -K "${vg}/mounted"
	mkdir -p "${dest}"
	mount -t ext4 "/dev/${vg}/mounted" "${dest}"
fi
