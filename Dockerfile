FROM centos:7.7.1908
LABEL author="Jinghui Hu"

ARG TIMEZONE
ENV TIMEZONE=${TIMEZONE:-Asia/Shanghai}
ARG USE_TUNA_UPSTREAM
ENV USE_TUNA_UPSTREAM=${USE_TUNA_UPSTREAM:-n}

ADD assets /assets
RUN chmod -R 755 /assets
RUN /assets/setup.sh

EXPOSE 1521
EXPOSE 8080

ENTRYPOINT /assets/entrypoint.sh
