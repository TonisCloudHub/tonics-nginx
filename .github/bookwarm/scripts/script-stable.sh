#!/bin/bash

# Init incus
sudo incus admin init --auto

# Launch Instance
sudo incus launch images:debian/bookworm/amd64 tonics-nginx

# Nginx Dependencies
sudo incus exec tonics-nginx -- apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring

# Sign Repo
sudo incus exec tonics-nginx -- bash -c "curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null"
sudo incus exec tonics-nginx -- bash -c "gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg"
sudo incus exec tonics-nginx -- bash -c "echo 'deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian bookworm nginx' | tee /etc/apt/sources.list.d/nginx.list | tee /etc/apt/sources.list.d/nginx.list"
sudo incus exec tonics-nginx -- bash -c "echo -e 'Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n' | tee /etc/apt/preferences.d/99nginx"

# Install Nginx
sudo incus exec tonics-nginx -- bash -c "apt-get update -y && apt install -y nginx"

# Start Nginx
sudo incus exec tonics-nginx -- bash -c "sudo nginx"

# Clean Debian Cache
sudo incus exec tonics-nginx -- bash -c "apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"

# Nginx Version
NginxVersion=$(sudo incus exec tonics-nginx -- nginx -v |& sed 's/nginx version: nginx\///')

# Publish Image
mkdir images && sudo incus stop tonics-nginx && sudo incus publish tonics-nginx --alias tonics-nginx

# Export Image
sudo incus start tonics-nginx
sudo incus image export tonics-nginx images/nginx-bookworm-$NginxVersion

# Image Info
sudo incus image info tonics-nginx >> images/info.txt && ls -la images
