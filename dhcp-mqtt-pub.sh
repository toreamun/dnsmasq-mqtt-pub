#!/usr/bin/env bash

export DNSMASQ_ARG_OPERATION=$1
export DNSMASQ_ARG_MAC=$2
export DNSMASQ_ARG_IP=$3
export DNSMASQ_ARG_HOSTNAME=$4

config_file="${BASH_SOURCE%.*}".mosqcfg
if [ ! -e "$config_file" ]
then
  echo "Cannot find required config file: $config_file"
  exit 1
fi

# Read config file into MAPFILE
mapfile -t pub_arguments < "$config_file"

# TODO: argumens
# - remove only whitespace lines
# - trim start and end
# - trim comment lines
# - check config_file not empty
# - remove -m message argument
# - remove set -t argument to default if missing

message=$(env | grep '^DNSMASQ_' | sort)
