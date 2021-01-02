Image for running Oracle Database 11g Standard/Enterprise. Due to oracle license restrictions image is not contain database itself and will install it on first run from external directory.

``This image for development use only``

# Usage
Download database installation files from [Oracle site](http://www.oracle.com/technetwork/database/in-memory/downloads/index.html) and unpack them to **install_folder**.
Run container and it will install oracle and create database:

```sh
docker run --privileged --name orcl11g -p 1521:1521 -v <install_folder>:/install orcl11g
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

Optionally you can map dpdump folder to easy upload dumps:
```sh
docker run --privileged --name orcl11g -p 1521:1521 -v <install_folder>:/install -v <local_dpdump>:/u01/app/dpdump orcl11g
```
To execute impdp/expdp just use docker exec command:
```sh
docker exec -it orcl11g impdp ..
```
