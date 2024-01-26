#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Ports
PORT_HTTP=80
PORT_HTTPS=443

# Paths
ENV_FILE="$SCRIPT_DIR/../.env"
HTTP_CONF="$SCRIPT_DIR/../Conf/http_blocks.conf"
STREAM_CONF="$SCRIPT_DIR/../Conf/stream_blocks.conf"
STREAM_MAP_CONF="$SCRIPT_DIR/../Conf/stream_map_blocks.conf"
NGINX_FINAL_CONF="$SCRIPT_DIR/../Conf/nginx.conf"

# Create files for HTTP and Stream configurations
echo "" > $HTTP_CONF
echo "" > $STREAM_CONF
echo "" > $STREAM_MAP_CONF

# Function to generate HTTP server blocks
generate_http_server_block() {
    local domain=$1
    local service=$2

    # HTTP server block
    echo "server {"                                                              >> $HTTP_CONF
    echo "    listen $PORT_HTTP;"                                                >> $HTTP_CONF
    echo "    server_name $domain;"                                              >> $HTTP_CONF
    echo "    location / {"                                                      >> $HTTP_CONF
    echo "        proxy_pass http://$service;"                                   >> $HTTP_CONF
    echo "        proxy_set_header Host \$host;"                                 >> $HTTP_CONF
    echo "        proxy_set_header X-Real-IP \$remote_addr;"                     >> $HTTP_CONF
    echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> $HTTP_CONF
    echo "        proxy_set_header X-Forwarded-Proto \$scheme;"                  >> $HTTP_CONF
    echo "    }"                                                                 >> $HTTP_CONF
    echo "}"                                                                     >> $HTTP_CONF
}

# Function to generate Stream server blocks
generate_stream_server_block() {
    local domain=$1
    local service=$2

    # Stream server block
    echo "server {"                 >> $STREAM_CONF
    echo "    listen $PORT_HTTPS;"  >> $STREAM_CONF
    echo "    server_name $domain;" >> $STREAM_CONF
    echo "    proxy_pass $service;" >> $STREAM_CONF
    echo "    ssl_preread on;"      >> $STREAM_CONF
    echo "}"                        >> $STREAM_CONF
}

# Generate the NGINX configuration
echo "events {}" > $NGINX_FINAL_CONF
echo "http {"    >> $NGINX_FINAL_CONF

# Read from .env file and generate server blocks for HTTP
while IFS='=' read -r domain service || [[ -n "$domain" ]]; do
    # Remove carriage return if present
    service=$(echo "$service" | tr -d '\r')
    if [[ ! -z "$domain" && ! -z "$service" ]]; then
        generate_http_server_block $domain $service
    fi
done < "$ENV_FILE"

# Append the HTTP server blocks to the NGINX configuration
cat $HTTP_CONF >> $NGINX_FINAL_CONF

# Close the HTTP section and start the Stream section
echo "}"                                          >> $NGINX_FINAL_CONF
echo "stream {"                                   >> $NGINX_FINAL_CONF
echo "    resolver 127.0.0.11 valid=30s;"         >> $NGINX_FINAL_CONF
echo "    map \$ssl_preread_server_name \$name {" >> $NGINX_FINAL_CONF

# Read from .env file and populate the Stream map
while IFS='=' read -r domain service || [[ -n "$domain" ]]; do
    # Remove carriage return if present
    service=$(echo "$service" | tr -d '\r')
    if [[ ! -z "$domain" && ! -z "$service" ]]; then
        echo "        $domain $service:443;" >> $NGINX_FINAL_CONF
    fi
done < "$ENV_FILE"

# Close the Stream map section and define the Stream server
echo "    }"                      >> $NGINX_FINAL_CONF
echo ""                           >> $NGINX_FINAL_CONF
echo "    server {"               >> $NGINX_FINAL_CONF
echo "        listen 443;"        >> $NGINX_FINAL_CONF
echo "        ssl_preread on;"    >> $NGINX_FINAL_CONF
echo "        proxy_pass \$name;" >> $NGINX_FINAL_CONF
echo "    }"                      >> $NGINX_FINAL_CONF
echo "}"                          >> $NGINX_FINAL_CONF

# Clean up the temporary configuration files
rm $HTTP_CONF
rm $STREAM_CONF
rm $STREAM_MAP_CONF