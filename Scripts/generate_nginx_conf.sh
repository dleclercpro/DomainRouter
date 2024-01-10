#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Paths relative to the script location
ENV_FILE="$SCRIPT_DIR/../.env"
STREAM_PLACEHOLDER="$SCRIPT_DIR/stream_blocks_placeholder"
STREAM_TEMPLATE_CONF="$SCRIPT_DIR/../Conf/nginx.stream.template.conf"
NGINX_FINAL_CONF="$SCRIPT_DIR/../Conf/nginx.conf"



# Create an empty placeholder file for Stream blocks
echo "" > $STREAM_PLACEHOLDER

# Start with a basic NGINX configuration
# Set up a global HTTP to HTTPS redirection
echo "events {}"                                        > $NGINX_FINAL_CONF
echo "http {"                                          >> $NGINX_FINAL_CONF
echo "    include /etc/nginx/mime.types;"              >> $NGINX_FINAL_CONF
echo "    server {"                                    >> $NGINX_FINAL_CONF
echo "        listen 80 default_server;"               >> $NGINX_FINAL_CONF
echo "        server_name _;"                          >> $NGINX_FINAL_CONF
echo "        return 301 https://\$host\$request_uri;" >> $NGINX_FINAL_CONF
echo "    }"                                           >> $NGINX_FINAL_CONF
echo "}"                                               >> $NGINX_FINAL_CONF
echo "stream {"                                        >> $NGINX_FINAL_CONF
echo "#PLACEHOLDER_STREAM"                             >> $NGINX_FINAL_CONF
echo "    server {"                                    >> $NGINX_FINAL_CONF
echo "        listen 443;"                             >> $NGINX_FINAL_CONF
echo "        ssl_preread on;"                         >> $NGINX_FINAL_CONF
echo "        proxy_pass \$ssl_preread_server_name;"   >> $NGINX_FINAL_CONF
echo "    }"                                           >> $NGINX_FINAL_CONF
echo "}"                                               >> $NGINX_FINAL_CONF



# Function to replace a placeholder in a file with the contents of another file
replace_placeholder_with_file_content() {
    local placeholder=$1
    local content_file=$2
    local target_file=$3

    # Prepare the contents of the file for insertion
    # Escape backslashes, forward slashes, and & characters
    local content=$(awk '{gsub(/\\/,"\\\\"); gsub(/\//,"\\/"); gsub(/&/,"\\&"); printf("%s\\n", $0)}' "$content_file")

    # Use sed to replace the placeholder with the prepared content
    if [[ "$(uname)" == "Darwin" ]]; then
        # MacOS (BSD sed)
        sed -i '' "s/$placeholder/$content/" "$target_file"
    else
        # Linux (GNU sed)
        sed -i "s/$placeholder/$content/" "$target_file"
    fi
}

# Function to generate upstream block for the Stream context
generate_stream_upstream_block() {
    local domain=$1
    local port=$2
    local temp=$(mktemp)

    # Replace placeholders in template
    sed "s/{{SUB_DOMAIN}}/$domain/g; s/{{PORT}}/$port/g" $STREAM_TEMPLATE_CONF > $temp

    # Append to the Stream placeholder file
    cat $temp >> $STREAM_PLACEHOLDER

    # Clean up
    rm $temp
}



# Read from .env file and generate upstream blocks
while IFS='=' read -r domain port || [[ -n "$domain" ]]; do
    if [[ ! -z "$domain" && ! -z "$port" ]]; then
        generate_stream_upstream_block $domain $port
    fi
done < "$ENV_FILE"

# Replace the stream placeholder with the contents of the Stream placeholder
replace_placeholder_with_file_content '#PLACEHOLDER_STREAM' $STREAM_PLACEHOLDER $NGINX_FINAL_CONF

# Clean up the placeholder file
rm $STREAM_PLACEHOLDER