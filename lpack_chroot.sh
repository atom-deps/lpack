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
id_check

if [ "$driver" != "btrfs" -a "$driver" != "lvm" ]; then
	exit 0
fi

if [ "$driver" = "btrfs" ]; then
	if [ ! -d "${btrfsmount}/mounted" ]; then
		echo "Nothing is checked out"
		exit 0
	fi

	chroot "${btrfsmount}/mounted" $*
else
	if ! mountpoint "${lvbasedir}/mounted" > /dev/null 2>&1; then
		echo "Nothing is checked out"
		exit 0
	fi

	chroot "${lvbasedir}/mounted" $*
fi
