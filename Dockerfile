FROM ghcr.io/ytsaurus/ytsaurus:stable-23.2.0 as ytsaurus
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y supervisor python3 python3-pip containerd less wget iptables sudo && apt-get clean

RUN wget https://github.com/containerd/nerdctl/releases/download/v1.5.0/nerdctl-1.5.0-linux-amd64.tar.gz && \
    tar -zxf nerdctl-1.5.0-linux-amd64.tar.gz nerdctl && \
    mv nerdctl /usr/bin/nerdctl && \
    rm nerdctl-1.5.0-linux-amd64.tar.gz

RUN wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz && \
    mkdir -p /opt/cni/bin/ && \
    tar -zxf cni-plugins-linux-amd64-v1.3.0.tgz -C /opt/cni/bin/ && \
    rm cni-plugins-linux-amd64-v1.3.0.tgz

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
COPY ./modprobe /usr/local/bin/

VOLUME /var/lib/containerd
#VOLUME /run/containerd

RUN for PROGRAM in master http-proxy node scheduler controller-agent job-proxy exec discovery clock cell-balancer \
      master-cache proxy queue-agent replicated-table-tracker tablet-balancer timestamp-provider tools; \
    do ln -s /usr/bin/ytserver-all /usr/bin/ytserver-$PROGRAM; done

RUN for PROGRAM in master http-proxy node scheduler controller-agent job-proxy exec discovery clock cell-balancer \
      master-cache proxy queue-agent replicated-table-tracker tablet-balancer timestamp-provider tools; \
    do ln -s /usr/bin/ytserver-all /usr/local/bin/ytserver-$PROGRAM; done


CMD ["supervisord"]
