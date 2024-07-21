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
