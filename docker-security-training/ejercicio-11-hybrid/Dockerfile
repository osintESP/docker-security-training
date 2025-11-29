FROM nginx:latest

# Copy certificates (Standard ECDSA)
COPY certs/server.crt /etc/nginx/ssl/server.crt
COPY certs/server.key /etc/nginx/ssl/server.key

# Copy configuration
COPY config/nginx.conf /etc/nginx/conf.d/default.conf

# Copy HTML
COPY html/index.html /usr/share/nginx/html/index.html
