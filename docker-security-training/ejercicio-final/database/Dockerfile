# =============================================================================
# DATABASE DOCKERFILE - POSTGRESQL SECURE
# =============================================================================
# Security Features:
# - Pinned base image version (no :latest)
# - Alpine-based image for minimal attack surface
# - Custom initialization scripts
# - Proper metadata labels
# - Health check included
#
# Note: PostgreSQL runs as 'postgres' user by default (UID 70 in Alpine)
# This is a non-root user, which satisfies security requirements
# =============================================================================

FROM postgres:16.1-alpine3.19

# Metadata labels following OCI Image Spec
LABEL org.opencontainers.image.title="Secure PostgreSQL" \
      org.opencontainers.image.description="Production PostgreSQL database with security hardening" \
      org.opencontainers.image.version="16.1" \
      org.opencontainers.image.vendor="Docker Security Training" \
      org.opencontainers.image.authors="security-training@example.com" \
      org.opencontainers.image.licenses="PostgreSQL" \
      org.opencontainers.image.source="https://github.com/example/docker-security-training" \
      security.non-root="true"

# Install security updates
RUN apk update && \
    apk upgrade && \
    rm -rf /var/cache/apk/*

# Copy initialization scripts
# These run in alphabetical order when container is first created
COPY init/ /docker-entrypoint-initdb.d/

# Set proper permissions for init scripts
RUN chmod 755 /docker-entrypoint-initdb.d/*.sql 2>/dev/null || true && \
    chmod 755 /docker-entrypoint-initdb.d/*.sh 2>/dev/null || true

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres} || exit 1

# PostgreSQL already runs as non-root user 'postgres'
# Default port
EXPOSE 5432

# Default command (inherited from base image)
CMD ["postgres"]
