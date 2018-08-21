#!/bin/bash
if [ -z "$1" ] || [ -z "$2" ]
	then
		echo "Usage: $0 <container name> <ssh password>"
		exit 1
fi

CONTAINER_NAME="$1"
ROOT_PASSWORD="$2"

cat > Dockerfile << EOF
FROM ubuntu:16.04

RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo "root:$ROOT_PASSWORD" | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
EXPOSE 1337

RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 -y
RUN apt-get install python vim gdb libc6-dbg libc6-dbg:i386 netcat ucspi-tcp git -y
RUN git clone https://github.com/longld/peda.git ~/peda
RUN echo "source ~/peda/peda.py" >> ~/.gdbinit
RUN git clone https://github.com/scwuaptx/Pwngdb.git ~/Pwngdb/
RUN cp ~/Pwngdb/.gdbinit ~/

CMD ["/usr/sbin/sshd", "-D"]
EOF

docker build -t $CONTAINER_NAME .
docker run -h pwn -v "$(pwd)/shared":"/shared" -d -P --cap-add=SYS_PTRACE --security-opt seccomp=unconfined --name $CONTAINER_NAME $CONTAINER_NAME
echo -n "SSH Port: "
docker port $CONTAINER_NAME 22
echo -n "Port for reverse shell: "
docker port $CONTAINER_NAME 1337
echo "The directory '/shared' is shared between the docker container and the host."
