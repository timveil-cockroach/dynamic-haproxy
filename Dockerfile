# Use specific version tag for better reproducibility and security
FROM haproxy:2.6-alpine

# Add metadata labels following OCI Image Format Specification
LABEL maintainer="tjveil@gmail.com" \
      org.opencontainers.image.title="Dynamic HAProxy for CockroachDB" \
      org.opencontainers.image.description="HAProxy load balancer with dynamic configuration for CockroachDB clusters" \
      org.opencontainers.image.vendor="Tim Veil" \
      org.opencontainers.image.source="https://github.com/timveil/dynamic-haproxy"

# Switch to root user to install packages
USER root

# Install bash (needed for the entrypoint script) in a single layer
# Use --no-cache to avoid storing package index locally
RUN apk add --no-cache bash

# Copy entrypoint script with proper permissions
COPY --chmod=755 docker-entrypoint.sh /docker-entrypoint.sh

# Create config directory and set permissions for haproxy user
RUN mkdir -p /usr/local/etc/haproxy && \
    chown -R haproxy:haproxy /usr/local/etc/haproxy

# Switch back to haproxy user for runtime security
USER haproxy

# Document exposed ports
EXPOSE 26257 8080 8081

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/ || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
