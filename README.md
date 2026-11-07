# Enterprise Bot – DevOps Take-Home

## 1. Overview

This project demonstrates containerization and deployment of a Python HTTP application using Docker, Kubernetes (Kind), and Helm.

The application exposes a root endpoint and a health-check endpoint.

## 2. Project Structure

- `setup.sh` – Automated cluster setup and deployment.
- `service/` – Python application and Docker configuration.
- `chart/` – Helm deployment chart.
- `lab/` – Part 4 Kubernetes troubleshooting exercise.
- `ANSWERS.md` – Kubernetes migration architecture response.

## 3. Prerequisites

- Docker
- kubectl
- Kind
- Helm
- Git

## 4. Deployment Instructions

Run from the repository root:

```bash
chmod +x setup.sh
./setup.sh
```

The setup script creates or reuses the Kind cluster named `demo`, installs ingress-nginx, builds the application image, loads it into Kind, and deploys the application using Helm.

## 5. Verification

Check cluster and application resources:

```bash
kubectl get nodes
kubectl get pods -n demo
kubectl get svc -n demo
kubectl get ingress -n demo
```

Test the application through Ingress:

```bash
curl -H "Host: demo.local" http://localhost/
```

Test the health endpoint:

```bash
kubectl port-forward svc/demo 8080:80 -n demo
curl http://localhost:8080/healthz
```

## 6. Configuration

The Helm chart exposes configurable values for:

- Replica count
- Image repository, tag and pull policy
- Service type and ports
- Application name and version
- Ingress hostname and class
- CPU and memory requests and limits

Example:

```bash
helm upgrade --install demo ./chart \
  --namespace demo --create-namespace \
  --set replicaCount=3 \
  --set config.appName=custom-app \
  --set config.version=2.0.0
```

## 7. Resource Allocation

The deployment uses two replicas to provide basic availability.

Initial resource allocation:

- CPU request: 100m
- Memory request: 128Mi
- CPU limit: 500m
- Memory limit: 256Mi

These values are suitable starting points for a small demonstration workload and should be adjusted using actual resource monitoring.

## 8. Limitations and Production Improvements

This project uses a local Kind environment and is intended for demonstration rather than production.

Potential production improvements include:

- CI/CD automation and container image vulnerability scanning.
- External secrets management.
- Centralized logging and monitoring.
- Horizontal Pod Autoscaling.
- Pod Disruption Budgets.
- Network policies and stricter security controls.
- TLS certificates and production ingress configuration.
- Backup and disaster recovery procedures.

## 9. Part 4 – Debugging Status

The debugging exercise currently has nine passing checks and two failing reporter-related checks:

- Reporter deployment readiness.
- Reporter `/report` endpoint pod count.

The remaining checks pass. The unresolved issue is disclosed rather than represented as fixed.

## 10. AI Use Disclosure

ChatGPT was used for troubleshooting assistance, command guidance, configuration review, and documentation drafting. Suggested changes were tested during the exercise. The reporter issue remains unresolved and is disclosed honestly.