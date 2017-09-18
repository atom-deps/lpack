#!/bin/bash -xe
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

if [ $(id -u) != 0 ]; then
	echo "be root"
	exit 1
fi

basedir=$(pwd)
layoutdir="${basedir}/oci"

if [ $# = 0 ]; then
	echo "Usage: $0 tag"
	exit 1
fi

if mountpoint -q "${basedir}/overlay/mounted"; then
	echo "\"$(cat ${basedir}/overlay/mounted_tag)\" is already checked out"
	echo "Please check it in first."
	exit 1
fi

gettag() {
	res=`umoci stat --image ${layoutdir}:$1 | tail -1`
	echo "${res}" | grep -q "^sha256:" || { echo "Bad tag"; exit 1; }
	echo "${res}" | cut -c 8-71
}

tag="$(gettag $1)"
if [ -z "${tag}" ]; then
	echo "Tag not found"
	exit 1
fi

echo "${tag}" > "${basedir}/overlay/mounted_tag"

lower="${basedir}/overlay/${tag}/target"
upper="${basedir}/overlay/upper"
work="${basedir}/overlay/work"
dest="${basedir}/overlay/mounted"
rm -rf "${upper}" "${work}" "${dest}"
mkdir -p "${upper}" "${work}" "${dest}"
mount -t overlay -o "lowerdir=${lower},upperdir=${upper},workdir=${work}" "lpack" "${dest}"
echo "$1 is checked out and mounted under ${basedir}/overlay/mounted"
