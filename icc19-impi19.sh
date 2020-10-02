#!/bin/bash

export WRF_BUILD_DIR=~/wrf-build-icc19-impi19
module purge
module load rhel7/default-ccl

echo Using script ${0} at $(git -C  ${0%/*} describe --always --dirty) > $WRF_BUILD_DIR/README

set -x #echo on
: "${WRF_BUILD_DIR:?Need to set WRF_BUILD_DIR non-empty}"

export CC=icc
export CXX=icc
export FC=ifort
export F77=ifort
export DM_FC=mpiifort

# prep for build:
mkdir -p $WRF_BUILD_DIR/LIBRARIES
DIR=$WRF_BUILD_DIR/LIBRARIES

# build netcdf
cd $DIR
[ ! -f netcdf-4.1.3.tar.gz ] && wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/netcdf-4.1.3.tar.gz
[ ! -d netcdf-4.1.3 ] && tar -xzf netcdf-4.1.3.tar.gz
cd netcdf-4.1.3
./configure --prefix=$DIR/netcdf --disable-dap --disable-netcdf-4 --disable-shared
make clean
make
make install
make check
export PATH=$DIR/netcdf/bin:$PATH
export NETCDF=$DIR/netcdf

# build WRF
cd $WRF_BUILD_DIR
[ ! -f WRFV3.8.1.TAR.gz ] && wget http://www2.mmm.ucar.edu/wrf/src/WRFV3.8.1.TAR.gz
if [ ! -d WRFV3.8.1 ]; then
    tar -xzf WRFV3.8.1.TAR.gz
    mv WRFV3 WRFV3.8.1
fi
cd WRFV3.8.1
./clean
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
./configure <<< 15 # INTEL (ifort/icc)
sed -i 's/DM_CC           =       mpicc/DM_CC           =       mpicc -DMPI2_SUPPORT/' configure.wrf
# following based on teams advice try
# Remove '-xHost':
sed 's/-xHost //' -i configure.wrf
# Change architecture flag:
sed "s/-xCORE-AVX2/-march=core-avx2/" -i configure.wrf
# Fix -openmp:
sed 's/-openmp /-qopenmp -qoverride-limits /' -i configure.wrf
./compile em_real >& log.compile
