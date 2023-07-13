#!/bin/bash

# Launch Instance
lxc launch images:debian/bookworm/amd64 tonics-nginx

# Nginx Dependencies
lxc exec tonics-nginx -- apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring

# Sign Repo
lxc exec tonics-nginx -- bash -c "curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null"
lxc exec tonics-nginx -- bash -c "gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg"
lxc exec tonics-nginx -- bash -c "echo 'deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian bookworm nginx' | tee /etc/apt/sources.list.d/nginx.list | tee /etc/apt/sources.list.d/nginx.list"
lxc exec tonics-nginx -- bash -c "echo -e 'Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n' | tee /etc/apt/preferences.d/99nginx"

# Install Nginx
lxc exec tonics-nginx -- bash -c "apt-get update -y && apt install -y nginx"

# Start Nginx
lxc exec tonics-nginx -- bash -c "sudo nginx"

# Clean Debian Cache
lxc exec tonics-nginx -- apt clean

# Nginx Version
NginxVersion=$(lxc exec tonics-nginx -- nginx -v |& sed 's/nginx version: nginx\///')

# Publish Image
mkdir images && lxc stop tonics-nginx && lxc publish tonics-nginx --alias tonics-nginx

# Export Image
lxc start tonics-nginx
lxc image export tonics-nginx images/nginx-$NginxVersion

# Image Info
lxc image info tonics-nginx >> images/info.txt && ls -la images
