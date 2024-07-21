#!/usr/bin/env bash

set -ex

/yt_scripts/prepare_yt_configs.py

exec supervisord
