#!/usr/bin/env bash

set -ex

export YT_DRIVER_CONFIG_PATH=/yt_configs/client.yson

yt set //sys/@provision_lock true

yt create group --attr '{name=admins}' --ignore-existing

yt set //sys/schemas/tablet_cell/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/tablet_action/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/tablet_cell_bundle/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/user/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/group/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/rack/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/data_center/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/cluster_node/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/access_control_object_namespace/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/access_control_object_namespace_map/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/medium/@acl '[{action=allow;subjects=[users;];permissions=[read;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]' || yt set //sys/schemas/domestic_medium/@acl '[{action=allow;subjects=[users;];permissions=[read;create;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/account/@acl '[{action=allow;subjects=[users;];permissions=[read;create;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/scheduler_pool/@acl '[{action=allow;subjects=[users;];permissions=[read;create;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/scheduler_pool_tree/@acl '[{action=allow;subjects=[users;];permissions=[read;create;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/access_control_object/@acl '[{action=allow;subjects=[users;];permissions=[read;create;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'
yt set //sys/schemas/account_resource_usage_lease/@acl '[{action=allow;subjects=[users;];permissions=[read;write;create;];};{action=allow;subjects=[admins;];permissions=[read;write;administer;create;remove;];};]'

yt create scheduler_pool_tree --attributes '{name=default; config={nodes_filter=""}}' --ignore-existing

if [ $(yt exists //sys/pool_trees/@default_tree) = 'false' ]; then
  yt set //sys/pool_trees/@default_tree default
fi

if [ $(yt exists //sys/pools) = 'false' ]; then
  yt link //sys/pool_trees/default //sys/pools
fi

yt create scheduler_pool --attributes '{name=research; pool_tree=default}' --ignore-existing
yt create map_node //home --ignore-existing

yt set //sys/@cluster_connection '{
    "cluster_name"=hegel;
    "primary_master"={
        addresses=[
            "localhost:22290";
        ];
        peers=[
            {
                address="localhost:22290";
                voting=%true;
            };
        ];
        "cell_id"="f85de883-ffffffff-10259-ffffffff";
    };
    "discovery_connection"={
        addresses=[
            "localhost:22290";
        ];
    };
    "master_cache"={
        addresses=[
            "localhost:22290";
        ];
        "cell_id"="f85de883-ffffffff-10259-ffffffff";
        "enable_master_cache_discovery"=%false;
    };
}'

yt set //sys/rpc_proxies/@config '{
  "rpc_server" = {
      "services" = {
          "ApiService" = {
              "authentication_queue_size_limit" = 500000;
              "methods" = {
                  "CreateNode" = {
                      "concurrency_limit" = 30000;
                      "queue_size_limit" = 10000000;
                  };
                  "GetNode" = {
                      "concurrency_limit" = 50000;
                      "queue_size_limit" = 500000;
                  };
              };
          };
      };
  };
}'

if [ $(yt exists //sys/controller_agents/config/operation_options/spec_template) = 'false' ]; then
  yt set //sys/controller_agents/config/operation_options/spec_template '{enable_partitioned_data_balancing=%false}' -r
fi

if [ $(yt exists //sys/users/admin) = 'false' ]; then
  yt create user --attributes '{name="admin"}'
  yt execute set_user_password '{user=admin;new_password_sha256="53336a676c64c1396553b2b7c92f38126768827c93b64d9142069c10eda7a721"}'
  yt create map_node '//sys/cypress_tokens/53336a676c64c1396553b2b7c92f38126768827c93b64d9142069c10eda7a721' --ignore-existing
  yt set '//sys/cypress_tokens/53336a676c64c1396553b2b7c92f38126768827c93b64d9142069c10eda7a721/@user' 'admin'
  yt add-member admin superusers
fi

yt create document //sys/client_config -f --attributes '{"value"={"proxy"={"enable_proxy_discovery"=%false};};}'

yt set --format json //sys/rpc_proxies/@balancers '{ "default": { "internal_rpc": { "default": ["localhost:20069"]} } }'

shopt -s nullglob
for filename in /yt_post_init_scripts/*; do "$filename"; done

yt set //sys/@ytsaurus_local_ready '%true'

yt remove //sys/@provision_lock -f  # TODO: consider removing
