#!/bin/bash
# unsetup_btrfs.sh: remove btrfs on a mounted loopback fs
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

if mountpoint -q "${btrfsmount}"; then
	umount -l "${btrfsmount}"
	sleep 2
	rmdir "${btrfsmount}"
fi

if [ -f "${lofile}" ]; then
	rm "${lofile}"
fi
