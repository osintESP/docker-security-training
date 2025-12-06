# =============================================================================
# API DOCKERFILE - SECURE MULTI-STAGE BUILD
# =============================================================================
# Security Features:
# - Multi-stage build to minimize final image size
# - Pinned base image versions (no :latest)
# - Non-root user execution
# - Alpine-based image for minimal attack surface
# - Health check included
# - Proper metadata labels
# - No dev dependencies in production
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build Stage (Install dependencies)
# -----------------------------------------------------------------------------
FROM node:20.10.0-alpine3.19 AS builder

# Metadata labels
LABEL org.opencontainers.image.title="Secure API Builder" \
      org.opencontainers.image.description="Build stage for Node.js API"

# Set working directory
WORKDIR /app

# Copy package files first (leverage Docker cache)
COPY package*.json ./

# Install ALL dependencies (including dev for potential build steps)
RUN npm install --silent && \
    npm cache clean --force

# Copy source code
COPY src/ ./src/

# -----------------------------------------------------------------------------
# Stage 2: Production Stage
# -----------------------------------------------------------------------------
FROM node:20.10.0-alpine3.19 AS production

# Metadata labels following OCI Image Spec
LABEL org.opencontainers.image.title="Secure API" \
      org.opencontainers.image.description="Production Node.js REST API" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="Docker Security Training" \
      org.opencontainers.image.authors="security-training@example.com" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/example/docker-security-training" \
      security.non-root="true" \
      security.read-only-root="true"

# Install security updates and required packages
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        dumb-init \
        curl && \
    rm -rf /var/cache/apk/*

# Create non-root user and group
RUN addgroup -g 1001 -S nodejs && \
    adduser -u 1001 -S nodeuser -G nodejs

# Set working directory
WORKDIR /app

# Copy package files
COPY --from=builder /app/package*.json ./

# Install ONLY production dependencies
RUN npm install --omit=dev --silent && \
    npm cache clean --force && \
    # Remove unnecessary files to reduce image size
    rm -rf /root/.npm /tmp/*

# Copy application code from builder
COPY --from=builder --chown=nodeuser:nodejs /app/src ./src

# Set environment variables
ENV NODE_ENV=production \
    PORT=3001

# Change ownership of the app directory
RUN chown -R nodeuser:nodejs /app

# Switch to non-root user
USER nodeuser

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "src/server.js"]
