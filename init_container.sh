#!/usr/bin/env bash

set -ex

if [ "${YTLOCAL_CRI_ENABLED:-0}" == "1" ]
then
  /yt_scripts/yt_init/cgroups_enable_nesting.sh
fi

/yt_scripts/yt_init/init_yt_cluster.sh
