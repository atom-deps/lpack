#!/bin/bash -e
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

# set -x

. $(dirname $0)/common.sh
id_check

python -c "import pytz" || { echo "python pytz (python-tz) timezone package not found"; exit 1; }
gen_newtag() {
    d=`date "+%Y-%m-%d"`
    tags=`umoci ls --layout "${layoutdir}" | grep "$d" | sort | tail -1`
    if [ -z "${tags}" ]; then
        echo "${d}_v1"
        return
    fi
    v=`echo "${tags}" | sed -e 's/^.*v//'`
    v=$((v+1))
    echo "${d}_v${v}"
    return
}

if [ $# = 1 ]; then
    newtag=$1
else
    newtag=$(gen_newtag)
fi

if [ ! -d "${btrfsmount}/mounted" ]; then
    echo "No tags are checked out"
    exit 1
fi

reftag="$(cat ${basedir}/btrfs.mounted_tag)"
refsha="$(cat ${basedir}/btrfs.mounted_sha)"

workspace="${basedir}/WORKSPACE"
rm -rf -- "${workspace}"
mkdir ${workspace}

cleanup() {
    rm -rf -- "${workspace}"
}
trap cleanup EXIT

# --no-dereference fails when you have a symlink directory...
# There has to be a better way, but really we're going to drop this shell
# code anyway so deal with it for now
#diff --no-dereference -Nrq "${btrfsmount}/${refsha}" "${btrfsmount}/mounted" | while read line; do
dir1="${btrfsmount}/${refsha}"
dir2="${btrfsmount}/mounted"
dir1len=${#dir1}
dir2len=${#dir2}
diff -Nrq "${dir1}" "${dir2}" | while read line; do
    # TODO - this is obviously insufficient - needs to i.e.
    # maintain mtime etc.  That will all be fixed when we just
    # start using the oci or umoci go libraries.
    # echo $line
    set - $line
    if [ "$1" = "Only" ]; then
        # Only in /tmp/btrfs/mounted/dev: null
        l2=${#3}
        l2=$((l2-1))   # drop the trailing :
        if [ "${3:0:$dir1len}" = "${dir1}" ]; then
            l2=$((l2 - dir1len))
            full1="$dir1${3:$dir1len:$l2}/$4"
            full2="$dir2${3:$dir1len:$l2}/$4"
        elif [ "${3:0:dir2len}" = "${dir2}" ]; then
            l2=$((l2 - dir2len))
            full1="$dir1${3:$dir2len:$l2}/$4"
            full2="$dir2${3:$dir2len:$l2}/$4"
        else
            echo "Error: couldn't figure out the diff meaning of: $line"
            exit 1
        fi
    elif [ "$1" = "File" ]; then
        # Example:
        # File /var/lib/atom/btrfs/975a316af08091b77ff5c213fabb953a8afa53ba7893a303602e05fb9dc18f0c/fifo1 is a fifo while file /var/lib/atom/btrfs/mounted/fifo1 is a character special file
        full1="$2"
        full2="$8"
    else
        full1="$2"
        full2="$4"
    fi
    # echo "Comparing $full1 to $full2"
    cmp="${btrfsmount}/mounted/"
    len=${#cmp}
    f2=`echo ${full2} | cut -c ${len}-`
    dir=`dirname "${f2}"`
    fnam2=`basename "${f2}"`
    if [ ! -z "$(dir)" ]; then
        mkdir -p "${workspace}/${dir}"
    fi
    if [ ! -e "${full2}" -a ! -h "${full2}" ]; then
        # whiteout
        mknod "${workspace}/${dir}/.wh.${fnam2}" c 0 0
    else
        if [ -d "${full1}" ]; then
            mkdir "${workspace}/${f2}"
        else
            cp -a "${full2}" "${workspace}/${f2}" || { echo "Failure copying ${workspace}/${f2}"; true; }
        fi
    fi
done

(cd "${workspace}"; tar --acls --xattrs -cf ../WORKSPACE.tar .)
diffshasum=`sha256sum ${basedir}/WORKSPACE.tar | awk '{ print $1 }'`
gzip -n ${basedir}/WORKSPACE.tar
newshasum=`sha256sum ${basedir}/WORKSPACE.tar.gz | awk '{ print $1 }'`
mv ${basedir}/WORKSPACE.tar.gz "${layoutdir}/blobs/sha256/${newshasum}"
mv "${btrfsmount}/mounted" "${btrfsmount}/${newshasum}"
$(dirname $0)/add_oci_tag.py "${layoutdir}" "${reftag}" "${newtag}" "${diffshasum}" "${newshasum}"
