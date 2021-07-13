KUBECONFIG=$KUBECONFIG_PATH

echo "Setting up System Upgrade Controller driver..."

kubectl apply -f https://raw.githubusercontent.com/rancher/system-upgrade-controller/master/manifests/system-upgrade-controller.yaml

echo
