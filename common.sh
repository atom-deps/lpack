set -e

# Default to everything under cwd
# Basedir is where we keep a few things like the mounted tag and a tmpdir "WORKSPACE"
# where we stage new directories to tar up.
basedir="$(pwd)"
# layoutdir is the OCI layout directory
layoutdir="${basedir}/oci"
# lofile is the btrfs loopback file
lofile="${basedir}/btrfs.img"
# btrfsmount is where the btrfs filesystem is mounted.
btrfsmount="${basedir}/btrfs"

parse_config() {
    x="$(mktemp)"
    sed -e 's/:[ \t]*/="/;s/$/"/' "$1" > "${x}"
    . "${x}"
    rm "${x}"
}

# Parse config
# Example config to place the OCI layout and loopback file in /tmp, but keep
# mounted btrfs under $cwd:
# cat > atom_config.yaml << EOF
# layoutdir: /tmp/myimage
# lofile: /tmp/lofile
# EOF
# NOTE - changing this between a setup_btrfs and unsetup_btrfs may lead to
# annoying-to-fix leftovers.  Recommend not doing so.

if [ -f ./atom_config.yaml ]; then
    parse_config ./atom_config.yaml
elif [ -f ~/.config/atom/config.yaml ]; then
    parse_config ~/.config/atom/config.yaml
fi

if [ ! -d "${basedir}" ]; then
	echo "basedir does not exist: ${basedir}"
	exit 1
fi

id_check() {
        if [ $(id -u) != 0 ]; then
                echo "be root"
                exit 1
        fi
}
