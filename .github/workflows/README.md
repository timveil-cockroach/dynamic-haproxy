# GitHub Actions Workflows

This directory contains GitHub Actions workflows for CI/CD automation.

## Workflows

### CI Build and Test (`ci.yml`)
- **Triggers**: On every push to master/main and pull requests
- **Actions**:
  - Builds multi-platform Docker images (linux/amd64, linux/arm64)
  - Tests container startup and health endpoint
  - Runs Trivy security scanning for vulnerabilities
  - Runs Docker Scout CVE analysis
  - Fails on CRITICAL or HIGH vulnerabilities

### Release Docker Image (`release.yml`)
- **Triggers**: On push to master/main when Dockerfile or docker-entrypoint.sh changes
- **Actions**:
  - Builds and pushes multi-platform images to Docker Hub
  - Creates versioned tags:
    - `latest`
    - `YYYY.MM.DD` (date-based)
    - `YYYY.MM.DD-sha` (date + commit SHA)
  - Generates SBOM and provenance attestations for supply chain security
  - Runs Docker Scout analysis and uploads results
  - Updates Docker Hub repository description

### Docker Scout Analysis (`docker-scout.yml`)
- **Triggers**: Weekly on Mondays at 9am UTC, or manual dispatch
- **Actions**:
  - Compares current image with previous versions
  - Generates security recommendations
  - Creates and stores SBOM artifacts
  - Monitors for new vulnerabilities in existing images

## Required Secrets

Configure these secrets in your GitHub repository settings:

- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub access token (not password)

## Docker Scout Best Practices

The workflows implement several Docker Scout best practices:

1. **Supply Chain Security**: Generates SBOM and provenance attestations
2. **Vulnerability Scanning**: Regular CVE scanning with severity thresholds
3. **SARIF Integration**: Uploads security findings to GitHub Security tab
4. **Continuous Monitoring**: Weekly scans for new vulnerabilities
5. **Multi-platform Support**: Builds for both AMD64 and ARM64 architectures
6. **Layer Caching**: Uses GitHub Actions cache for faster builds

## Local Testing

To test the Docker image locally before pushing:

```bash
# Build the image
docker build -t dynamic-haproxy:test .

# Run with test nodes
docker run --rm -e NODES="node1 node2 node3" dynamic-haproxy:test

# Check health endpoint
curl http://localhost:8081/
```