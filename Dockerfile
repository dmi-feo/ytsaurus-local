FROM ghcr.io/ytsaurus/ytsaurus:stable-23.2.0 as ytsaurus
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y \
      supervisor python3 python3-pip containerd less \
      wget iptables sudo \
    && apt-get clean

COPY --from=ytsaurus /usr/bin/ytserver-all /usr/bin/ytserver-all
COPY --from=ytsaurus /usr/bin/init_queue_agent_state /usr/bin/init_queue_agent_state
COPY --from=ytsaurus /usr/bin/init_operation_archive /usr/bin/init_operation_archive
RUN ln -s /usr/bin/init_operation_archive /usr/bin/init_operations_archive

COPY --from=ytsaurus /tmp/ytsaurus_python /tmp/ytsaurus_python
RUN for package in client yson local native_driver; \
  do \
    dist_dir="/tmp/ytsaurus_python/ytsaurus_${package}_dist"; \
    wheel_path="${dist_dir}/$(ls ${dist_dir} | grep "^ytsaurus_$package.*whl$")"; \
    python3 -m pip install ${wheel_path}; \
  done


COPY ./configs /configs
COPY ./supervisord.conf /etc/supervisord.conf

RUN for PROGRAM in master http-proxy node scheduler controller-agent job-proxy exec discovery clock cell-balancer \
      master-cache proxy queue-agent replicated-table-tracker tablet-balancer timestamp-provider tools; \
    do ln -s /usr/bin/ytserver-all /usr/bin/ytserver-$PROGRAM; done


CMD ["supervisord"]
