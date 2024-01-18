# DomainRouter

## Description

This repository hosts the configuration for a main reverse proxy server. It
routes traffic to multiple containerized applications, each on its own
sub-domain. The reverse proxy, managed by NGINX, handles HTTP and HTTPS traffic.
HTTPS traffic uses SNI (Server Name Indication) for directing to the correct
service without SSL termination at the proxy level.

## Features

- **Centralized Traffic Management**: Manages all inbound HTTP and HTTPS
  traffic through a single NGINX reverse proxy, simplifying network architecture.
- **Sub-Domain Routing**: Access each application via its own sub-domain.
  NGINX reverse proxy uses SNI-based routing for HTTPS to forward requests
  appropriately.
- **Docker Network Integration**: Optimized for Docker, NGINX is configured
  to resolve container names within a Docker network. Allows seamless
  communication between the reverse proxy and containerized applications.
- **SSL Passthrough**: Each application handles its own SSL termination.
  The NGINX reverse proxy forwards HTTPS traffic without decryption, enabling
  end-to-end encryption.
- **Automated Configuration**: Includes a Bash script to automatically generate
  the NGINX configuration file. The script creates HTTP and HTTPS configurations
  dynamically from a `.env` file mapping domain names to containerized services.

## Configuration and Usage

1. **Setting up the `.env` file**: Define domain and service mappings in the
   `.env` file. Each line should contain a domain name and the corresponding
   Docker service name, separated by an equals sign.
2. **Generating the Configuration**: Run the provided Bash script to generate
   the NGINX configuration file. The script creates server blocks for HTTP and
   HTTPS traffic based on `.env` file contents.
3. **Deploying the Reverse Proxy**: After generating the configuration file,
   deploy the NGINX container on the Docker network with your services. Ensure
   NGINX is configured to use Docker's internal DNS for name resolution.

## Note on DNS Resolution

The NGINX setup uses Docker's internal DNS (`127.0.0.11`) for resolving
container names. This is vital for proper reverse proxy operation within the
Docker environment. Maintain this DNS setting for functionality.
