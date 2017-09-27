#!/usr/bin/python
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

from datetime import datetime
import pytz
import os
import sys
import json
import hashlib

if len(sys.argv) != 6:
    print("Insufficient arguments")
    sys.exit(1)

layoutdir = sys.argv[1]
oci_idx_file = layoutdir + "/index.json"
reftag = sys.argv[2]
newtag = sys.argv[3]
diffsum = sys.argv[4]
blobsum = sys.argv[5]
blobdir = layoutdir + "/blobs/sha256"

def load_manifest_data(sha):
    data = None
    with open(blobdir + "/" + sha) as indata:
        data = json.load(indata)
    return data

# indata is the loaded oci/index.json
# oldsha is the sha256sum of the layer we appended to
# newsha is the sha256sum of our new layer
# we have to create a new config file listing our newsha as
# a new layer
def set_new_config_file(manifest_data, diffsum, newsha):
    config_shasum = manifest_data["config"]["digest"][7:]
    config_data = load_manifest_data(config_shasum)
    config_data["rootfs"]["diff_ids"].append("sha256:" + diffsum)
    if not "history" in config_data:
        config_data["history"] = []
    config_data["history"].append({
            "created": datetime.now(pytz.timezone("UTC")).isoformat(),
            "created_by": "lpack" })
    tmpfnam = blobdir + "YYY" # TODO use tmpnam
    with open(tmpfnam, "w") as outfile:
        json.dump(config_data, outfile)
    m = hashlib.sha256()
    with open(tmpfnam) as infile:
        blobdata = infile.read()
        m.update(blobdata.encode('utf-8'))
    config_sha = m.hexdigest()
    newname = blobdir + "/" + config_sha
    os.rename(tmpfnam, newname)
    manifest_data["config"]["digest"] = "sha256:" + config_sha
    manifest_data["config"]["size"] = os.stat(newname).st_size
    manifest_data["Create"] = datetime.now().isoformat()

with open(oci_idx_file) as filedata:
    ocidata = json.load(filedata)

oldentry = None
for m in ocidata["manifests"]:
    if m["mediaType"] == "application/vnd.oci.image.manifest.v1+json":
        if m["annotations"]["org.opencontainers.image.ref.name"] == reftag:
            oldentry = m["digest"][7:]
            break

if oldentry is None:
    print("old tag (%s) not found" % reftag)
    sys.exit(1)

# Open the old ref, append our new layer info
oldfnam = layoutdir + "/blobs/sha256/" + oldentry
with open(oldfnam) as filedata:
    manifest_data =  json.load(filedata)
newentry = {}
newentry["mediaType"] = "application/vnd.oci.image.layer.v1.tar+gzip"
newentry["digest"] = "sha256:" + blobsum
newentry["size"] = os.stat(layoutdir + "/blobs/sha256/" + blobsum).st_size
newentry["size"] = os.stat(layoutdir + "/blobs/sha256/" + blobsum).st_size

manifest_data["layers"].append(newentry)
set_new_config_file(manifest_data, diffsum, blobsum)

# Write this as a new file, get sha256sum, put it into place under blobs/sha256
# TODO use tmpfile
with open(layoutdir + "/blobs/sha256/XXX", "w") as outfile:
    json.dump(manifest_data, outfile)

m = hashlib.sha256()
with open(layoutdir + "/blobs/sha256/XXX") as filedata:
    blobdata = filedata.read()
    m.update(blobdata.encode('utf-8'))
newsha = m.hexdigest()

newentry = {}
newentry["mediaType"] = "application/vnd.oci.image.manifest.v1+json"
newentry["size"] = os.stat(layoutdir + "/blobs/sha256/XXX").st_size
newentry["digest"] = "sha256:" + newsha
os.rename(layoutdir + "/blobs/sha256/XXX", layoutdir + "/blobs/sha256/" + newsha)
labeldict = {"org.opencontainers.image.ref.name": newtag}
newentry["annotations"] = labeldict

# Now add the new sha256sum under newtag in oci/index.json

ocidata["manifests"].append(newentry)

with open(oci_idx_file, "w") as outfile:
    json.dump(ocidata, outfile)
