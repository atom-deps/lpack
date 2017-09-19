#!/usr/bin/python

import os
import sys
import json
import hashlib

oci_idx_file = sys.argv[1]
reftag = sys.argv[2]
newtag = sys.argv[3]
blobsum = sys.argv[4]
with open(oci_idx_file) as filedata:
    data = json.load(filedata)

print(data)

oldentry = None
for m in data["manifests"]:
    if m["datatype"] == "application/vnd.oci.image.manifest.v1+json":
        if m["annotations"]["org.opencontainers.image.ref.name"] == reftag:
            oldentry = m["digest"]

if oldentry is None:
    print "reftag not found"
    sys.exit(1)

# Open the old ref, append our new layer info
oldfnam = "oci/blobs/sha256/" + oldentry[7:]
with open(oldfnam) as filedata:
    olddata =  json.load(filedata)
newentry["mediaType"] = "application/vnd.oci.image.layer.v1.tar+gzip"
newentry["digest"] = "sha256:" + blobsum
newentry["size"] = os.stat("oci/blobs/sha256/" + blobsum).st_size

olddata["layers"].append(newentry)

# Write this as a new file, get sha256sum, put it into place under blobs/sha256
# TODO use tmpfile
with open("oci/blobs/sha256/XXX", "w") as outfile:
    json.dump(olddata, outfile)

m = hashlib.sha256()
with open("oci/blobs/sha256/XXX") as filedata:
    m.update(filedata)
newsha = m.hexdigest()

newentry["mediaType"] = "application/vnd.oci.image.manifest.v1+json"
newentry["size"] = os.stat("oci/blobs/sha256/XXX").st_size
newentry["digest"] = "sha256:" + newsha
labeldict["org.opencontainers.image.ref.name"] = newtag
newentry["annotations"] = labeldict

# Now add the new sha256sum under newtag in oci/index.json
with open(oci_idx_file) as filedata:
    data = json.load(filedata)

data["manifests"].append(newentry)

with open(oci_idx_file, "w") as outfile:
    json.dump(data)
