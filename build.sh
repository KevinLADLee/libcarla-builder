
#! /bin/bash
set -e
set -u

CARLA_VERSION=0.9.11

sudo apt-get install -y --no-install-recommends \
        git curl ca-certificates apt-transport-https wget curl \
        cmake build-essential ninja-build zlib1g \
        python3-dev python3-pip 

set +e    
# git clone -b ${CARLA_VERSION} https://gitlab.isus.tech/carla-simulator/carla --depth=1
git clone -b ${CARLA_VERSION} https://github.com/carla-simulator/carla --depth=1
set -e

sed -i "s@gcc-7@gcc@g" carla/Examples/CppClient/Makefile
sed -i "s@g++-7@g++@g" carla/Examples/CppClient/Makefile
sed -i "s@-Werror@@g" carla/Examples/CppClient/Makefile
cp Setup.sh carla/Util/BuildTools/Setup.sh

pushd carla > /dev/null

make setup

pushd Examples/CppClient > /dev/null

make build_libcarla

echo "Generate cmake file..."
cat > libcarla-install/LibCarlaClient.cmake << EOL
find_package(JPEG REQUIRED)
find_package(TIFF REQUIRED)
find_package(ZLIB REQUIRED)

include_directories(
        \${LIBCARLA_INSTALL_DIR}/include
        SYSTEM PUBLIC
        \${LIBCARLA_INSTALL_DIR}/include/system
)

link_directories(\${LIBCARLA_INSTALL_DIR}/lib)
link_libraries(
        png
        \${ZLIB_LIBRARIES}
)        

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
