KUBECONFIG=$KUBECONFIG_PATH

echo "Setting up CSI driver..."

kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=$HETZNER_TOKEN
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.5.3/deploy/kubernetes/hcloud-csi.yml

echo
