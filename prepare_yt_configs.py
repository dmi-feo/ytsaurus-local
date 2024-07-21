#!/usr/bin/env python3

import os
from contextlib import contextmanager

import yt.yson


PROXY_CONFIG_PATH = "/yt_configs/proxy.yson"
NODE_CONFIG_PATH = "/yt_configs/node.yson"


@contextmanager
def modify_yt_config(path: str):
    with open(path, "rb+") as f:
        config = yt.yson.load(f)
        f.seek(0)
        yield config
        yt.yson.dump(config, f, yson_format="pretty")
        f.truncate()


if os.environ.get("YTLOCAL_AUTH_ENABLED", "0") == "1":
    with modify_yt_config(PROXY_CONFIG_PATH) as proxy_config:
        proxy_config["auth"]["require_authentication"] = True

    with modify_yt_config(NODE_CONFIG_PATH) as node_config:
        node_config["exec_node"]["job_proxy_authentication_manager"]["require_authentication"] = True


if os.environ.get("YTLOCAL_CRI_ENABLED", "0") == "1":
    with modify_yt_config(NODE_CONFIG_PATH) as node_config:
        node_config["exec_node"]["slot_manager"]["job_environment"] = {
            "type": "cri",
            "job_proxy_image": "ghcr.io/ytsaurus/ytsaurus:stable-23.2.0",
            "use_job_proxy_from_image": False,
            "cri_executor": {
                "runtime_endpoint": "unix:///run/containerd/containerd.sock",
                "image_endpoint": "unix:///run/containerd/containerd.sock",
                "base_cgroup": "/yt",
                "namespace": "yt",
                "retry_backoff_time": 1000,
                "retry_attempts": 1800,
                "retry_error_prefixes": [
                    "server is not initialized yet",
                    "failed to create containerd task: failed to create shim task",
                    "failed to delete containerd container",
                    "failed to prepare extraction snapshot",
                ]
            }
        }
