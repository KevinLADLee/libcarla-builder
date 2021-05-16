
#! /bin/bash

set -e
set -u

CARLA_VERSION=0.9.11

sudo apt-get install -y --no-install-recommends \
        git vim sudo curl ca-certificates apt-transport-https wget curl rsync \
        cmake build-essential ninja-build clang-8  \
        python3-dev python3-pip 

sudo ln -sf /usr/bin/clang++-8 /usr/bin/clang++  
sudo ln -sf /usr/bin/clang-8 /usr/bin/clang  

set +e    
git clone -b ${CARLA_VERSION} https://github.com/carla-simulator/carla --depth=1
set -e

pushd carla > /dev/null

sed -i "s@gcc-7@gcc@g" Examples/CppClient/Makefile 
sed -i "s@g++-7@g++@g" Examples/CppClient/Makefile 
sed -i "s@-Werror@@g" Examples/CppClient/Makefile 

sed -i 's/b2/& link=static/' Util/BuildTools/Setup.sh
sed -i 's/configure/& LDFLAGS="-static"/' Util/BuildTools/Setup.sh

make setup

pushd Examples/CppClient > /dev/null

make build_libcarla

echo "Generate cmake file..."
cat > libcarla-install/LibCarlaClient.cmake << EOL
find_package(JPEG REQUIRED)
find_package(TIFF REQUIRED)

include_directories(
        \${LIBCARLA_INSTALL_DIR}/include
        SYSTEM PUBLIC
        \${LIBCARLA_INSTALL_DIR}/include/system
)

link_directories(\${LIBCARLA_INSTALL_DIR}/lib)
link_libraries(
        carla_client
        boost_filesystem
        rpc
        png
        Recast
        Detour
        DetourCrowd
        \${JPEG_LIBRARY}
        \${TIFF_LIBRARY}
)
EOL

tar -czvf libcarla-install.tar.gz libcarla-install
