FROM ibmcom/db2

USER root

# Habilitar SSH y autenticación por contraseña
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    echo 'root:rootpassword' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    
RUN useradd -m db2ssh && echo 'db2ssh:db2password' | chpasswd

EXPOSE 22 50000

CMD ["/bin/bash", "-c", "/usr/sbin/sshd -D & su - db2inst1 -c 'db2start' && tail -f /dev/null"]
