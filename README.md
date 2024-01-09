# SubDomainRouter

## Description

This repository contains the configuration and setup for a main reverse proxy server, designed to route traffic to multiple containerized applications, each hosted on its own sub-domain. The reverse proxy is managed by NGINX, and each application is set up with SSL termination handled internally.

## Features

- **Centralized Traffic Management**: All inbound traffic is managed by a single NGINX reverse proxy.
- **Sub-Domain Routing**: Each application is accessible via its own sub-domain.
- **SSL Configuration**: SSL termination is handled by each app's internal NGINX setup.
- **Automated Configuration**: A Bash script is used to automatically generate the needed NGINX configuration file based on a given template.