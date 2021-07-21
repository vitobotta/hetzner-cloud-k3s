FIRST_MASTER_PUBLIC_IP=$(public_ip $MASTER_INSTANCE_TYPE master1)
FIRST_MASTER_PRIVATE_IP=$(ssh $SSH_USER@$FIRST_MASTER_PUBLIC_IP "hostname -I" | awk '{print $2}')
TLS_SANS=" --tls-san=$FIRST_MASTER_PRIVATE_IP "

if [ "$HA" == "true" ]; then
  API_SERVER_IP=$(public_ip_load_balancer)

  COUNTER=1
  while [  $COUNTER -lt $MASTER_COUNT ]; do
    let COUNTER=COUNTER+1

    MASTER_IP=$(private_ip $MASTER_INSTANCE_TYPE master$COUNTER)

    TLS_SANS=" $TLS_SANS --tls-san=$MASTER_IP "
  done

else
  API_SERVER_IP=$FIRST_MASTER_PUBLIC_IP
fi


TLS_SANS=" $TLS_SANS --tls-san=$API_SERVER_IP "

cat << EOF > /tmp/master.sh
  FLANNEL_INTERFACE="$FLANNEL_INTERFACE"
  CLUSTER_CIDR="$CLUSTER_CIDR"
  K3S_TOKEN="$K3S_TOKEN"
  K3S_VERSION="$K3S_VERSION"
  API_SERVER_IP=$API_SERVER_IP
  FIRST_MASTER_PRIVATE_IP=$FIRST_MASTER_PRIVATE_IP
  TLS_SANS="$TLS_SANS"
EOF

cat << 'EOF' >> /tmp/master.sh
  curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION K3S_TOKEN=$K3S_TOKEN INSTALL_K3S_EXEC="server \
    --disable-cloud-controller \
    --disable servicelb \
    --disable traefik \
    --disable local-storage \
    --cluster-init \
    --write-kubeconfig-mode=644 \
    --node-name="$(hostname -f)" \
    --cluster-cidr=$CLUSTER_CIDR \
    --node-taint CriticalAddonsOnly=true:NoExecute \
    --kubelet-arg="cloud-provider=external" \
    --node-ip=$(hostname -I | awk '{print $2}') \
    --node-external-ip=$(hostname -I | awk '{print $1}') \
    --flannel-iface=$FLANNEL_INTERFACE \
EOF

cat << EOF >> /tmp/master.sh
    $TLS_SANS" sh -
EOF

echo
echo "Setting up Kubernetes (k3s) on master1..."

scp /tmp/master.sh $SSH_USER@$FIRST_MASTER_PUBLIC_IP:/tmp/master.sh > /dev/null 2>&1
ssh $SSH_USER@$FIRST_MASTER_PUBLIC_IP /bin/bash /tmp/master.sh

echo "...first master up and running."

ssh $SSH_USER@$FIRST_MASTER_PUBLIC_IP "cat /etc/rancher/k3s/k3s.yaml" | sed "s/default/$CLUSTER_NAME/g" | sed "s/127.0.0.1/$API_SERVER_IP/g" > $KUBECONFIG_PATH


if [ "$HA" == "true" ]; then
  COUNTER=1
  while [  $COUNTER -lt $MASTER_COUNT ]; do
    let COUNTER=COUNTER+1

    MASTER_IP=$(public_ip $MASTER_INSTANCE_TYPE master$COUNTER)

    cat << EOF > /tmp/master.sh
    FLANNEL_INTERFACE="$FLANNEL_INTERFACE"
    CLUSTER_CIDR="$CLUSTER_CIDR"
    K3S_TOKEN="$K3S_TOKEN"
    K3S_VERSION="$K3S_VERSION"
    FIRST_MASTER_PRIVATE_IP="$FIRST_MASTER_PRIVATE_IP"
EOF

    cat << 'EOF' >> /tmp/master.sh
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$K3S_VERSION K3S_TOKEN=$K3S_TOKEN INSTALL_K3S_EXEC="server \
      --disable-cloud-controller \
      --disable servicelb \
      --disable traefik \
      --disable local-storage \
      --server https://$FIRST_MASTER_PRIVATE_IP:6443 \
      --write-kubeconfig-mode=644 \
      --node-name="$(hostname -f)" \
      --cluster-cidr=$CLUSTER_CIDR \
      --node-taint CriticalAddonsOnly=true:NoExecute \
      --kubelet-arg="cloud-provider=external" \
      --node-ip=$(hostname -I | awk '{print $2}') \
      --node-external-ip=$(hostname -I | awk '{print $1}') \
      --flannel-iface=$FLANNEL_INTERFACE \
EOF

    cat << EOF >> /tmp/master.sh
    $TLS_SANS" sh -
EOF

    echo
    echo "Setting up Kubernetes (k3s) on master $COUNTER..."

    scp /tmp/master.sh $SSH_USER@$MASTER_IP:/tmp/master.sh > /dev/null 2>&1
    ssh $SSH_USER@$MASTER_IP "/bin/bash /tmp/master.sh" &
  done
fi

wait

COUNTER=0
while [  $COUNTER -lt $WORKER_COUNT ]; do
  let COUNTER=COUNTER+1

  WORKER_IP=$(public_ip $WORKER_INSTANCE_TYPE worker$COUNTER)

  cat << EOF > /tmp/worker.sh
  MASTER_PRIVATE_IP="$FIRST_MASTER_PRIVATE_IP"
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
