KUBECONFIG=$KUBECONFIG_PATH

echo "Setting up cloud controller manager..."

kubectl -n kube-system create secret generic hcloud --from-literal=token=$HETZNER_TOKEN --from-literal=network=$CLUSTER_NAME
kubectl apply -f  https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/latest/download/ccm-networks.yaml

echo
