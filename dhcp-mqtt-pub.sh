#!/usr/bin/env bash

# Set mosquitto_pub arguments in [scriptname].mosqcfg

DEFUALT_TOPIC="dnsmasq/lease" # default topic if not set in mosqcfg

# Get all arguments and create environment variables named by number starting from 1
argument_count=$#
argument_values=("$@")
for ((x = 1; x <= argument_count; x++)); do
    export DNSMASQ_SCRIPT_ARG_$x="${argument_values[x - 1]}"
done

config_file="${BASH_SOURCE%.*}".mosqcfg
if [ -e "$config_file" ]; then
    # Read config file into array variable
    mapfile -t pub_arguments <"$config_file"
fi

# Iterate arguments in config to check for topic override,
# and remove comment lines, empty lines and invalid (missing prefix) arguments
config_has_topic=false
cleaned_pub_arguments=()
if [[ -v pub_arguments ]]; then
    for arg in "${pub_arguments[@]}"; do
        # clean
        if [ ! -z "$arg" ]; then arg="${arg#"${arg%%[![:space:]]*}"}"; fi # remove leading whitespace characters
        if [ ! -z "$arg" ]; then arg="${arg%"${arg##*[![:space:]]}"}"; fi # remove trailing whitespace characters
        if [ ! -z "$arg" ] && [[ $arg =~ ^#.* ]]; then arg=""; fi         # remove comment lines

        if [ ! -z "$arg" ]; then
            if [[ "$arg" =~ ^(-[a-zA-Z] |--[a-zA-Z]{2,} ) ]]; then
                cleaned_pub_arguments+=($arg)
            else
                echo "Skip invalid argument from $config_file: $arg" >&2
            fi

            # check for argument with topic
            if [ "$config_has_topic" = false ] && [[ "$arg" =~ ^(-t |--topic |-L |--url ) ]]; then
                config_has_topic=true
            fi
        fi
    done
fi

# Set default topic if missing in config
if [ "$config_has_topic" = false ]; then
    cleaned_pub_arguments=(${cleaned_pub_arguments[@]} "--topic" "$DEFUALT_TOPIC")
fi

# Build messages from all environment variables with names starting with DNSMASQ_
# Uses pipe to ensure UTF-8 encoding
env | grep '^DNSMASQ_' | iconv --to-code UTF-8 | mosquitto_pub --stdin-file ${cleaned_pub_arguments[@]}
