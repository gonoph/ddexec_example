# ddexec_example
Example of ddexec project in action using containers

## Summary

This project explores what [DDexec][ddexec] project can do using a read-only container.

[Video here][video]

Essentially:

* even if you have a secure container:
    * read-only filesystem
    * noexec on any writable directory
* you can run any readable file
    * by injecting it into any currently running process
    * hijacking the process to run your program
* all that is needed is a way to access a remote file

The author, [Yago][yago] implemented this in shell as a POC, but this could be implemented in any language.

The [ddexec_test.bash](/ddexec_test.bash) script performs the following:

1. tests if you have docker or podman on your system
2. picks a container image:
    1. For RHEL, CentOS Stream, and Fedora: [UBI9][ubi9]
    2. For Ubuntu and alpine: [alpine][alpine]
3. checks for wget or curl
4. downloads via pipes to file descriptors so nothing is written to the file system
    1. access fake.gz from releases and pipes to uncompress. What this does is [explained below](#to-build-executable-payload)
    2. access ddexec from Yago's repository and pipes it to a shell.
5. runs the shell with the ddexec and fake.gz accessed as file descriptors.

It'll display a silly [cowsay][cowsay].

[ddexec]: https://github.com/arget13/DDexec
[ubi9]: https://catalog.redhat.com/software/base-images#get-images
[alpine]: https://hub.docker.com/_/alpine
[cowsay]: https://en.wikipedia.org/wiki/Cowsay
[video]: https://youtu.be/7dc29U9DeIE?si=uygWoUGebKTZtZN3
[yago]: https://github.com/arget13

## Usage

First, you need podman or docker

```bash
# install podman
$ dnf install container-tools

# -or- docker
$ apt-get install docker
```

Then, you just run the bash script:

```bash
$ ./ddexec_test.bash
Checking for podman or docker: podman
Starting READ-ONLY container with /tmp NOEXEC: ebe36d79e23662f759c857eca1da4c144ae49e52ec57920706f40e538b8cca29
Testing for curl or wget...: /usr/bin/curl
execute using ddexec without writing any files:
 _____________________
< You've been hacked! >
 ---------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/

killing pod: WARN[0001] StopSignal SIGTERM failed to stop container test in 1 seconds, resorting to SIGKILL
```

## To Build executable payload (optional)

```bash
# install the compiler and static libraries (on fedora/centos stream/RHEL)
$ dnf install make gcc glibc-static

# make everything
$ make
```

The executable source is obfuscated, but it does:

1. base64 decodes the stored string.
2. gzip decodes the base64 decoded binary data.
3. displays the text to the screen.
4. is compiled statically, so it should run on most container images and host kernels.

## Impact

Yago's project highlights an important issue with current security strategies: you're never as secure as you think you are.

By itself, it's not super dangerous on the surface:

* you're running a program as the current user
* hijacking a process that the current user already can access
* downloading and running a program that the current user can already do

None of that is novel or new.

However, combined with addtional attacks and methods, then we have a big problem:

* exploiting a vulnerability in a program.
* the ability to download your own code to a secure space.
* to run that code in a secure space.
* piping the payload directly to the script, then no need to write any files.
* implementing the offset and memory handling code in another language, or with rest API calls - would mean you don't even need a shell.
* a payload could then attempt to exploit more weaknesses and elevate more privileges.

Security is layers, and this proof of concept shows that you must always be vigilant against threats, and you must never believe a single, method nor technology will protect you by itself. Containers are a great tool, but they must not be the only tool.
