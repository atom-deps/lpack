#!/bin/bash
# unsetup_cow.sh: remove copy-on-write loopback fs per
# the atom_config.yaml configuration

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

## Argument: -f || --force, passed along to unsetup_{lvm|btrfs}.sh

dir=$(dirname $0)
. ${dir}/common.sh

id_check

if [ "${driver}" = "btrfs" ]; then
	if mountpoint -q "${btrfsmount}"; then
		umount -l "${btrfsmount}"
		sleep 2
	fi
	if [ -d "${btrfsmount}" ]; then
		rmdir "${btrfsmount}"
	fi
elif [ "${driver}" = "lvm" ]; then
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
        vgchange -an "${vg}" || true
        kpartx -vd "${lofile}"
        pvscan --cache
    fi

fi
