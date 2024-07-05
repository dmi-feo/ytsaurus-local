#!/usr/bin/env bash

set -ex

export YT_DRIVER_CONFIG_PATH=/configs/client.yson

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

if [ $(yt exists //sys/controller_agents/config/operation_options/spec_template) = 'false' ]; then
yt set //sys/controller_agents/config/operation_options/spec_template '{enable_partitioned_data_balancing=%false}' -r
fi

if [ $(yt exists //sys/users/admin) = 'false' ]; then
yt create user --attributes '{name="admin"}'
yt execute set_user_password '{user=admin;new_password_sha256="3a5745a05f87ddee1db68b217dc043bfa206d1c7aaa1dd0a7dd76b852a733597"}'
yt create map_node '//sys/cypress_tokens/87a5d9406ccf6a42cca510d86e43b20e2943aa7ade7e9129f4f4f947e1b02574' --ignore-existing
yt set '//sys/cypress_tokens/87a5d9406ccf6a42cca510d86e43b20e2943aa7ade7e9129f4f4f947e1b02574/@user' 'admin'
yt add-member admin superusers
fi
