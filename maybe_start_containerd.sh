#!/usr/bin/env bash

if [ "${YTLOCAL_CRI_ENABLED:-0}" == "1" ]
then
  exec containerd
fi
