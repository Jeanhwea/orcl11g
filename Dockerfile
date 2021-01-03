FROM centos:7.7.1908
LABEL author="Jinghui Hu"

ADD assets /assets
ENV USE_TUNA_UPSTREAM=n
RUN chmod -R 755 /assets
RUN /assets/setup.sh

EXPOSE 1521
EXPOSE 8080

ENTRYPOINT /assets/entrypoint.sh
