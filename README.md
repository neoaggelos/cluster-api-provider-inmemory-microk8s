### Development

```bash
# Generate code, manifests
make generate

# Generate infrastructure-components.yaml in ./out/
make release-manifests-dev

# Build ./bin/capim-manager
make managers

# Build all components except for Deployment (for local development)
./hack/tools/bin/kustomize build ./test/infrastructure/inmemory/config/without-manager

# Run development
go run ./test/infrastructure/inmemory
```
