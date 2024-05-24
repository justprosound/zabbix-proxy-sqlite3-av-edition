FROM zabbix/zabbix-proxy-sqlite3:trunk-ubuntu
ARG ZBX_REPO_VERSION=6.5
ARG ZBX_REPO_PLATFORM=ubuntu
ARG ZBX_REPO_RELEASE=6.5-1+ubuntu22.04
USER root
RUN apt-get update && apt-get install -y iputils-ping fping dnsutils wget nano nmap iproute2
RUN wget https://repo.zabbix.com/zabbix/${ZBX_REPO_VERSION}/${ZBX_REPO_PLATFORM}/pool/main/z/zabbix-release/zabbix-release_${ZBX_REPO_RELEASE}_all.deb &&\
    dpkg -i zabbix-release_${ZBX_REPO_RELEASE}_all.deb &&\
    rm zabbix-release_${ZBX_REPO_RELEASE}_all.deb
RUN apt-get update && apt-get install -y zabbix-get zabbix-sender
COPY --chown=1997 --chmod=0711 ./scripts/* /usr/lib/zabbix/externalscripts/
USER 1997