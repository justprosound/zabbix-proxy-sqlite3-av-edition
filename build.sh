#!/bin/bash

tag=$1
args=$2
docker buildx build --build-arg ZABBIX_VERSION=$1 . --tag ghcr.io/fullmetal-fred/zabbix-proxy:$1 $2