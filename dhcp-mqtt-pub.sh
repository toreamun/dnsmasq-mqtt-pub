#!/usr/bin/env bash

# Set mosquitto_pub arguments in [scriptname].mosqcfg

DEFUALT_TOPIC="dnsmasq/lease" # default topic if not set in mosqcfg

# Get all arguments and create environment variables named by number starting from 1
argument_count=$#
argument_values=("$@")
for (( x=1; x<=argument_count; x++ ))
do
    export DNSMASQ_SCRIPT_ARG_$x="${argument_values[x-1]}"
done

config_file="${BASH_SOURCE%.*}".mosqcfg
if [ ! -e "$config_file" ]
then
    # Read config file into array variable
    mapfile -t pub_arguments < "$config_file"
fi

# Iterate config to check for topic override and remove comment lines and empty lines
config_has_topic=false
cleaned_pub_arguments=()
if [[ -v pub_arguments ]]
then
    for arg in "${pub_arguments}"
    do
        trimmed="${arg#"${arg%%[![:space:]]*}"}"   # remove leading whitespace characters
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"   # remove trailing whitespace characters
        if [[ $trimmed =~ ^#.* ]]; then trimmed=""; fi # remove comment lines
        if [[ $trimmed == "-t *" ]] || [[ $trimmed == "--topic *" ]]; then config_has_topic=true; fi
        if [[ $trimmed == "-L *" ]] || [[ $trimmed == "--url *" ]]; then config_has_topic=true; fi
        if [ ! -z "$trimmed" ]; then cleaned_pub_arguments+=("$trimmed"); fi
    done
fi

# Set default topic if missing in config
if [ "$config_has_topic" = false ]; then cleaned_pub_arguments+=("--topic '$DEFUALT_TOPIC'"); fi

# Build messages from all environment variables with names starting with DNSMASQ_
message=$(env | grep '^DNSMASQ_')

mosquitto_pub -m "$message" ${cleaned_pub_arguments[@]}
