#!/bin/bash -xe
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

if [ $(id -u) != 0 ]; then
	echo "be root"
	exit 1
fi

basedir=$(pwd)
layoutdir="${basedir}/oci"

mkdir -p "${basedir}/overlay"
if [ ! -d "${basedir}/overlay" ]; then
	echo "${basedir}/overlay does not exist; skipping"
	exit 0
fi

labels=`umoci ls --layout $layoutdir`

remove_whiteouts() {
	find "${dest}" -name ".wh.*" | while read line; do
		fname="$(basename $line)"
		dname="$(dirname $line)"
		delname=$(echo ${fname} | sed -e 's/.wh.//')
		rm "${dname}/${delname}"
		rm "${line}"
	done
}

unpack() {
	blob="$1/blobs/sha256/$3"
	dest="$basedir/overlay/$3/target"
	if [ ! -f "${blob}" ]; then
		echo "Missing blob in OCI image: $3"
		exit 1
	fi
	mkdir -p "$dest"
	if mountpoint -q "${dest}"; then
		return
	fi
	needunpack="yes"
	if [ "$2" != "first" ]; then
		lower="${basedir}/overlay/$2/target"
		work="${basedir}/overlay/$3/work"
		upper="${basedir}/overlay/$3/upper"
		if [ -d "${work}" ]; then
			# Contents never change, so after a reboot don't untar
			needunpack="no"
		fi
		mkdir -p "$lower" "$work" "$upper"
		mount -t overlay -o "lowerdir=${lower},upperdir=${upper},workdir=${work}" "$3" "${dest}"
	fi
	if [ "$needunpack" = "yes" ]; then
		tar -C "${dest}" -xvf "${blob}"
	fi
	remove_whiteouts "${dest}"
}

for l in ${labels}; do
	layers=`umoci stat --image ${layoutdir}:$l | grep sha256 | cut -c 8-71`
	if [ -z "${layers}" ]; then
		mkdir -p "${basedir}/overlay/${l}/target"
		touch "${basedir}/overlay/$l/empty"
		continue
	fi
	prev="first"
	for layer in ${layers}; do
		unpack "${layoutdir}" "${prev}" "${layer}"
		prev="${layer}"
	done
done
