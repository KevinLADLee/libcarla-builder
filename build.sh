#! /bin/bash
set -e
set -u

# Define argument
CARLA_VERSION=0.9.11
CARLA_REPO=https://github.com/carla-simulator/carla
CARLA_REPO_SUSTECH=https://gitlab.isus.tech/carla-simulator/carla
CARLA_SETUP_PATCH_SUSTECH=https://gitlab.isus.tech/carla1s/sustech-booster/-/raw/master/carla/${CARLA_VERSION}/libcarla-setup.patch
FLAG_SUSTECH=false
FLAG_SUSTECH_SUPPORT=false
SUSTECH_SUPPORT_LIST="0.9.11"  


# Listen parameter
if [[ $# == 0 ]]; then
  echo -e "\033[32mPublic network building start ... \033[0m"
elif [[ $# == 1 ]] && [[ $1 == "sustech" ]]; then
  echo -e "\033[32mSUSTech network building start ... \033[0m";
  CARLA_REPO=$CARLA_REPO_SUSTECH
  FLAG_SUSTECH=true
else
  echo -e "\033[31mParameter error \033[0m"
  exit -1
fi

# CARLA Version check
if [[ $FLAG_SUSTECH == true ]]; then
  for i in $SUSTECH_SUPPORT_LIST;  
  do
    if [[ $i == $CARLA_VERSION ]]; then
      FLAG_SUSTECH_SUPPORT=true 
    fi
  done

  if [[ $FLAG_SUSTECH_SUPPORT == false ]]; then
    echo -e "\033[31mUnsupported CARLA version \033[0m"
    exit -2
  fi
  
fi


# Show arguments
echo  -e "\033[33mSUSTech Flag => $FLAG_SUSTECH \033[0m"
echo  -e "\033[33mCARLA Repo => $CARLA_REPO \033[0m"
echo  -e "\033[33mSetup SUSTech Patch => $CARLA_SETUP_PATCH_SUSTECH \033[0m"

sudo apt-get install -y --no-install-recommends \
        git curl ca-certificates apt-transport-https wget curl \
        cmake build-essential ninja-build zlib1g \
        python3-dev python3-pip 

set +e    
git clone -b ${CARLA_VERSION} ${CARLA_REPO} --depth=1
set -e

sed -i "s@gcc-7@gcc@g" carla/Examples/CppClient/Makefile
sed -i "s@g++-7@g++@g" carla/Examples/CppClient/Makefile
sed -i "s@-Werror@@g" carla/Examples/CppClient/Makefile
cp Setup.sh carla/Util/BuildTools/Setup.sh
# Patch
if [[ $FLAG_SUSTECH == true ]]; then
        rm -rf ./libcarla-setup.patch
        wget ${CARLA_SETUP_PATCH_SUSTECH}
        patch -p0 carla/Util/BuildTools/Setup.sh ./libcarla-setup.patch
        echo -e "\033[32mPatch success \033[0m"
fi

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

echo -e "\033[32mSuccess \033[0m"
