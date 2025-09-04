FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    openssh-server \
    gnupg2 \
    apt-transport-https \
    wget \
    curl && \
    mkdir /var/run/sshd

RUN ssh-keygen -A

RUN echo 'root:rootpassword' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

RUN wget -q -O- https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor > /usr/share/keyrings/microsoft.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/microsoft.gpg arch=amd64,armhf,arm64] https://packages.microsoft.com/ubuntu/20.04/mssql-server-2019 focal main" | \
    tee /etc/apt/sources.list.d/mssql-server-2019.list

RUN apt-get update && apt-get install -y mssql-server

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
