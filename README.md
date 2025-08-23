# CockroachDB Dynamic HAProxy

[![CI Build and Test](https://github.com/timveil-cockroach/dynamic-haproxy/actions/workflows/ci.yml/badge.svg)](https://github.com/timveil-cockroach/dynamic-haproxy/actions/workflows/ci.yml)
[![Release Docker Image](https://github.com/timveil-cockroach/dynamic-haproxy/actions/workflows/release.yml/badge.svg)](https://github.com/timveil-cockroach/dynamic-haproxy/actions/workflows/release.yml)
[![Docker Hub](https://img.shields.io/docker/pulls/timveil/dynamic-haproxy)](https://hub.docker.com/repository/docker/timveil/dynamic-haproxy)

A production-ready Docker image that provides dynamic HAProxy load balancing for CockroachDB clusters. This image automatically generates HAProxy configuration at runtime based on environment variables, eliminating the need for manual configuration files.

## 🚀 Features

- **Dynamic Configuration**: Automatically generates HAProxy config based on environment variables
- **Health Checks**: Built-in health monitoring for CockroachDB nodes using `/health` endpoints
- **Load Balancing**: Round-robin load balancing across SQL and HTTP traffic
- **Statistics Dashboard**: Built-in HAProxy stats UI for monitoring performance
- **Container-Ready**: Optimized for Docker, Docker Compose, and Kubernetes deployments
- **Security Hardened**: Runs as non-root user with minimal Alpine Linux base
- **Long Connection Support**: 30-minute timeouts for long-running queries

## 🏗️ Architecture

This load balancer sits between your applications and CockroachDB cluster, providing:

```
Applications → HAProxy Load Balancer → CockroachDB Cluster
                     │
                     ├── SQL Traffic (port 26257)
                     ├── HTTP Traffic (port 8080) 
                     └── Stats UI (port 8081)
```

## 📋 Quick Start 

```yaml
services:

  crdb-0:
    hostname: crdb-0
    ...

  crdb-1:
    hostname: crdb-1
    ...

  crdb-2:
    hostname: crdb-2
    ...

  lb:
    container_name: lb
    hostname: lb
    image: timveil/dynamic-haproxy:latest
    ports:
      - "26257:26257" # SQL Port
      - "8080:8080"   # HTTP Port
      - "8081:8081"   # Stats Port
    environment:
      - NODES=crdb-0 crdb-1 crdb-2
    links:
      - crdb-0
      - crdb-1
      - crdb-2
```

### Using with Docker Run

```bash
# Basic usage with required NODES variable
docker run -d --name haproxy-lb \
  -e "NODES=crdb-0 crdb-1 crdb-2" \
  -p 26257:26257 \
  -p 8080:8080 \
  -p 8081:8081 \
  timveil/dynamic-haproxy:latest

# Access HAProxy stats dashboard
curl http://localhost:8081/
```

## ⚙️ Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NODES` | ✅ | - | Space-delimited list of CockroachDB node hostnames |
| `SQL_BIND_PORT` | ❌ | `26257` | HAProxy port for SQL connections |
| `HTTP_BIND_PORT` | ❌ | `8080` | HAProxy port for HTTP connections |
| `STATS_BIND_PORT` | ❌ | `8081` | HAProxy stats UI port |
| `SQL_LISTEN_PORT` | ❌ | `26257` | CockroachDB SQL port |
| `HTTP_LISTEN_PORT` | ❌ | `8080` | CockroachDB HTTP port |
| `HEALTH_CHECK_PORT` | ❌ | `8080` | CockroachDB health check port |

### Configuration Examples

```bash
# Custom ports example
docker run -d \
  -e "NODES=node1 node2 node3" \
  -e "SQL_BIND_PORT=5432" \
  -e "HTTP_BIND_PORT=9090" \
  -e "STATS_BIND_PORT=9091" \
  -p 5432:5432 \
  -p 9090:9090 \
  -p 9091:9091 \
  timveil/dynamic-haproxy:latest

# CockroachDB with non-standard ports
docker run -d \
  -e "NODES=crdb-secure-1 crdb-secure-2" \
  -e "SQL_LISTEN_PORT=26258" \
  -e "HTTP_LISTEN_PORT=8081" \
  -e "HEALTH_CHECK_PORT=8081" \
  timveil/dynamic-haproxy:latest
```

## 🎯 Usage Examples

### Local Development with Docker Compose

Complete example for a 3-node CockroachDB cluster:

```yaml
version: '3.8'
services:
  crdb-0:
    hostname: crdb-0
    image: cockroachdb/cockroach:latest
    command: start --insecure --join=crdb-0,crdb-1,crdb-2
    volumes:
      - crdb-0-data:/cockroach/cockroach-data

  crdb-1:
    hostname: crdb-1
    image: cockroachdb/cockroach:latest
    command: start --insecure --join=crdb-0,crdb-1,crdb-2
    volumes:
      - crdb-1-data:/cockroach/cockroach-data

  crdb-2:
    hostname: crdb-2
    image: cockroachdb/cockroach:latest
    command: start --insecure --join=crdb-0,crdb-1,crdb-2
    volumes:
      - crdb-2-data:/cockroach/cockroach-data

  haproxy-lb:
    image: timveil/dynamic-haproxy:latest
    hostname: haproxy-lb
    ports:
      - "26257:26257"  # SQL connections
      - "8080:8080"    # HTTP API
      - "8081:8081"    # HAProxy stats
    environment:
      - NODES=crdb-0 crdb-1 crdb-2
    depends_on:
      - crdb-0
      - crdb-1
      - crdb-2

volumes:
  crdb-0-data:
  crdb-1-data:
  crdb-2-data:
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: haproxy-lb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: haproxy-lb
  template:
    metadata:
      labels:
        app: haproxy-lb
    spec:
      containers:
      - name: haproxy
        image: timveil/dynamic-haproxy:latest
        env:
        - name: NODES
          value: "cockroachdb-0.cockroachdb cockroachdb-1.cockroachdb cockroachdb-2.cockroachdb"
        ports:
        - containerPort: 26257
        - containerPort: 8080
        - containerPort: 8081
---
apiVersion: v1
kind: Service
metadata:
  name: haproxy-lb-service
spec:
  selector:
    app: haproxy-lb
  ports:
  - name: sql
    port: 26257
    targetPort: 26257
  - name: http
    port: 8080
    targetPort: 8080
  - name: stats
    port: 8081
    targetPort: 8081
  type: LoadBalancer
```

### Testing the Load Balancer

```bash
# Test SQL connection through HAProxy
cockroach sql --insecure --host=localhost --port=26257

# Test HTTP API through HAProxy
curl http://localhost:8080/_status/vars

# Monitor HAProxy statistics
curl http://localhost:8081/
# Or open http://localhost:8081/ in your browser
```

## 🔧 Development

### Building the Image

```bash
# Build for current platform
docker build -t timveil/dynamic-haproxy:latest .

# Build multi-platform (requires buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t timveil/dynamic-haproxy:latest .
```

### Testing Locally

```bash
# Start test container with sample nodes
docker run --rm -d --name test-haproxy \
  -e NODES="node1 node2 node3" \
  -p 26257:26257 \
  -p 8080:8080 \
  -p 8081:8081 \
  timveil/dynamic-haproxy:latest

# Check generated configuration
docker exec test-haproxy cat /usr/local/etc/haproxy/haproxy.cfg

# View logs
docker logs test-haproxy

# Cleanup
docker stop test-haproxy
```

### Publishing to Docker Hub

```bash
docker push timveil/dynamic-haproxy:latest
```

## 🏛️ Technical Details

### Generated HAProxy Configuration

The container dynamically generates an HAProxy configuration file at `/usr/local/etc/haproxy/haproxy.cfg` with the following structure:

```haproxy
global
    log stdout format raw local0 info
    maxconn 4096

defaults
    log                 global
    timeout connect     30m
    timeout client      30m
    timeout server      30m
    option              clitcpka
    option              tcplog

listen cockroach-sql
    bind :26257
    mode tcp
    balance roundrobin
    option httpchk GET /health?ready=1
    server crdb-0 crdb-0:26257 check port 8080
    server crdb-1 crdb-1:26257 check port 8080
    server crdb-2 crdb-2:26257 check port 8080

listen cockroach-http
    bind :8080
    mode tcp
    balance roundrobin
    option httpchk GET /health
    server crdb-0 crdb-0:8080 check port 8080
    server crdb-1 crdb-1:8080 check port 8080
    server crdb-2 crdb-2:8080 check port 8080

listen stats
    bind :8081
    mode http
    stats enable
    stats hide-version
    stats realm Haproxy\ Statistics
    stats uri /
```

### Health Check Behavior

- **SQL Backend**: Uses `GET /health?ready=1` to ensure nodes are ready for SQL connections
- **HTTP Backend**: Uses `GET /health` for basic availability checks
- **Check Interval**: HAProxy default (2 seconds)
- **Timeout**: 30 minutes for long-running operations

### Load Balancing Strategy

- **Algorithm**: Round-robin distribution
- **Session Persistence**: None (stateless load balancing)
- **Failover**: Automatic removal of unhealthy nodes
- **Connection Reuse**: TCP keep-alive enabled

## 🚨 Troubleshooting

### Common Issues

#### Container Fails to Start

```bash
# Check if NODES environment variable is set
docker logs <container-name>

# Expected error if NODES is missing:
# The NODES environment variable is required. It is a space delimited list of CockroachDB node hostnames.
```

**Solution**: Ensure `NODES` environment variable is provided:
```bash
docker run -e "NODES=node1 node2 node3" timveil/dynamic-haproxy:latest
```

#### Can't Connect to CockroachDB Through HAProxy

```bash
# Check HAProxy stats to see backend health
curl http://localhost:8081/

# Check HAProxy logs
docker logs <haproxy-container>

# Test direct connection to CockroachDB nodes
curl http://node1:8080/health
```

**Common causes**:
- CockroachDB nodes not accessible from HAProxy container
- Incorrect node hostnames in `NODES` variable
- CockroachDB not responding to health checks
- Network connectivity issues

#### Health Checks Failing

```bash
# Check CockroachDB health endpoints directly
curl http://<node>:8080/health        # Basic health
curl http://<node>:8080/health?ready=1 # Ready for connections
```

**Solutions**:
- Ensure CockroachDB HTTP port is accessible
- Verify `HEALTH_CHECK_PORT` matches CockroachDB's HTTP port
- Check CockroachDB logs for startup issues

### Debug Commands

```bash
# View generated HAProxy configuration
docker exec <container> cat /usr/local/etc/haproxy/haproxy.cfg

# Monitor HAProxy logs in real-time
docker logs -f <container>

# Check HAProxy process status
docker exec <container> ps aux

# Test configuration syntax
docker exec <container> haproxy -f /usr/local/etc/haproxy/haproxy.cfg -c
```

### Performance Tuning

For high-load scenarios, consider adjusting:

```bash
# Increase max connections
docker run -e "NODES=..." \
  --sysctl net.core.somaxconn=4096 \
  timveil/dynamic-haproxy:latest

# Monitor connection statistics
curl http://localhost:8081/ | grep -E "(Curr|Max|Total)"
```

## 🤝 Contributing

### Prerequisites

- Docker and Docker Buildx
- Basic knowledge of HAProxy configuration
- Understanding of CockroachDB architecture

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-improvement
   ```

3. **Make your changes**
   - Modify `docker-entrypoint.sh` for configuration logic
   - Update `Dockerfile` for container improvements
   - Add tests if applicable

4. **Test your changes**
   ```bash
   # Build and test locally
   docker build -t dynamic-haproxy-dev .
   
   # Test with sample configuration
   docker run --rm -e "NODES=test1 test2" dynamic-haproxy-dev
   ```

5. **Submit a Pull Request**

### Code Style

- Use shellcheck for bash script validation
- Follow Docker best practices
- Include clear commit messages
- Update documentation for user-facing changes

### Reporting Issues

When reporting bugs, please include:
- Docker version and platform
- Complete error messages and logs
- Minimal reproduction case
- Environment variable configuration used

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- Built on the excellent [HAProxy](https://www.haproxy.org/) load balancer
- Designed for [CockroachDB](https://www.cockroachlabs.com/) distributed SQL database
- Inspired by the need for simplified container orchestration

---

**Maintainer**: [Tim Veil](mailto:tjveil@gmail.com)  
**Source**: [GitHub Repository](https://github.com/timveil/dynamic-haproxy)  
**Docker Hub**: [timveil/dynamic-haproxy](https://hub.docker.com/r/timveil/dynamic-haproxy)