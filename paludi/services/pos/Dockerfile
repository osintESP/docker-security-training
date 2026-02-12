# Stage 1: Builder
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci && \
    npm cache clean --force

# Copy application source
COPY . .

# Build the application with Vite
RUN npm run build

# Stage 2: Production
FROM nginx:1.25-alpine

# Create non-root user
RUN addgroup -g 1001 nginxuser && \
    adduser -D -u 1001 -G nginxuser nginxuser && \
    chown -R nginxuser:nginxuser /var/cache/nginx && \
    chown -R nginxuser:nginxuser /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginxuser:nginxuser /var/run/nginx.pid

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built files from builder
COPY --from=builder --chown=nginxuser:nginxuser /app/dist /usr/share/nginx/html

# Switch to non-root user
USER nginxuser

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3001 || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
