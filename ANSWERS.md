# Part 5 – Migrating Ingress-nginx to Gateway API

For migrating approximately 40 Ingress resources from the end-of-life ingress-nginx controller to Gateway API, I would follow a phased migration approach to avoid downtime.

## 1. Assessment and Preparation

First, inventory all 40 Ingress resources and identify their hosts, paths, TLS configurations, annotations, rewrite rules and backend services. Classify simple routing rules separately from complex configurations that depend on controller-specific annotations.

Install a Gateway API-compatible controller and verify that it supports the required Gateway API resources and features.

## 2. Gateway API Configuration

Create the required GatewayClass, Gateway and HTTPRoute resources. Configure listeners, TLS certificates, hostnames and backend service references.

Convert each existing Ingress rule into the corresponding HTTPRoute configuration. Validate path matching, routing behaviour and security requirements.

## 3. Parallel Deployment and Testing

Keep the existing ingress-nginx controller operational while deploying the new Gateway configuration in parallel.

Test the new routes using temporary host mappings or controlled traffic. Verify HTTP responses, TLS, redirects, headers, health checks and backend connectivity.

## 4. Gradual Traffic Migration

Migrate applications in small batches rather than switching all 40 resources simultaneously.

Monitor error rates, latency, availability and application logs after each batch. Keep the original Ingress resources available for rollback until the new routes are stable.

## 5. Risks and Rollback

Important risks include unsupported annotations, differences in path matching, TLS configuration errors, controller compatibility and DNS or traffic-switching issues.

If problems occur, redirect traffic to the existing ingress-nginx configuration and investigate the Gateway implementation before continuing.

## Conclusion

A phased migration with parallel deployment, validation, monitoring and rollback planning provides a safer path to Gateway API while minimizing downtime and operational risk.