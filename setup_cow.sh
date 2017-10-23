#!/bin/bash
# setup_cow.sh: set up copy-on-write over a loopback fs per
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
	${dir}/setup_btrfs.sh $*
elif [ "${driver}" = "lvm" ]; then
	${dir}/setup_lvm.sh $*
fi
