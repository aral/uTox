#!/bin/sh
set -eux

. ./extra/travis/env.sh

export TARGET_HOST="--host=x86_64-w64-mingw32"

. ./extra/common/build_nacl.sh

# install libopus, needed for audio encoding/decoding
if ! [ -f $CACHE_DIR/usr/lib/pkgconfig/opus.pc ]; then
  curl http://downloads.xiph.org/releases/opus/opus-1.1.4.tar.gz -o opus.tar.gz
  tar xzf opus.tar.gz
  cd opus-1.1.4
  ./configure --host=x86_64-w64-mingw32 --prefix=$CACHE_DIR/usr
  make -j`nproc`
  make install
  cd ..
  rm -rf opus**
fi

# install libvpx, needed for video encoding/decoding
if ! [ -d libvpx ]; then
  git clone --depth=1 --branch=v1.6.0 https://chromium.googlesource.com/webm/libvpx
fi
cd libvpx
git rev-parse HEAD > libvpx.sha
if ! ([ -f "$CACHE_DIR/libvpx.sha" ] && diff "$CACHE_DIR/libvpx.sha" libvpx.sha); then
  CROSS=x86_64-w64-mingw32- ./configure --target=x86_64-win64-gcc --prefix=$CACHE_DIR/usr --disable-examples --disable-unit-tests --disable-shared --enable-static
  make -j`nproc`
  make install
  mv libvpx.sha "$CACHE_DIR/libvpx.sha"
fi
cd ..
rm -rf libvpx

# install toxcore
if ! [ -d toxcore ]; then
  git clone --depth=1 --branch=$TOXCORE_REPO_BRANCH $TOXCORE_REPO_URI toxcore
fi
cd toxcore
git rev-parse HEAD > toxcore.sha
if ! ([ -f "$CACHE_DIR/toxcore.sha" ] && diff "$CACHE_DIR/toxcore.sha" toxcore.sha); then
  mkdir _build
  cmake -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -B_build -H. -DCMAKE_INSTALL_PREFIX:PATH=$CACHE_DIR/usr -DENABLE_SHARED=0
  make -C_build -j`nproc`
  make -C_build install
  mv toxcore.sha "$CACHE_DIR/toxcore.sha"
fi
cd ..
rm -rf toxcore

if ! [ -d openal ]; then
  git clone --depth=1 https://github.com/irungentoo/openal-soft-tox.git openal
fi
cd openal
git rev-parse HEAD > openal.sha
if ! ([ -f "$CACHE_DIR/openal.sha" ] && diff "$CACHE_DIR/openal.sha" openal.sha ); then
  mkdir -p build
  cd build
  echo "
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)
set(CMAKE_RC_COMPILER x86_64-w64-mingw32-windres)
set(CMAKE_FIND_ROOT_PATH $CACHE_DIR )
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" > ./Toolchain-x86_64-w64-mingw32.cmake
  cmake ..  -DCMAKE_TOOLCHAIN_FILE=./Toolchain-x86_64-w64-mingw32.cmake \
            -DCMAKE_PREFIX_PATH="$CACHE_DIR/usr" \
            -DCMAKE_INSTALL_PREFIX="$CACHE_DIR/usr" \
            -DLIBTYPE="STATIC" \
            -DCMAKE_BUILD_TYPE=Debug \
            -DDSOUND_INCLUDE_DIR=/usr/x86_64-w64-mingw32/include \
            -DDSOUND_LIBRARY=/usr/x86_64-w64-mingw32/lib/libdsound.a
  make
  make install
  cd ..
  mv openal.sha "$CACHE_DIR/openal.sha"
fi
cd ..
rm -rf openal

cp $CACHE_DIR/usr/lib/libOpenAL32.a $CACHE_DIR/usr/lib/libopenal.a || true

curl https://cmdline.org/travis/64/shell32.a > $CACHE_DIR/usr/lib/libshell32.a

# filter_audio
if ! [ -d filter_audio ]; then
    git clone --depth=1 https://github.com/irungentoo/filter_audio
fi
cd filter_audio
git rev-parse HEAD > filter_audio.sha
if ! ([ -f "$CACHE_DIR/filter_audio.sha" ] && diff "$CACHE_DIR/filter_audio.sha" filter_audio.sha); then
    make
    PREFIX="$HOME/cache/usr/" make install
    mv filter_audio.sha "$CACHE_DIR/filter_audio.sha"
fi
rm -rf filter_audio

