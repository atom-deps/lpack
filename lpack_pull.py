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

import os
import json
import yaml
import sys

#  usage: lpack pull docker://dockerhub.example.com/some/image localtag
#  This will copy over the new blob and tags as needed into $layoutdir as
#  localtag, then do a fresh lpack unpack to unpack the new layer

if len(sys.argv) != 3:
    print "Usage: lpack_pull.py docker://dockerurl/image localtag"
    sys.exit(1)

def in_manifests(m, d):
    dname = d['annotations']['org.opencontainers.image.ref.name']
    for t in manifests:
        tname = t['annotations']['org.opencontainers.image.ref.name']
        if tname == dname:
            print "found redundant manifest"
            return True
    return False

# by default work in current dir
basedir = os.getcwd()
layoutname="oci"
layoutdir = basedir + "/" + layoutname

def parse_config_file(filename):
    configs = {}
    retvalues = {}
    with open(filename, "r") as outfile:
        print("loading yaml file: %s" % filename)
        configs = yaml.load(outfile)
        print(configs)
    if "btrfsmount" in configs:
        x = configs["btrfsmount"]
        retvalues["btrfsmount"] = x
    if "layoutdir" in configs:
        retvalues["layoutdir"] = configs["layoutdir"]
    return retvalues

def parse_config():
    filename = "./atom_config.yaml"
    if os.path.exists(filename):
        return parse_config_file(filename)
    filename = "~/.config/atom/config.yaml"
    if os.path.exists(os.path.expanduser(filename)):
        return parse_config_file(filename)
    return {}

configvalues = parse_config()
lpack_info = {}
if "btrfsmount" in configvalues:
    lpack_info = {"btrfsmount": configvalues["btrfsmount"]}
if "layoutdir" in configvalues:
    layoutdir = configvalues["layoutdir"]
    basedir, layoutname = os.path.split(layoutdir)

# grab the existing tags, skopeo will overwrite them
# see https://github.com/projectatomic/skopeo/issues/405

jsonfile = layoutdir + "/index.json"
manifests = []
try:
    with open(jsonfile) as data_file:
        data = json.load(data_file)
        for d in data["manifests"]:
            manifests.append(d)
except:
    pass

cmd = "skopeo copy " + sys.argv[1] + " oci:" + layoutdir + ":" + sys.argv[2]
assert(0 == os.system(cmd))

with open(jsonfile) as data_file:
	data = json.load(data_file)
	for d in data["manifests"]:
		if in_manifests(manifests, d) == False:
			manifests.append(d)

with open(jsonfile) as data_file:
    data = json.load(data_file)
    data["manifests"] = []
    for m in manifests:
        data["manifests"].append(m)

with open(jsonfile, 'w') as outfile:
        json.dump(data, outfile)

# unpack so we can use the new image
cmd = "lpack unpack"
assert(0 == os.system(cmd))
