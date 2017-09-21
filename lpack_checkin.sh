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

reftag="$(cat ${basedir}/btrfs.mounted_tag)"
workspace="${basedir}/WORKSPACE"
rm -rf "${workspace}"
mkdir ${workspace}

#cleanup() {
#	rm -rf "${workspace}"
#}
#trap cleanup EXIT

diff --no-dereference -Nrq "${basedir}/btrfs/${reftag}" "${basedir}/btrfs/mounted" | while read line; do
	# TODO - this is obviously insufficient - needs to i.e.
	# maintain mtime etc.  That will all be fixed when we just
	# start using the oci or umoci go libraries.
	echo $line
	set - $line
	full1="$2"
	full2="$4"
	cmp="${basedir}/btrfs/mounted/"
	len=${#cmp}
	f2=`echo ${full2} | cut -c ${len}-`
	dir=`dirname "${f2}"`
	fnam2=`basename "${f2}"`
	if [ ! -z "$(dir)" ]; then
		mkdir -p "${workspace}/${dir}"
	fi
	if [ ! -e "${full2}" -a ! -h "${full2}" ]; then
		# whiteout
		mknod "${workspace}/${dir}/.wh_${fnam2}" c 0 0
	else
		if [ -d "${full1}" ]; then
			mkdir "${workspace}/${f2}"
		else
			cp -a "${full2}" "${workspace}/${f2}"
		fi
	fi
done

(cd "${workspace}"; tar --acls --xattrs -cf ../WORKSPACE.tar .)
diffshasum=`sha256sum WORKSPACE.tar | awk '{ print $1 }'`
gzip -n WORKSPACE.tar
newshasum=`sha256sum WORKSPACE.tar.gz | awk '{ print $1 }'`
mv WORKSPACE.tar.gz "${layoutdir}/blobs/sha256/${newshasum}"
mv "${basedir}/btrfs/mounted" "${basedir}/btrfs/${newshasum}"
./add_oci_tag.py "${layoutdir}" "${reftag}" "${newtag}" "${diffshasum}" "${newshasum}"
