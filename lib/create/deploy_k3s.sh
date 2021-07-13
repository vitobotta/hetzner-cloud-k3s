MASTER_PRIVATE_IP=$(ssh $SSH_USER@$MASTER_IP "hostname -I" | awk '{print $2}')

  cat << EOF > /tmp/master.sh
  FLANNEL_INTERFACE="$FLANNEL_INTERFACE"
  CLUSTER_CIDR="$CLUSTER_CIDR"
  K3S_TOKEN="$K3S_TOKEN"
  K3S_VERSION="$K3S_VERSION"
EOF

  cat << 'EOF' >> /tmp/master.sh
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION K3S_TOKEN=$K3S_TOKEN INSTALL_K3S_EXEC="server \
    --disable-cloud-controller \
    --disable servicelb \
    --disable traefik \
    --disable local-storage \
    --write-kubeconfig-mode=644 \
    --node-name="$(hostname -f)" \
    --cluster-cidr=$CLUSTER_CIDR \
    --node-taint CriticalAddonsOnly=true:NoExecute \
    --tls-san=$(hostname -I | awk '{print $1}') \
    --kubelet-arg="cloud-provider=external" \
    --node-ip=$(hostname -I | awk '{print $2}') \
    --node-external-ip=$(hostname -I | awk '{print $1}') \
    --flannel-iface=$FLANNEL_INTERFACE" sh -
EOF

echo
echo "Setting up Kubernetes (k3s) on master..."

scp /tmp/master.sh $SSH_USER@$MASTER_IP:/tmp/master.sh > /dev/null 2>&1
ssh $SSH_USER@$MASTER_IP /bin/bash /tmp/master.sh

echo "...master up and running."

ssh $SSH_USER@$MASTER_IP "cat /etc/rancher/k3s/k3s.yaml" | sed "s/default/$CLUSTER_NAME/g" | sed "s/127.0.0.1/$MASTER_IP/g" > $KUBECONFIG_PATH


COUNTER=0
while [  $COUNTER -lt $WORKER_COUNT ]; do
  let COUNTER=COUNTER+1

  WORKER_IP=$(public_ip $WORKER_INSTANCE_TYPE worker$COUNTER)

  cat << EOF > /tmp/worker.sh
  MASTER_PRIVATE_IP="$MASTER_PRIVATE_IP"
  FLANNEL_INTERFACE="$FLANNEL_INTERFACE"
  CLUSTER_CIDR="$CLUSTER_CIDR"
  K3S_TOKEN="$K3S_TOKEN"
  K3S_VERSION="$K3S_VERSION"
EOF

  cat << 'EOF' >> /tmp/worker.sh
  curl -sfL https://get.k3s.io | K3S_TOKEN=$K3S_TOKEN INSTALL_K3S_VERSION=$K3S_VERSION K3S_URL=https://$MASTER_PRIVATE_IP:6443 INSTALL_K3S_EXEC="agent \
    --node-name="$(hostname -f)" \
    --kubelet-arg="cloud-provider=external" \
    --node-ip=$(hostname -I | awk '{print $2}') \
    --node-external-ip=$(hostname -I | awk '{print $1}') \
    --flannel-iface=$FLANNEL_INTERFACE" sh -
EOF

  echo
  echo "Setting up Kubernetes (k3s) on worker $COUNTER..."

  scp /tmp/worker.sh $SSH_USER@$WORKER_IP:/tmp/worker.sh > /dev/null 2>&1
  ssh $SSH_USER@$WORKER_IP "/bin/bash /tmp/worker.sh" &
done

wait

echo
