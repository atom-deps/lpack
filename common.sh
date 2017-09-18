basedir=$(pwd)
layoutdir="${basedir}/oci"
lofile="${basedir}/btrfs.img"
btrfsmount="${basedir}/btrfs"

id_check() {
        if [ $(id -u) != 0 ]; then
                echo "be root"
                exit 1
        fi
}
