FROM oraclelinux:8-slim

RUN microdnf update -y && \
    microdnf install -y openssh-server sudo glibc libaio libnsl gcc make binutils && \
    microdnf clean all && \
    microdnf install dnf && \
    dnf install -y oracle-database-preinstall-21c-1.0-1.el8.x86_64 && \
    dnf install -y passwd && \
    dnf install -y ncurses && \
    dnf install -y unixODBC unixODBC-devel curl gnupg2 libaio-devel glibc-devel libgcc glibc-common iputils iproute hostname java-1.8.0-openjdk nmap-ncat

RUN curl -LO https://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli/linuxx64_odbc_cli.tar.gz && \
    mkdir -p /opt/ibm/db2_odbc_cli && \
    tar -xvzf linuxx64_odbc_cli.tar.gz -C /opt/ibm/db2_odbc_cli && \
    rm -f linuxx64_odbc_cli.tar.gz

COPY oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm /tmp/
COPY mysql-connector-odbc-9.0.0-1.el8.x86_64.rpm /tmp/
COPY odbc.ini /etc/
#COPY listener.ora /etc/
#COPY tnsnames.ora /etc/
COPY /gateways_21c/gateways.rsp /tmp/gateways_21c/
COPY /gateways_21c/netca.rsp /tmp/gateways_21c/

COPY LINUX.X64_213000_gateways.zip /tmp/gateways_21c/
RUN unzip tmp/gateways_21c/LINUX.X64_213000_gateways.zip -d /tmp/gateways_21c/ && \
    rm -f tmp/gateways_21c/LINUX.X64_213000_gateways.zip

RUN mkdir -p /u01/app/oracle/product/21c/db1 && \
    mkdir -p /u01/app/oraInventory && \
    mkdir -p /u01/app/oracle/product/21c/db1/hs/admin && \
    mkdir -p /u01/app/oracle/homes/OraDB21Home1/network/admin && \
    mkdir -p /opt/ibm/db2_odbc_cli/clidriver/cfg/


COPY db2cli.ini /opt/ibm/db2_odbc_cli/clidriver/cfg/
COPY LINUX.X64_213000_db_home.zip /tmp/
RUN unzip /tmp/LINUX.X64_213000_db_home.zip -d /u01/app/oracle/product/21c/db1 && \
    rm -f /tmp/LINUX.X64_213000_db_home.zip


COPY .bash_profile /home/oracle/
COPY mydbinstall.rsp /u01/app/oracle/product/21c/db1/

RUN chown -R oracle:oinstall /u01 && \
    chmod -R 775 /u01 && \
    chown -R oracle:oinstall /u01/app/oracle/product/21c/db1 && \
    chmod -R 775 /u01/app/oracle/product/21c/db1/hs/admin && \
    chown -R oracle:oinstall /u01/app/oracle/product/21c/db1/hs/admin && \
    chmod -R 775 /u01/app/oracle/homes/OraDB21Home1/network/admin && \
    chown -R oracle:oinstall /u01/app/oracle/homes/OraDB21Home1/network/admin && \
    chmod 644 /opt/ibm/db2_odbc_cli/clidriver/cfg/db2cli.ini


RUN dnf localinstall -y /tmp/mysql-connector-odbc-9.0.0-1.el8.x86_64.rpm && \
    rm -f /tmp/mysql-connector-odbc-9.0.0-1.el8.x86_64.rpm && \
    dnf clean all

# Microsoft repo setup for RHEL 8
RUN curl https://packages.microsoft.com/config/rhel/8/prod.repo -o /etc/yum.repos.d/mssql-release.repo && \
    ACCEPT_EULA=Y dnf install -y msodbcsql18 && \
    dnf clean all

COPY initdg4msql.ora /u01/app/oracle/product/21c/db1/hs/admin
COPY initdg4odbc.ora /u01/app/oracle/homes/OraDB21Home1/hs/admin/
COPY listener.ora /u01/app/oracle/homes/OraDB21Home1/network/admin
COPY tnsnames.ora /u01/app/oracle/homes/OraDB21Home1/network/admin

RUN chown oracle:oinstall /u01/app/oracle/homes/OraDB21Home1/hs/admin/initdg4odbc.ora \
 && chown oracle:oinstall /u01/app/oracle/product/21c/db1/hs/admin/initdg4msql.ora \
 && chmod 644 /u01/app/oracle/homes/OraDB21Home1/hs/admin/initdg4odbc.ora \
 && chmod 644 /u01/app/oracle/product/21c/db1/hs/admin/initdg4msql.ora

RUN mkdir /var/run/sshd

# Generar claves host para sshd
RUN ssh-keygen -A

# Configurar contraseña root
RUN echo 'root:rootpassword' | chpasswd

# Permitir login root
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
