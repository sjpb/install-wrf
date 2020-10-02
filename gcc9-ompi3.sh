#!/bin/bash

export WRF_BUILD_DIR=~/wrf-build-icc19-impi19
module load spack/git
source $SPACK_ROOT/share/spack/setup-env.sh
module load gcc-9.1.0-gcc-7.2.0-m72nqcu
module load openmpi-3.1.6-gcc-9.1.0-omffmfv

echo Using script ${0} at $(git -C  ${0%/*} describe --always --dirty) > $WRF_BUILD_DIR/README

set -x #echo on
: "${WRF_BUILD_DIR:?Need to set WRF_BUILD_DIR non-empty}"

# gcc:
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran

# prep for build:

mkdir -p $WRF_BUILD_DIR/LIBRARIES
cd $WRF_BUILD_DIR/LIBRARIES
wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/netcdf-4.1.3.tar.gz
DIR=$WRF_BUILD_DIR/LIBRARIES 


# build netcdf 
tar -xzf netcdf-4.1.3.tar.gz
cd netcdf-4.1.3
./configure --prefix=$DIR/netcdf --disable-dap --disable-netcdf-4 --disable-shared
make
make install
make check # DONE
export PATH=$DIR/netcdf/bin:$PATH
export NETCDF=$DIR/netcdf
cd ..

# test netcdf
cd ~/WRF_TESTS
wget http://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_NETCDF_MPI_tests.tar
tar -xf Fortran_C_NETCDF_MPI_tests.tar
cp ${NETCDF}/include/netcdf.inc .
gfortran -c 01_fortran+c+netcdf_f.f
gcc -c 01_fortran+c+netcdf_c.c
gfortran 01_fortran+c+netcdf_f.o 01_fortran+c+netcdf_c.o -L${NETCDF}/lib -lnetcdff -lnetcdf
./a.out
cp ${NETCDF}/include/netcdf.inc .
mpif90 -c 02_fortran+c+netcdf+mpi_f.f
mpicc -c 02_fortran+c+netcdf+mpi_c.c
mpif90 02_fortran+c+netcdf+mpi_f.o 02_fortran+c+netcdf+mpi_c.o -L${NETCDF}/lib -lnetcdff -lnetcdf
mpirun ./a.out

# build WRF
cd $WRF_BUILD_DIR
wget http://www2.mmm.ucar.edu/wrf/src/WRFV3.8.1.TAR.gz
tar -xzf WRFV3.8.1.TAR.gz
mv WRFV3 WRFV3.8.1
cd WRFV3.8.1
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
./configure <<< 34 # gcc+dmpar
sed -i 's/DM_CC           =       mpicc/DM_CC           =       mpicc -DMPI2_SUPPORT/' configure.wrf

./compile -j20 em_real >& log.compile
