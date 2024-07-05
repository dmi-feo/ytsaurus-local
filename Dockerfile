FROM ghcr.io/ytsaurus/ytsaurus-nightly:dev-2024-07-03-c05f760b02d9610bc5f2767e8dfa458c9c66bbd7 as ytsaurus

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y supervisor python3 python3-pip && apt-get clean
# RUN pip install ytsaurus-client

COPY --from=ytsaurus /usr/bin/ytserver-all /usr/bin/ytserver-all

COPY --from=ytsaurus /tmp/ytsaurus_python /tmp/ytsaurus_python
RUN for package in client yson local native_driver; \
  do \
    dist_dir="/tmp/ytsaurus_python/ytsaurus_${package}_dist"; \
    wheel_path="${dist_dir}/$(ls ${dist_dir} | grep "^ytsaurus_$package.*whl$")"; \
    python3 -m pip install ${wheel_path}; \
  done


COPY ./configs /configs
COPY ./init.sh /configs
COPY ./client.yson /configs
COPY ./supervisord.conf /etc/supervisord.conf

RUN for SERVICE in master http-proxy node scheduler controller-agent; \
    do ln -s /usr/bin/ytserver-all /usr/bin/ytserver-$SERVICE; done

CMD ["supervisord"]
