# lpack

This is a toy one-night implementation for unpacking an OCI image into
btrfs layers.  Assuming the OCI layout is in /home/serge/project/oci, then
the contents will be expanded under /home/serge/project/btrfs/.  Each layer
represented in a btrfs snapshot named by its shasum under
/home/serge/project/btrfs/.

This will be re-written in go - the bash implementation was to get a
sense of any gotchas which needed to be considered.

## Trying it out

If you do not have a btrfs rootfs, use setup_btrfs.sh to setup and mount
a btrfs-formatted loopback file.

If your rootfs is btrfs, then you could simply mkdir ./btrfs.

Use lpack_unpack.sh to unpack ./oci into ./btrfs (which setup_btrfs has
created).

Use

```bash
lpack_checkout.sh <tag>
```

to check a tag out under ./btrfs/mounted.
You can then make changes to the rootfs under ./btrfs/mounted, and check
the changes in as a new tag using

```bash
./lpack_checkin.sh <newtag>
```

If you do not provide a new tag, then YYYY-MM-DD_vN will be used, where
YYYY-MM-DD is today's date, and N is a unique integer, starting with 1.
For instance, 2017-09-17_v1.
