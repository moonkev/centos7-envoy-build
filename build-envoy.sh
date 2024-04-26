#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "You must provide a version to build"
    exit 0
fi

cd /home/build/envoy

echo "Checking out version $1"
git checkout -f v$1

echo "Patching tcp_stats.cc"
sed -e 's/tcpi_data_segs_out/tcpi_segs_out/' source/extensions/transport_sockets/tcp_stats/tcp_stats.cc -i
sed -e 's/tcpi_data_segs_in/tcpi_segs_in/' source/extensions/transport_sockets/tcp_stats/tcp_stats.cc -i
sed -e 's/tcpi_bytes_sent/tcpi_bytes_acked/' source/extensions/transport_sockets/tcp_stats/tcp_stats.cc -i
sed -e 's/tcp_info->tcpi_notsent_bytes/0U/' source/extensions/transport_sockets/tcp_stats/tcp_stats.cc -i
echo "tcp_stats.cc Patched"

echo "Starting Build..."

bazel build -c opt --config=libc++ --verbose_failures --copt="-Wno-error=uninitialized" --local_cpu_resources=$(nproc) //source/exe:envoy-static.stripped
bzip2 -9 -k bazel-bin/source/exe/envoy-static
mv bazel-bin/source/exe/envoy-static.bz2 .