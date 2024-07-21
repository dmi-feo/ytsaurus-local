#!/usr/bin/env bash

set -ex

/yt_scripts/yt_init/cgroups_enable_nesting.sh
/yt_scripts/yt_init/init_yt_cluster.sh
