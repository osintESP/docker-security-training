# Using OpenQuantumSafe nginx with OQS provider for PQC support
FROM openquantumsafe/nginx:latest

# Copy certificates (Standard ECDSA for browser compatibility)
# Note: Ensure server.key has readable permissions before building
COPY certs/server.crt /etc/nginx/ssl/server.crt
COPY certs/server.key /etc/nginx/ssl/server.key

# Copy configuration to the correct path used by openquantumsafe/nginx
# The container runs: nginx -c nginx-conf/nginx.conf
COPY config/nginx.conf /opt/nginx/nginx-conf/nginx.conf

# Copy HTML demonstration page
COPY html/index.html /usr/share/nginx/html/index.html

EXPOSE 4433
