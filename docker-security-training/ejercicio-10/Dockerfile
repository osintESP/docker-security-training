FROM openquantumsafe/httpd:latest

USER root

# Copy minimal configuration
COPY config/pqc.conf /opt/httpd/conf/pqc.conf
RUN echo "Include /opt/httpd/conf/pqc.conf" >> /opt/httpd/conf/httpd.conf

# Prepare directories & permissions
RUN mkdir -p /opt/httpd/logs /opt/httpd/htdocs && chown -R daemon:daemon /opt/httpd/htdocs /opt/httpd/logs

# Copy artifacts directly into the image so it's self-contained for K8s
COPY html/index.html /opt/httpd/htdocs/index.html
COPY certs/server.crt /opt/httpd/pki/server.crt
COPY certs/server.key /opt/httpd/pki/server.key

# Fix permissions for the certs
RUN chown daemon:daemon /opt/httpd/pki/server.crt /opt/httpd/pki/server.key

USER daemon
