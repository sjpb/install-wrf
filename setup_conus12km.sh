#!/usr/bin/bash

: "${WRF_BUILD_DIR:?Need to set WRF_BUILD_DIR non-empty}"

set -x #echo on
export RUN_DIR=~/tmp/wrf

#
mkdir -p $RUN_DIR
cp -a $WRF_BUILD_DIR/WRFV3.8.1/test/em_real/* $RUN_DIR # -a needed so symlinked binaries are copied
cd $RUN_DIR
mv namelist.input namelist.input.orig
for benchfile in namelist.input wrfbdy_d01 wrfrst_d01_2001-10-25_00_00_00 # sample_diffwrf_output.txt wrf_reference
do
    wget "http://www2.mmm.ucar.edu/WG2bench/conus12km_data_v3/${benchfile}"
done
sed '/&dynamics/a \ use_baseparam_fr_nml = .t.' -i namelist.input
# not using pnetcdf so io_form_* being 2 already is correct
