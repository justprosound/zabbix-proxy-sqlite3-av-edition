#!/bin/bash

tag=$1
args=$2
docker buildx build . --tag ghcr.io/fullmetal-fred/zabbix-proxy:$1 $2