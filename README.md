# lpack

lpack unpacks OCI images into CoW layers using either btrfs or lvm,
according to a configuration in ./atom_config.yaml.  A sample btrfs
configuration looks like:

```yaml
driver: "btrfs"
layoutdir: ~/oci
lofile: ~/btrfs.img
btrfsmount: ~/experiment
```

A sample lvm configuration is:

```yaml
driver: "lvm"
vg: "atom"
lvbasedir: "~/lvm"
lvdev: "nbd1"
```

The shortest working configuration includes only the driver line,
setting it to either lvm or btrfs.  In this case, the OCI layout
is ./oci, the loopback file is btrfs.img or lvm.img, the LV is
stacker, the lv device is /dev/nbd0, and the layouts are mounted
under ./btrfs or ./lvm.

This will be re-written as 'stacker' (in golang).

## Installing

Since this is a proof of concept, installation is hacky:

```bash
mkdir -p /usr/share/atom
cp *.py *.sh /usr/share/atom
cp lpack /usr/bin
```

## Trying it out

Setup a loopback device using

```bash
lpack setup
```

Tear it down using

```bash
lpack unsetup
```

Unpack the OCI layers using

```bash
lpack unpack
```

Use

```bash
lpack checkout <tag>
```

to check a tag out under ./btrfs/mounted or ./lvm/mounted.

You can then make changes to the rootfs under the mounted directory and check
the changes in as a new tag using

```bash
lpack checkin<newtag>
```

If you do not provide a new tag, then YYYY-MM-DD_vN will be used, where
YYYY-MM-DD is today's date, and N is a unique integer, starting with 1.
For instance, 2017-09-17_v1.

## TODO

This will be merged with 'genoci' and rewritten in golang as
github.com/atom-deps/stacker.
