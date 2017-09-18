#!/bin/bash -xe
# lpack_unmount.sh: unmount an overlay-unpacked OCI image, but keep
#  the upperdir (delta) contents
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

if [ $(id -u) != 0 ]; then
	echo "be root"
	exit 1
fi

basedir=$(pwd)

find "${basedir}/overlay" -name target | xargs sudo umount -l
