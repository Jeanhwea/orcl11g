set -e

source /assets/colorecho
trap "echo_red '******* ERROR: Something went wrong.'; exit 1" SIGTERM
trap "echo_red '******* Caught SIGINT signal. Stopping...'; exit 2" SIGINT

#Install prerequisites directly without virtual package
echo "Installing dependencies"
rm /etc/yum.repos.d/*.repo && cp /assets/CentOS-Base.repo /etc/yum.repos.d
yum makecache

yum -y install binutils compat-libstdc++-33 compat-libstdc++-33.i686 ksh \
    elfutils-libelf elfutils-libelf-devel glibc glibc-common glibc-devel \
    gcc gcc-c++ libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc \
    libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make   \
    sysstat unixODBC unixODBC-devel

yum clean all
rm -rf /var/lib/{cache,log} /var/log/lastlog

echo "Creating directories"
mkdir -p -m 755 /u01/app/oracle
mkdir -p -m 755 /u01/app/oraInventory
mkdir -p -m 755 /u01/app/dpdump

echo "Configuring users"
groupadd -g 200 oinstall
groupadd -g 201 dba
groupadd -g 202 oper
useradd -u 440 -g oinstall -G dba,oper -d /u01/app oracle
echo "oracle:install" | chpasswd
echo "root:install" | chpasswd
sed -i "s/pam_namespace.so/pam_namespace.so\nsession    required     pam_limits.so/g" /etc/pam.d/login
chown -R oracle:oinstall /u01/app

cat /assets/profile >> ~oracle/.bash_profile
cat /assets/profile >> ~oracle/.bashrc

echo "Configuring system limits"
cp /assets/sysctl.conf /etc/sysctl.conf
cat /assets/limits.conf >> /etc/security/limits.conf
