FROM centos:7.9.2009

# Initial tools and libraries that we can get from yum repos
RUN yum install -y git
RUN yum install -y zlib-devel
RUN yum install -y krb5-devel
RUN yum install -y bzip2
RUN yum install -y centos-release-scl-rh
RUN yum install -y make
RUN yum install -y sudo

# Install LLVM
RUN <<EOR
bash -c 'cat << EOF > /etc/yum.repos.d/llvmtoolset-build.repo
[llvmtoolset-build]
name=LLVM Toolset 13.0 - Build
baseurl=https://buildlogs.centos.org/c7-llvm-toolset-13.0.x86_64/
gpgcheck=0
enabled=1
EOF'
EOR
RUN yum install -y --nogpgcheck llvm-toolset-13.0-clang-tools-extra llvm-toolset-13.0-clang
RUN cp -r /opt/rh/llvm-toolset-13.0/root/usr/bin/* /usr/bin
RUN cp -r /opt/rh/llvm-toolset-13.0/root/usr/lib64/* /lib64
ENV CC=clang
ENV CXX=clang++

# OpenSSL - needed by cmake
WORKDIR /root
RUN curl -fLO https://www.openssl.org/source/old/1.1.1/openssl-1.1.1w.tar.gz
RUN tar xf openssl-1.1.1w.tar.gz
RUN rm /root/openssl-1.1.1w.tar.gz
WORKDIR /root/openssl-1.1.1w
RUN ./config --prefix=/usr
RUN make -j$(nproc)
RUN make install -j$(nproc)
RUN rm -rf /root/openssl-1.1.1w

# CMake
WORKDIR /root
RUN curl -fLO https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2.tar.gz
RUN tar xf cmake-3.29.2.tar.gz
RUN rm /root/cmake-3.29.2.tar.gz
WORKDIR /root/cmake-3.29.2
RUN ./configure --prefix=/usr
RUN make -j$(nproc)
RUN make install -j$(nproc)
RUN rm -rf /root/cmake-3.29.2

# Bazel - May have to upgrade this for newer versions of Envoy
WORKDIR /usr/bin
RUN curl -fLO https://releases.bazel.build/6.5.0/release/bazel-6.5.0-linux-x86_64
RUN mv bazel-6.5.0-linux-x86_64 bazel
RUN chmod +x bazel

# Ninja
WORKDIR /root
RUN curl -fLO https://github.com/ninja-build/ninja/archive/refs/tags/v1.12.0.tar.gz
RUN tar xf v1.12.0.tar.gz
RUN rm /root/v1.12.0.tar.gz
WORKDIR /root/ninja-1.12.0
RUN ./configure.py --bootstrap
RUN mv /root/ninja-1.12.0/ninja /bin/ninja
RUN rm -rf /root/ninja-1.12.0

# LLVM libc++ standard C++ library and lld linker
WORKDIR /root
RUN git clone https://github.com/llvm/llvm-project.git
WORKDIR /root/llvm-project
RUN git checkout -f llvmorg-13.0.1
RUN cmake -G Ninja -S llvm -B build -DCMAKE_INSTALL_PREFIX=/usr -DLLVM_LIBDIR_SUFFIX=64 -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi;lld"
RUN ninja -C build cxx cxxabi lld
RUN ninja -C build install-cxx install-cxxabi install-lld
# RUN rm -rf /root/llvm-project

# Setup a user for building.  Parts of the build will not let us run it as root.
RUN groupadd -r build
RUN useradd -r -g build build
RUN echo build:build | chpasswd
RUN usermod -aG wheel build
USER build

# Clone Envoy repository and copy over build script
WORKDIR /home/build
RUN git clone https://github.com/envoyproxy/envoy.git
WORKDIR /home/build/envoy
COPY --chown=build ./build-envoy.sh /home/build/envoy

CMD /bin/bash
