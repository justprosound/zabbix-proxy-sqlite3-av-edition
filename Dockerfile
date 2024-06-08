FROM zabbix/zabbix-proxy-sqlite3:ubuntu-7.0-latest
USER root
RUN apt-get update && apt-get install -y \
    iputils-ping \
    iputils-tracepath \
    traceroute \
    fping \
    dnsutils \
    curl \
    wget \
    nano \
    nmap \
    # ncat \
    netcat \
    mtr \
    iproute2 \
    tcpdump \
    snmp
RUN curl -o speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz && tar -xvf speedtest.tgz && mv speedtest /usr/local/bin/speedtest
COPY --chown=1997 --chmod=0711 ./scripts/* /usr/lib/zabbix/externalscripts/
USER 1997