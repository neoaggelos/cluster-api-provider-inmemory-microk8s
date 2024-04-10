#!/bin/bash

# Generate clusters
export CONTROL_PLANE_MACHINE_COUNT=3
export WORKER_MACHINE_COUNT=3

mkdir -p clusters/100-1cp
for ns in $(seq 0 9); do
    for c in $(seq 0 9); do
        namespace="$(printf "ns-%02d" "$ns")"
        cluster_name="$(printf "c-%02d-%03d" "$ns" "$c")"

        clusterctl generate cluster "$cluster_name" --kubernetes-version 1.29.0 --from ./template/tmpl.yaml > clusters/100-1cp/"$cluster_name".yaml
    done
done

# Apply clusters
kubectl apply -f ./clusters/100-1cp -R
