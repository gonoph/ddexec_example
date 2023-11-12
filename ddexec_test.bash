#!/bin/sh

# based on https://github.com/arget13/DDexec

e() { echo -en "\x1b[0;33m$1: ";echo -en "\x1b[1;33m"; }
ee() { test -z "$1" && args='-en' || args='-e';echo $args "$1\x1b[0m"; }

cleanup() {
	set +e
	e "killing pod: "
	$CONTAINER stop -t 1 test
	ee ""
}

GET() {
	[[ "$1" == *"/curl" ]] && echo "$1 -s $2 -o $3" && return 0
	[[ "$1" == *"/wget" ]] && echo "$1 -q $2 -O $3" && return 0
	echo "Unknown web command: $1" 1>&2 && exit -1
}

e "Checking for podman or docker:"
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
e "Starting READ-ONLY container with /tmp NOEXEC:"
$CONTAINER run --rm --name=test -d --read-only $IMAGE sleep 3600
ee ""

trap cleanup EXIT

e "Testing for curl or wget..."
WEB=$($CONTAINER exec test sh -c "(which curl;which wget) 2>/dev/null | head -n 1")
ee $WEB

GET "$WEB" "test" "test" > /dev/null

e "downloading compressed binary from this host to container: "
$CONTAINER cp ./fake.gz test:/tmp/fake.gz
ee done

# e "downloading ddexec.sh from github: "
# $CONTAINER exec test $(GET $WEB https://raw.githubusercontent.com/arget13/DDexec/main/ddexec.sh /tmp/ddexec.sh)
# ee done

DDEXEC=$(GET $WEB https://raw.githubusercontent.com/arget13/DDexec/main/ddexec.sh -)

e "set /tmp/fake.gz to execute"
$CONTAINER exec test chmod +x /tmp/fake.gz
ee done

set +e
e "execute /tmp/fake.gz should fail: "
$CONTAINER exec test /tmp/fake.gz
ee ""

set -e
e "execute using ddexec should work: "
echo
$CONTAINER exec test sh -c "gzip -cd /tmp/fake.gz | base64 -w0 | sh <($DDEXEC) fake"
ee ""
