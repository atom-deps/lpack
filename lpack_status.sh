#!/bin/bash -e
# lpack_abort.sh: abort a checkout
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

echo "Layoutdir: ${layoutdir}"

if [ "$driver" != "btrfs" -a "$driver" != "lvm" ]; then
	echo "Driver: vfs"
	exit 0
fi

if [ "$driver" = "btrfs" ]; then
	echo "Driver: btrfs"
	if [ -z "${lofile}" ]; then
		echo "No loopback"
	else
		echo -n "Loopback file: ${lofile}, "
		if [ -f "${lofile}" ]; then
			echo -n "exists, "
			if mountpoint -q "${btrfsmount}"; then
				echo "mounted"
			else
				echo "not mounted"
			fi
		else
			echo "does not exist"
		fi
	fi
	echo "Mountpoint: ${btrfsmount}"
	if [ ! -d "${btrfsmount}/mounted" ]; then
		echo "Nothing is checked out"
	else
		echo "$(cat ${basedir}/btrfs.mounted_tag) is checked out"
	fi
else
	echo "Driver: lvm"
	echo "Volume group: ${vg}"
	if [ -z "${lofile}" ]; then
		echo "No backing file"
	else
		echo "Backing file: ${lofile}"
        lvdev=$(cat .lpack.lvm.loopdev)
		sz=$(cat /sys/class/block/${lvdev}/size)
		if [ $sz -eq 0 ]; then
			echo "Not attached"
		else
			echo "Attached"
		fi
		echo "Loop device: ${lvdev}"
		echo "Configured size: ${lvsize}"
		echo "Thinpool size: ${thinsize}"
	fi
	if ! mountpoint "${lvbasedir}/mounted" > /dev/null 2>&1; then
		echo "Nothing is checked out"
	else
		echo "$(cat ${basedir}/lvm.mounted_tag) is checked out"
	fi
fi
