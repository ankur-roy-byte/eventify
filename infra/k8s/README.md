# Kubernetes Starter Manifests

This folder contains optional Kubernetes-ready assets to demonstrate platform deployability beyond local compose.

Included manifests:
- `namespace.yaml`
- `platform-config.yaml`
- `orders-api-deployment.yaml`
- `notifications-worker-deployment.yaml`
- `kustomization.yaml`

Apply starter manifests:

```bash
kubectl apply -k infra/k8s
```

Notes:
- Kafka, Schema Registry, and Connect are expected to be provided by your Kubernetes platform stack (for example via Strimzi + companion components) and wired through `platform-config.yaml`.
- Secrets are referenced but not committed; create `orders-db-secret` before deploying `orders-api`.
