Image for running Oracle Database 11g Standard/Enterprise. Due to oracle license
restrictions image is not contain database itself and will install it on first
run from external directory.

``This image for development use only``

# Usage
Extract database installation files to **install_folder**.  Run container and it
will install oracle and create database:

```sh
docker run --privileged \
       --hostname orcl11g.$(hostname) \
       -v <install_folder>:/install \
       -v <local_dpdump>:/u01/app/dpdump \
       -p 1521:1521 \
       --name orcl11g \
       orcl11g
```

Then you can commit this container to have installed and configured oracle database:

```sh
docker commit orcl11g orcl11g-installed
```

Database located in **/u01/app** folder

OS users:
* root/install
* oracle/install

DB users:
* SYS/oracle

SID: *ora11g*


Optionally you can map dpdump folder to easy upload dumps:
```sh
docker run --privileged --detach \
       --hostname orcl11g.$(hostname) \
       -v ~/Public/srv/orcl11g/install:/install \
       -v ~/Public/srv/orcl11g/dpdump:/u01/app/dpdump \
       -p 1521:1521 \
       --name orcl11g \
       orcl11g
```

```sh
docker run --privileged --detach \
       --hostname orcl11g.$(hostname) \
       -v /srv/orcl11g/install:/install \
       -v /srv/orcl11g/dpdump:/u01/app/dpdump \
       -p 1521:1521 \
       --name orcl11g \
       orcl11g
```

To execute impdp/expdp just use docker exec command:
```sh
docker exec -it orcl11g impdp ..
```
