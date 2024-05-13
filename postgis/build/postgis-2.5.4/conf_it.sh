#!/bin/bash

# Build & install prerequisites:
# /home/al/src/greenplum/PROJ-4.9.3 (with /opt/greenplum-db-6.8.1 prefix)
# /home/al/prj/greenplum/gdal-1.11.1 (with /opt/greenplum-db-6.8.1 prefix)

if ! [ -z "${GPDB_PREFIX}" ]; then
    GPDB_PREFIX=$1
fi

if [ -z "${GPDB_PREFIX}" ]; then
    echo "Please specify Greenplum installation prefix using command line argument or GPDB_PREFIX environment variable"
    exit 1
fi

GPHOME=$GPDB_PREFIX

./configure \
    --prefix=$GPHOME \
    --with-raster --without-topology \
    --with-pgconfig=$GPHOME/bin/pg_config \
    --with-gdalconfig=$GPHOME/bin/gdal-config \
    --with-projdir=$GPHOME
