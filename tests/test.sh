#!/usr/bin/env bash

set -ex

image_id=$(docker build -q --platform linux/amd64 .)
port_num=$(shuf -i 40000-50000 -n 1)

container_id=$(docker run -q -d \
  --privileged \
  -p $port_num:80 \
  -e YTLOCAL_AUTH_ENABLED=1 -e YTLOCAL_CRI_ENABLED=1 \
  $image_id)

trap 'docker stop $container_id && docker rm $container_id' EXIT

export YT_TOKEN="topsecret"
export YT_PROXY="localhost:$port_num"

sleep 20s

i=0
while [ 1 ]
do
    lock_exists_str=$(yt exists //sys/@provision_lock 2>/dev/null || echo "true")
    if [[ $lock_exists_str = "false" ]];
    then
      break
    else
      i=$((i + 1))
      if [[ $i = 20 ]]; then exit 1; fi
      sleep 3s
    fi
done


timeout --preserve-status -v 3m yt vanilla \
  --tasks '{task={job_count=1; command="python3 --version | grep -q 3.9.19"; docker_image="docker.io/library/python:3.9.19"}}' \
  --spec '{resource_limits={user_slots=1}; max_failed_job_count=1}'

timeout --preserve-status -v 3m yt vanilla \
  --tasks '{task={job_count=1; command="echo $PYTHON_VERSION | grep -q 3.9.19"; docker_image="docker.io/library/python:3.9.19"}}' \
  --spec '{resource_limits={user_slots=1}; max_failed_job_count=1}'

# check auth is working

unset YT_TOKEN
yt list / && { echo "Something wrong with yt auth"; exit 1; } || echo "Auth ok"
