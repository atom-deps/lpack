#!/bin/bash -e
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

if [ ! -d "${btrfsmount}" ]; then
	echo "${btrfsmount} does not exist; skipping"
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
	dest="${btrfsmount}/$3"
	if [ ! -f "${blob}" ]; then
		echo "Missing blob in OCI image: $3"
		exit 1
	fi
	if [ -d "${dest}" ]; then
		return
	fi
	if [ "$2" = "first" ]; then
		btrfs subvolume create "${dest}" || true
	else
		lower="${btrfsmount}/$2"
		btrfs subvolume snapshot "${lower}" "${dest}"
	fi
	tar --acls --xattrs -C "${dest}" -xvf "${blob}"
	remove_whiteouts "${dest}"
}

for l in ${labels}; do
	layers=`umoci stat --image ${layoutdir}:${l} | grep sha256 | cut -c 8-71`
	if [ -z "${layers}" ]; then
		btrfs subvolume create "${btrfsmount}/${l}" || true
		continue
	fi
	prev="first"
	for layer in ${layers}; do
		if [ "${layer:0:7}" = "sha256:" ]; then
			unpack "${layoutdir}" "${prev}" "${layer}"
			prev="${layer}"
		fi
	done
done
