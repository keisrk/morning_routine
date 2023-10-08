## Buildstage ##
FROM ghcr.io/linuxserver/openssh-server:latest as buildstage

## Single layer deployed image ##
FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

ARG USER_NAME=guest
ARG USER_GECOS="Guest Account"
ARG USER_EMAIL=guest@morningrouti.ne
ARG ANSIBLE_MAIN=main.docker.yml

# Use the bootstrap script
COPY ./bootstrap.sh /bootstrap.sh
RUN sh /bootstrap.sh

# Set sensible default settings for OpenSSH runtime
ENV USER_NAME=${USER_NAME}
ENV PUID=1000
ENV PGID=1000
ENV DEBIAN_FRONTEND=noninteractive

# Cherry-pick files from openssh-server
COPY --from=buildstage /keygen.sh /keygen.sh
COPY --from=buildstage /etc/motd /etc/motd
COPY --from=buildstage /etc/s6-overlay/s6-rc.d /etc/s6-overlay/s6-rc.d

# A build script taken from linuxserver/openssh-server
RUN \
  apt-get update -y && \
  apt-get upgrade -y && \
  echo "**** install runtime packages ****" && \
  apt-get install -y \
  curl \
  logrotate \
  nano \
  sudo && \
  echo "**** install openssh-server ****" && \
  apt-get install -y \
  openssh-client \
  openssh-server && \
  echo "**** patch executable's name ****" && \
  ln -s /usr/sbin/sshd /usr/sbin/sshd.pam && \
  echo "**** setup openssh environment ****" && \
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
  sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

ENTRYPOINT ["/init"]
