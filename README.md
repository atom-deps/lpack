# lpack

This is a toy one-night implementation for unpacking an OCI image into
overlayfs layers.  Assuming the OCI layout is in /home/serge/oci, then
the contents will be expanded under /home/serge/overlay/.  Each layer
represented by shasum is expanded under /home/serge/overlay/shasum/target.
If it is a bottom layer, then it is simply expanded into that directory.
If it is a higher layer, then it is mounted as an overlay with the next
layer down as the lower layer, and an empty upperdir.  Then the next
layer is untarred.

This will be re-written in go - the bash implementation was to get a
sense of any gotchas which needed to be considered.
