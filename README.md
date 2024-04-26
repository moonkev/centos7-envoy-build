## Docker container to build CentOS/RHEL 7 compatible Envoy Binary

This docker file will create an image that contains all of the tools/libraries necessary to build a
portable, statically compiled Envoy binary which is compatible with glibc 2.17, the version available
in CentOS 7.9 and RHEL 7.9.  Really it should work on any x86 linux with glibc 2.17 or higher.

When starting up the container it will run a bash shell as the user `build`.  You will be place in
the `/home/build/envoy` directory which is a clone of the Envoy repository.  Inside the directory
you will find a file called `build-envoy.sh`.  You simply need to run this shell and it will build
the specified version.  For example

```bash
build $ ./build-envoy.sh 1.30.1
```

will build version 1.30.1 of Envoy.  Note that if a version was released after you initially created
the container you will need to do a git fetch origin to pull down the latest code. After building a
bzipped version of the binary will be available at `/home/build/envoy/envoy-static.bz2`

If you need to peform an actions as root, the build user is able to sudo.  The password for build is
also simply `build`.
