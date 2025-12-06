# =============================================================================
# FRONTEND DOCKERFILE - SECURE MULTI-STAGE BUILD
# =============================================================================
# Security Features:
# - Multi-stage build to minimize final image size
# - Pinned base image versions (no :latest)
# - Non-root user execution
# - Alpine-based images for minimal attack surface
# - Health check included
# - Proper metadata labels
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build Stage
# -----------------------------------------------------------------------------
FROM node:20.10.0-alpine3.19 AS builder

# Metadata labels following OCI Image Spec
LABEL org.opencontainers.image.title="Secure Frontend Builder" \
      org.opencontainers.image.description="Build stage for React frontend" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="Docker Security Training" \
      org.opencontainers.image.authors="security-training@example.com"

# Set working directory
WORKDIR /app

# Copy package files first (leverage Docker cache)
COPY package*.json ./

# Install dependencies
RUN npm install --silent && \
    npm cache clean --force

# Copy source code
COPY public/ ./public/
COPY src/ ./src/

# Build argument for API URL (can be overridden at build time)
ARG REACT_APP_API_URL=http://localhost:3001
ENV REACT_APP_API_URL=${REACT_APP_API_URL}

# Build the application
RUN npm run build

# -----------------------------------------------------------------------------
# Stage 2: Production Stage
# -----------------------------------------------------------------------------
FROM nginx:1.25.3-alpine3.18 AS production

# Metadata labels
LABEL org.opencontainers.image.title="Secure Frontend" \
      org.opencontainers.image.description="Production React frontend with Nginx" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="Docker Security Training" \
      org.opencontainers.image.authors="security-training@example.com" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/example/docker-security-training" \
      security.non-root="true" \
      security.read-only-root="true"

# Install curl for health checks and remove cache
RUN apk add --no-cache curl && \
    rm -rf /var/cache/apk/*

# Create non-root user for nginx
RUN addgroup -g 1001 -S nginxgroup && \
    adduser -u 1001 -S nginxuser -G nginxgroup

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create required directories and set permissions
RUN mkdir -p /var/cache/nginx /var/log/nginx /var/run && \
    chown -R nginxuser:nginxgroup /var/cache/nginx /var/log/nginx /var/run /usr/share/nginx/html /etc/nginx && \
    chmod -R 755 /var/cache/nginx /var/log/nginx /etc/nginx && \
    chmod 644 /etc/nginx/nginx.conf && \
    touch /var/run/nginx.pid && \
    chown nginxuser:nginxgroup /var/run/nginx.pid

# Copy built assets from builder stage
COPY --from=builder --chown=nginxuser:nginxgroup /app/build /usr/share/nginx/html

# Remove default nginx config
RUN rm -f /etc/nginx/conf.d/default.conf

# Switch to non-root user
USER nginxuser

# Expose port (non-privileged port)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
