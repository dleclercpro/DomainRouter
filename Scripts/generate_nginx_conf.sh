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
    echo "        proxy_pass http://$service:$PORT_HTTP;"                        >> $HTTP_CONF
    echo "        proxy_set_header Host \$host;"                                 >> $HTTP_CONF
    echo "        proxy_set_header X-Real-IP \$remote_addr;"                     >> $HTTP_CONF
    echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> $HTTP_CONF
    echo "        proxy_set_header X-Forwarded-Proto \$scheme;"                  >> $HTTP_CONF
    echo "    }"                                                                 >> $HTTP_CONF
    echo "}"                                                                     >> $HTTP_CONF
}

# Function to generate mapping for Stream server block
generate_stream_map_block() {
    local domain=$1
    local service=$2

    echo "$domain $service:$PORT_HTTPS;" >> $STREAM_MAP_CONF
}

# Function to generate Stream server block for HTTPS
generate_stream_server_block() {
    # Stream server block with resolver and map
    echo "resolver 127.0.0.11 valid=30s;"         > $STREAM_CONF
    echo "map \$ssl_preread_server_name \$name {" >> $STREAM_CONF
    cat  $STREAM_MAP_CONF                         >> $STREAM_CONF
    echo "}"                                      >> $STREAM_CONF
    echo ""                                       >> $STREAM_CONF
    echo "server {"                               >> $STREAM_CONF
    echo "    listen $PORT_HTTPS;"                >> $STREAM_CONF
    echo "    ssl_preread on;"                    >> $STREAM_CONF
    echo "    proxy_pass \$name;"                 >> $STREAM_CONF
    echo "}"                                      >> $STREAM_CONF
}

# Read from .env file and generate server blocks
while IFS='=' read -r domain service || [[ -n "$domain" ]]; do
    if [[ ! -z "$domain" && ! -z "$service" ]]; then
        generate_http_server_block $domain $service
        generate_stream_map_block $domain $service
    fi
done < "$ENV_FILE"

# Generate final stream block
generate_stream_server_block

# Start with a basic NGINX configuration with placeholders for HTTP and Stream contexts
echo "events {}" >  $NGINX_FINAL_CONF
echo "http {"    >> $NGINX_FINAL_CONF
cat $HTTP_CONF   >> $NGINX_FINAL_CONF
echo "}"         >> $NGINX_FINAL_CONF
echo "stream {"  >> $NGINX_FINAL_CONF
cat $STREAM_CONF >> $NGINX_FINAL_CONF
echo "}"         >> $NGINX_FINAL_CONF

# Clean up the temporary configuration files
rm $HTTP_CONF
rm $STREAM_CONF
rm $STREAM_MAP_CONF