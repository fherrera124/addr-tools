#!/bin/sh

# add-domain.sh
#
# A command-line utility to associate a domain identifier (key) with an IP address
# through the external myaddr-tools service. Upon successful operation, both the key
# and the associated IP address are stored locally in a JSON file, along with the
# domain name and a timestamp indicating when the update was made.
#
# If the specified key already exists in the JSON file, the optional -o flag must
# be provided, otherwise, the operation will be aborted. The purpose of the flag is to
# prevent unintentional changes to the IP address associated with a given key.
#
# Parameters:
#   -k <key>   : (Required) Domain identifier key.
#   -i <ip>    : (Required) IP address to associate with the given domain identifier key.
#   -o         : (Optional) In case the key is present in the JSON file, allow forced update.
#

DOMAINS="/data/domains.json"

add_entry() {
    key="$1"
    ip="$2"
    overwrite="$3"

    # Check if the DOMAINS file exists; if not, create an empty JSON array
    if [ ! -f "$DOMAINS" ]; then
        echo "[]" >"$DOMAINS"
    fi

    # Try to find the entry in the JSON file with the specified key
    entry=$(jq -e ".[] | select(.key == \"$key\")" "$DOMAINS")

    # If the key exists and the -o flag is not set, abort the operation
    # to avoid unintentional overwrites
    if [ -n "$entry" ] && [ "$overwrite" = false ]; then
        echo "Error: Key already exists in the JSON file. Use -o flag to overwrite."
        return 1
    fi

    # Attempt to register/update the key with the IP
    if response=$(curl -s -d "key=$key" -d "ip=$ip" https://ipv4.myaddr.tools/update); then
        if [ "$response" == "OK" ]; then
            # fetch information associated with the key
            if info=$(curl -s -w "%{http_code}" -o resp.json https://myaddr.tools/reg?key=$key); then
                if [ "$info" -eq 200 ]; then
                    name=$(jq -r '.name' resp.json)
                    timestamp=$(jq '.updated' resp.json)
                else
                    echo "Error: Received HTTP status $info"
                    return 1
                fi
            else
                echo "Error: Curl command failed to execute."
                return 1
            fi

            if [ -z "$entry" ]; then
                jq --arg key "$key" --arg ip "$ip" --arg name "$name" --argjson ts "$timestamp" \
                    '. += [{"key": $key, "ip": $ip, "name": $name, "timestamp": $ts}]' "$DOMAINS" >tmp.$$.json && mv tmp.$$.json "$DOMAINS"
                echo "Success: Entry added."
            else
                jq "map(if .key == \"$key\" then .ip = \"$ip\" | .name = \"$name\" | .timestamp = $timestamp else . end)" "$DOMAINS" >tmp.$$.json && mv tmp.$$.json "$DOMAINS"
                echo "Success: Entry updated."
            fi
            return 0
        fi
        echo "Error: Received unexpected response from the server: '$response'."
        return 1
    fi
    echo "Error: Curl command failed to execute."
    return 1
}

# Check if the number of arguments is within the expected range
if [ $# -lt 4 ] || [ $# -gt 5 ]; then
    echo "Usage: $0 -k <key> -i <ip> [-o]"
    exit 1
fi

overwrite=false

while getopts ":k:i:o" opt; do
    case ${opt} in
    k)
        key=$OPTARG
        ;;
    i)
        ip=$OPTARG
        ;;
    o)
        overwrite=true
        ;;
    \?)
        echo "Usage: $0 -k <key> -i <ip> [-o]"
        exit 1
        ;;
    esac
done

# Check for any unexpected arguments after processing options
shift $((OPTIND - 1))
if [ $# -ne 0 ]; then
    echo "Usage: $0 -k <key> -i <ip> [-o]"
    exit 1
fi

# Validate that both key and IP parameters were provided
if [ -z "$key" ] || [ -z "$ip" ]; then
    echo "Usage: $0 -k <key> -i <ip> [-o]"
    exit 1
fi

add_entry "$key" "$ip" "$overwrite"
