#!/bin/bash

# Path to the .env file with domains and ports
env_file=".env"

# Path to the NGINX template file
template_conf="nginx.template.conf"

# Output path for the final NGINX configuration
final_conf="nginx.conf"

# Start with an empty configuration file
echo "" > $final_conf

# Function to generate server block from template
generate_server_block() {
    local domain=$1
    local port=$2
    local temp=$(mktemp)

    # Print out some info
    echo "Generating server block for: $domain:$port"

    # Replace placeholders in template
    sed "s/{{SUB_DOMAIN}}/$domain/g; s/{{PORT}}/$port/g" $template_conf > $temp

    # Append to final configuration file
    cat $temp >> $final_conf

    # Clean up
    rm $temp
}

# Read from .env file and generate server blocks
while IFS='=' read -r domain port || [[ -n "$domain" ]]; do
    if [[ ! -z "$domain" && ! -z "$port" ]]; then
        generate_server_block $domain $port
    fi
done < "$env_file"

echo "Final NGINX configuration generated at: $final_conf"