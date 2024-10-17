#!/bin/sh

# Script to update domain entries if their timestamps exceed a predetermined interval

DOMAINS="/data/domains.json"
ERROR_LOG="/data/errors.log"

# Exit if the domains file does not exist (no entries to process)
if [ ! -f "$DOMAINS" ]; then
    exit 0
fi

current_time=$(date +%s)

# Calculate the update interval lapse in seconds (default to 30 days if not set)
lapse=$(( ${UPDATE_INTERVAL_DAYS:-30} * 24 * 60 * 60 ))

jq -c '.[]' "$DOMAINS" | while read -r entry; do
    # Extract the key, IP, and timestamp from the current entry
    key=$(echo "$entry" | jq -r '.key')
    ip=$(echo "$entry" | jq -r '.ip')
    timestamp=$(echo "$entry" | jq -r '.timestamp')

    # Check if the timestamp of the entry exceeds the allowed lapse
    if [ $((current_time - timestamp)) -ge $lapse ]; then
        # Attempt to update the key with the IP using the external service
        if response=$(curl -s -d "key=$key" -d "ip=$ip" https://ipv4.myaddr.tools/update); then
            # If the update was successful, refresh the timestamp in the JSON file
            if [ "$response" == "OK" ]; then
                jq "map(if .key == \"$key\" then .timestamp = $current_time else . end)" "$DOMAINS" >tmp.$$.json && mv tmp.$$.json "$DOMAINS"
            else
                echo "$(date +'%Y-%m-%d %H:%M:%S') - Error: Unexpected response from the server: ['$response'], for key: [$key]." >>"$ERROR_LOG"
                exit 1
            fi
        else
            echo "$(date +'%Y-%m-%d %H:%M:%S') - Error: Curl command failed to execute for key: $key." >>"$ERROR_LOG"
            exit 1
        fi
    fi
done
