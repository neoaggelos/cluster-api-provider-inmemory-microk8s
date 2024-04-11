```bash
# Install Canonical K8s to server as the control cluster
sudo snap install k8s --revision 220 --classic

# Run single-node etcd (on separate terminal)
wget https://github.com/etcd-io/etcd/releases/download/v3.5.13/etcd-v3.5.13-linux-amd64.tar.gz
tar xvzf etcd-v3.5.13-linux-amd64.tar.gz
./etcd-v3.5.13-linux-amd64/etcd --data-dir /etcd-data

# Bootstrap cluster with defaults
echo '
---
cluster-config:
  network:
    enabled: true
  dns:
    enabled: true
  metrics-server:
    enabled: true
datastore-type: external
datastore-servers: ["http://127.0.0.1:2379"]
' > config.yaml
sudo k8s bootstrap --file config.yaml

# Generate kubeconfig
mkdir -p ~/.kube
sudo k8s config > ~/.kube/config

# Deploy kube-prometheus-stack for observability
# node_address="$(sudo k8s kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')"
# sudo k8s helm upgrade --install \
#     kpm kube-prometheus-stack \
#     --repo https://prometheus-community.github.io/helm-charts \
#     --create-namespace -n kpm \
#     --set kubeControllerManager.endpoints="{${node_address}}" \
#     --set kubeScheduler.endpoints="{${node_address}}" \
#     --set kubeProxy.endpoints="{${node_address}}"

sudo k8s helm upgrade --install \
    kpm kube-prometheus-stack \
    --repo https://prometheus-community.github.io/helm-charts \
    --create-namespace -n kpm \


# Create a port forward to Grafana. Login to http://localhost:3000 with username "admin", password "prom-operator"
sudo k8s kubectl port-forward -n kpm svc/kpm-grafana 3000:80 --address 0.0.0.0

# Install clusterctl v1.6.3 and initialize ClusterAPI
sudo snap install clusterctl --revision 4 --devmode

# Initialize ClusterAPI providers
clusterctl init -i - -b microk8s:v0.6.8 -c microk8s:v0.6.8

# Adjust resource limits for ClusterAPI providers
# adjust limits with: --limits=cpu=1000m,memory=1024Mi
# remove limits with: --limits=cpu=0,memory=0 --requests=cpu=0,memory=0
sudo k8s kubectl set resources -n capi-microk8s-bootstrap-system deploy/capi-microk8s-bootstrap-controller-manager -c manager --limits=cpu=0,memory=0 --requests=cpu=0,memory=0
sudo k8s kubectl set resources -n capi-microk8s-control-plane-system deploy/capi-microk8s-control-plane-controller-manager -c manager --limits=cpu=0,memory=0 --requests=cpu=0,memory=0

# Deploy in-memory-microk8s provider (tag: 20240410-dev1)
sudo k8s kubectl apply -f https://github.com/neoaggelos/cluster-api-provider-inmemory-microk8s/releases/download/20240410-dev1/infrastructure-components-in-memory-development.yaml

# Download cluster-template.yaml
curl -fsSL https://github.com/neoaggelos/cluster-api-provider-inmemory-microk8s/releases/download/20240410-dev1/cluster-template.yaml -o cluster-template.yaml

# Cluster template configuration
export CONTROL_PLANE_MACHINE_COUNT=1
export WORKER_MACHINE_COUNT=0
export KUBERNETES_VERSION=1.29.0

# Generate cluster templates (takes around 30 seconds for 10000 clusters)
mkdir -p clusters
clusterctl generate cluster "c-0000" --from ./cluster-template.yaml > "clusters/c-0000.yaml"
for x in $(seq 1 9999); do
    cluster="$(printf "c-%04d" "$x")"
    cat clusters/c-0000.yaml | sed "s/c-0000/$cluster/g" > "clusters/${cluster}.yaml"
done

# Apply 300 clusters (c-0000 -> c0299)
date   # Thu Apr 11 14:31:27 UTC 2024
find ./clusters -name 'c-0[012]*.yaml' | sort | xargs -n1 sudo k8s kubectl apply -f
date   # Thu Apr 11 14:33:19 UTC 2024

# wait until everything is provisioned:
date   # Thu Apr 11 14:34:32 UTC 2024


# [Track progress] (provisioned clusters, running machines, ready control planes)
while true; do
  sudo k8s kubectl get clusters | grep Provisioned | wc -l
  sudo k8s kubectl get machines  | grep Running | wc -l
  sudo k8s kubectl get microk8scontrolplane | grep 'true    true' | wc -l
  date
done


# Apply 300 more (c-0300 -> c0599)
date   # Thu Apr 11 14:34:55 UTC 2024
find ./clusters -name 'c-0[345]*.yaml' | sort | xargs -n1 sudo k8s kubectl apply -f
date   # Thu Apr 11 14:36:48 UTC 2024

# wait until everything is provisioned:
date   # Thu Apr 11 14:38:28 UTC 2024

# Apply 300 more (c-0600 -> c0899)
date   # Thu Apr 11 14:50:18 UTC 2024
find ./clusters -name 'c-0[678]*.yaml' | sort | xargs -n1 sudo k8s kubectl apply -f
date   # Thu Apr 11 14:52:15 UTC 2024

# wait until everything is provisioned:
date   # Thu Apr 11 14:54:04 UTC 2024


# Apply 100 more (c-0900 -> c0999)
date   # Thu Apr 11 15:00:34 UTC 2024
find ./clusters -name 'c-09*.yaml' | sort | xargs -n1 sudo k8s kubectl apply -f
date   # Thu Apr 11 15:01:18 UTC 2024

# wait until everything is provisioned:
date   # Thu Apr 11 15:02:40 UTC 2024


# Apply 1000 more (c-1000 -> c1999)
date   # Thu Apr 11 15:06:33 UTC 2024
find ./clusters -name 'c-1*.yaml' | sort | xargs -n1 sudo k8s kubectl apply -f
date   # Thu Apr 11 15:12:32 UTC 2024

# wait until everything is provisioned:
date   # Thu Apr 11 15:19:33 UTC 2024
