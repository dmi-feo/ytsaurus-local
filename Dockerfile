FROM ghcr.io/ytsaurus/ytsaurus-nightly:dev-2024-07-03-c05f760b02d9610bc5f2767e8dfa458c9c66bbd7 as ytsaurus

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y supervisor && apt-get clean

COPY --from=ytsaurus /usr/bin/ytserver-all /usr/bin/ytserver-all
COPY ./configs /configs
COPY ./supervisord.conf /etc/supervisord.conf

RUN for SERVICE in master http-proxy node; \
    do ln -s /usr/bin/ytserver-all /usr/bin/ytserver-$SERVICE; done

CMD ["supervisord"]
