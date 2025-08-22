# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview
This repository contains a Docker image that deploys HAProxy as a load balancer in front of a CockroachDB cluster. It's designed for local development, testing, and demos.

## Key Components

### Architecture
- **docker-entrypoint.sh**: Bash script that dynamically generates HAProxy configuration based on environment variables
- **Dockerfile**: Based on haproxy:2.6, installs the entrypoint script
- **Generated haproxy.cfg**: Created at runtime with CockroachDB node backends for SQL and HTTP traffic

### Configuration Flow
1. Environment variables are read at container startup
2. `docker-entrypoint.sh` builds HAProxy configuration dynamically
3. HAProxy starts with the generated config, load balancing across CockroachDB nodes

## Common Commands

### Build Docker Image
```bash
# Build for local platform
docker build -t timveil/dynamic-haproxy:latest .

# Build multi-platform image
docker buildx build --platform linux/amd64,linux/arm64 -t timveil/dynamic-haproxy:latest .
```

### Run Container
```bash
# Basic run with required NODES environment variable
docker run --env "NODES=crdb-0 crdb-1 crdb-2" -it timveil/dynamic-haproxy:latest

# Run with custom ports
docker run \
    --env "NODES=crdb-0 crdb-1 crdb-2" \
    --env SQL_BIND_PORT=5432 \
    --env HTTP_BIND_PORT=8080 \
    -it timveil/dynamic-haproxy:latest
```

### Test Container Locally
```bash
# Run with test nodes and port mappings
docker run --rm -d --name test-haproxy \
    -e NODES="node1 node2 node3" \
    -p 26257:26257 \
    -p 8080:8080 \
    -p 8081:8081 \
    timveil/dynamic-haproxy:latest

# Check stats page
curl http://localhost:8081/

# Stop test container
docker stop test-haproxy
```

### GitHub Actions

The repository includes automated CI/CD workflows:

- **CI Build and Test**: Runs on all pushes and PRs, builds and tests the image
- **Release**: Automatically versions and publishes to Docker Hub when Dockerfile or entrypoint changes
- **Docker Scout**: Weekly security scanning and recommendations

Required GitHub Secrets:
- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub access token

## Environment Variables
- **NODES** (required): Space-delimited list of CockroachDB node hostnames
- **SQL_BIND_PORT**: HAProxy SQL bind port (default: 26257)
- **HTTP_BIND_PORT**: HAProxy HTTP bind port (default: 8080) 
- **STATS_BIND_PORT**: HAProxy stats UI port (default: 8081)
- **SQL_LISTEN_PORT**: CockroachDB SQL port (default: 26257)
- **HTTP_LISTEN_PORT**: CockroachDB HTTP port (default: 8080)
- **HEALTH_CHECK_PORT**: CockroachDB health check port (default: 8080)

## Key Implementation Details
- HAProxy configuration is generated dynamically in `buildConfig()` function
- Health checks use HTTP GET requests to `/health` and `/health?ready=1` endpoints
- Load balancing uses round-robin strategy
- Connection timeouts set to 30 minutes for long-running queries
- Stats interface available for monitoring HAProxy performance