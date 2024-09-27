#!/usr/bin/env bash

set -ex

image_id=$(docker build -q --platform linux/amd64 .)
port_num=$(shuf -i 40000-50000 -n 1)

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo $SCRIPT_DIR/post_init_scripts

container_id=$(docker run -q -d \
  --privileged \
  -p $port_num:80 \
  -e YTLOCAL_AUTH_ENABLED=1 -e YTLOCAL_CRI_ENABLED=1 \
  -v $SCRIPT_DIR/post_init_scripts:/yt_post_init_scripts \
  $image_id)

trap 'docker stop $container_id && docker rm $container_id' EXIT

export YT_TOKEN="topsecret"
export YT_PROXY="localhost:$port_num"

sleep 20s

i=0
while [ 1 ]
do
    ready=$(yt get //sys/@ytsaurus_local_ready 2>/dev/null || echo "false")
    if [ $ready = "%true" ];
    then
      break
    else
      i=$((i + 1))
      if [[ $i = 20 ]]; then exit 1; fi
      sleep 3s
    fi
done

# check dynamic tables
yt set //sys/accounts/tmp/@resource_limits/tablet_count 100500
yt create tablet_cell --attr '{tablet_cell_bundle=default}'

yt create table //tmp/dyntable --attributes '{dynamic=%true;schema=[{name=id;type=uint64;sort_order=ascending};{name=first_name;type=string};{name=last_name;type=string}]}'

yt mount-table //tmp/dyntable

echo '{id=1;first_name=Ivan;last_name=Ivanov}; {id=2;first_name=Petr;last_name=Petrov};{id=3;first_name=Sid;last_name=Sidorov}' |
yt insert-rows //tmp/dyntable --format yson


if [ "$(yt exists //tmp/foo)" != "true" ]; then
  echo "//tmp/foo does not exist" && exit 1
fi

if [ "$(yt exists //tmp/bar)" != "true" ]; then
  echo "//tmp/bar does not exist" && exit 1
fi

timeout --preserve-status -v 3m yt vanilla \
  --tasks '{task={job_count=1; command="python3 --version | grep -q 3.9.19"; docker_image="docker.io/library/python:3.9.19"}}' \
  --spec '{resource_limits={user_slots=1}; max_failed_job_count=1}'

timeout --preserve-status -v 3m yt vanilla \
  --tasks '{task={job_count=1; command="echo $PYTHON_VERSION | grep -q 3.9.19"; docker_image="docker.io/library/python:3.9.19"}}' \
  --spec '{resource_limits={user_slots=1}; max_failed_job_count=1}'


# check auth is working

unset YT_TOKEN
yt list / && { echo "Something wrong with yt auth"; exit 1; } || echo "Auth ok"
