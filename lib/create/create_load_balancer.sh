if hcloud load-balancer list | grep -q $CLUSTER_NAME; then
  echo "API server load balancer already exists, skipping."
else
  echo "Creating API server load balancer..."

  hcloud load-balancer create \
    --name $CLUSTER_NAME \
    --location $LOCATION \
    --type lb11

  hcloud load-balancer add-service $CLUSTER_NAME \
    --protocol tcp \
    --listen-port 6443 \
    --destination-port 6443

  hcloud load-balancer attach-to-network $CLUSTER_NAME \
    --network $CLUSTER_NAME \

  hcloud load-balancer add-target $CLUSTER_NAME \
    --label-selector cluster=$CLUSTER_NAME \
    --label-selector role=master \
    --use-private-ip
fi
