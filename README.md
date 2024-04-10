### Development

```bash
# Generate code, manifests
make generate

# Generate infrastructure-components.yaml in ./out/
make release-manifests-dev

# Run tests
make test
```

### Deploy

```bash
# Generate code, manifests
make generate

# Build and push image (DockerHub)
make docker-build REGISTRY=docker.io/neoaggelos
make docker-push REGISTRY=docker.io/neoaggelos

# Build and push image (private registry)
make docker-build REGISTRY=10.0.0.1:5060
make docker-push REGISTRY=10.0.0.1:5060

# Generate infrastructure-components in ./out
make release-manifests-dev

# Apply components on cluster
kubectl apply -f ./out/infrastructure-components-in-memory-development.yaml
```
