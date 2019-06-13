#! /bin/bash

# -------------------------------------------------------------
# elastic/filebeat build for the raspberry pi
#
# Meant to be run from your raspberry pi directly.
#
# References:
# https://discuss.elastic.co/t/how-to-install-filebeat-on-a-arm-based-sbc-eg-raspberry-pi-3/103670/3
# -------------------------------------------------------------

# -------------------------------------------------------------
# Step 1) Build
# NOTE: the git checkout version needs to match the elastic search API version
# -------------------------------------------------------------
elastic_version="7.1.1"
golang_version="1.12.5"
home="/home/pi"
gopath="${home}/go"
usrlibs="/usr/lib"
elasticpath="${home}/elastic"
beatspath="${elasticpath}/beats"

echo "--------------------------------"
echo "  $(date)"
echo "  Downloading latest golang..."
echo "--------------------------------"
# Raspbian repos only go up to go 1.7, yet the latest elastic builds need 1.9 or newer.
cd ${home}
wget https://dl.google.com/go/go${golang_version}.linux-armv6l.tar.gz
tar -xvf go${golang_version}.linux-armv6l.tar.gz
sudo mv ${home}/go ${usrlibs}
# Just to make sure the current GOPATH has the new version in it.
# You can also overwrite /usr/lib/go (or wherever go is installed), but this is less intrusive.
export GOPATH=${gopath}:$GOPATH
export GOROOT=${usrlibs}/go/bin:$GOROOT

echo "--------------------------------"
echo "  $(date)"
echo "  Downloading sources..."
echo "  NOTE: Expect to see an error about no buildable Go source files."
echo "--------------------------------"
cd go
go get github.com/elastic/beats
# NOTE: Expect to see something like the following line:
# package github.com/elastic/beats: no buildable Go source files in /home/pi/go/src/github.com/elastic/beats
cd ${gopath}/src/github.com/elastic/beats/filebeat/
git checkout "v${elastic_version}"
cd ${gopath}/src/github.com/elastic/beats/heartbeat/
git checkout "v${elastic_version}"

echo "--------------------------------"
echo "  $(date)"
echo "  Building source..."
echo "  Seeing errors here is unexpected."
echo "--------------------------------"
cd ${gopath}/src/github.com/elastic/beats/filebeat/
GOARCH=arm go build
cd ${gopath}/src/github.com/elastic/beats/heartbeat/
GOARCH=arm go build

# -------------------------------------------------------------
# Step 2) Download the tar files necessary to run the executable we just ceated, untar them, and put them together in the executable directory
# The url contains the version number like this: "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.1.1-linux-x86.tar.gz"
# -------------------------------------------------------------

echo "--------------------------------"
echo "  $(date)"
echo "  Creating filebeat in ${home}/elastic/beats/filebeat..."
echo "  Creating heartbeat in ${home}/elastic/beats/heartbeat..."
echo "  Don't forget to update your filebeat.yml and heartbeat.yml files!"
echo "--------------------------------"
mkdir ${elasticpath}
mkdir ${beatspath}

curl -L -O https://artifacts.elastic.co/downloads/beats/heartbeat/heartbeat-${elastic_version}-linux-x86_64.tar.gz
tar xzvf heartbeat-${elastic_version}-linux-x86_64.tar.gz
mv heartbeat-${elastic_version}-linux-x86_64 heartbeat

curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${elastic_version}-linux-x86_64.tar.gz
tar xzvf filebeat-${elastic_version}-linux-x86_64.tar.gz
mv filebeat-${elastic_version}-linux-x86_64 filebeat

mv ${gopath}/github.com/elastic/beats/filebeat/filebeat ${beatspath}/filebeat
mv ${gopath}/github.com/elastic/beats/heartbeat/heartbeat ${beatspath}/filebeat


# -------------------------------------------------------------
# Step 3) Clean up
# -------------------------------------------------------------

echo "--------------------------------"
echo "  $(date)"
echo "  Clearning up..."
echo "--------------------------------"
rm filebeat-${elastic_version}-linux-x86_64.tar.gz
rm heartbeat-${elastic_version}-linux-x86_64.tar.gz
rm go${golang_version}.linux-armv6l.tar.gz

echo "-------------------------------------------------------------"
echo "  $(date)"
echo "  COMPLETE! Copy pibeats.tar.gz to raspberry pi!"
echo ""
echo "  Something like this?"
echo "  scp ./pibeats.tar.gz username@pi_address:/home/username/"
echo "-------------------------------------------------------------"
