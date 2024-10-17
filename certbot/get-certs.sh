#!/bin/sh

DOMAINS="/data/domains.json"
DIR="/etc/letsencrypt/live"

# Check if the number of arguments is within the expected range
if [ $# -ne 2 ]; then
    echo "Usage: $0 -k <key>"
    exit 1
fi

while getopts ":k:" opt; do
    case ${opt} in
    k)
        key=$OPTARG
        ;;
    \?)
        echo "Usage: $0 -k <key>"
        exit 1
        ;;
    esac
done

if [ ! -f "$DOMAINS" ]; then
    echo "Error: File '$DOMAINS' doesn't exist."
    exit 1
fi

# Try to find the entry in the JSON file with the specified key
entry=$(jq -e ".[] | select(.key == \"$key\")" "$DOMAINS")

if [ -n "$entry" ]; then
    # Extract the domain name from the current entry
    name=$(echo "$entry" | jq -r '.name')
else
    echo "Error: Key not found in the JSON file."
    exit 1
fi

AUTHHOOK="wget -q -O - \"https://myaddr.tools/update?key=$key&acme_challenge=\$CERTBOT_VALIDATION\""

certbot certonly \
    --manual \
    --manual-auth-hook "$AUTHHOOK" \
    --preferred-challenges dns \
    --keep-until-expiring \
    -d "$name.myaddr.tools" -d "$name.myaddr.dev" -d "$name.myaddr.io"

ln -s "$(find $DIR -type d -name "$name.myaddr*" | head -n 1)" "$DIR/$name.myaddr"