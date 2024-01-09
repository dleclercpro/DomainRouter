#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Paths relative to the script location
ENV_FILE="$SCRIPT_DIR/../.env"
TEMPLATE_CONF="$SCRIPT_DIR/../Conf/nginx.template.conf"
FINAL_CONF="$SCRIPT_DIR/../nginx.conf"

# Start with an empty configuration file
echo "" > $FINAL_CONF

# Function to generate server block from template
generate_server_block() {
    local domain=$1
    local port=$2
    local temp=$(mktemp)

    # Print out some info
    echo "Generating server block for: $domain:$port"

    # Replace placeholders in template
    sed "s/{{SUB_DOMAIN}}/$domain/g; s/{{PORT}}/$port/g" $TEMPLATE_CONF > $temp

    # Append to final configuration file
    cat $temp >> $FINAL_CONF

    # Clean up
    rm $temp
}

# Read from .env file and generate server blocks
while IFS='=' read -r domain port || [[ -n "$domain" ]]; do
    if [[ ! -z "$domain" && ! -z "$port" ]]; then
        generate_server_block $domain $port
    fi
done < "$ENV_FILE"

echo "Final NGINX configuration generated at: $FINAL_CONF"