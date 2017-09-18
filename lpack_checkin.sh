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

. common.sh
id_check

gen_newtag() {
	d=`date "+%Y-%m-%d"`
	echo "using date $d" >> /tmp/debug
	tags=`umoci ls --layout "${layoutdir}" | grep "$d" | sort | tail -1`
	if [ -z "${tags}" ]; then
		echo "tags was zero" >> /tmp/debug
		echo "${d}_v1"
		return
	fi
	echo "tags was ${tags}" >> /tmp/debug
	v=`echo "${tags}" | sed -e 's/^.*v//'`
	echo "v was ${v}" >> /tmp/debug
	v=$((v+1))
	echo "${d}_v${v}"
	return
}

if [ $# = 1 ]; then
	newtag=$1
else
	newtag=$(gen_newtag)
fi

if [ ! -d "${basedir}/btrfs/mounted" ]; then
	echo "No tags are checked out"
	exit 1
fi

# XXX must be a better way to do this.  Probably using golang library.
# For now, we unpack the original_tag, copy btrfs/mounted in place of
# rootfs, and then regen
# Ideally we would just generate a new tarball and generate the new
# tag for it ourselves.
# Failing that, we need to keep the full unpacked tree for each label,
# including index.json, so that we can repack without

rm -rf "${basedir}/WORKSPACE"
if [ ! -f "${basedir}/btrfs.mounted_tag" ]; then
	echo "No reference tag: don't know how to checkin"
	exit 1
fi

workspace="${basedir}/WORKSPACE"
reftag="$(cat ${basedir}/btrfs.mounted_tag)"
umoci unpack --image "${layoutdir}:${reftag}" "${workspace}"
rsync -va "${basedir}/btrfs/mounted/" "${workspace}/rootfs"
umoci repack --image "${layoutdir}:${newtag}" "${workspace}"
rm -rf "${workspace}"

# being lazy - make sure to unpack the new tag
./lpack_unpack.sh
btrfs subvolume delete "${basedir}/btrfs/mounted"
