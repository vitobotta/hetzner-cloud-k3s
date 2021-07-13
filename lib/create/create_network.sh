if hcloud network list | grep -q $CLUSTER_NAME; then
  echo "Network already exists, skipping."
else
  echo "Creating network..."

  hcloud network create --name $CLUSTER_NAME --ip-range 10.0.0.0/16
  hcloud network add-subnet $CLUSTER_NAME --network-zone eu-central --type server --ip-range 10.0.0.0/16
fi

if hcloud ssh-key list | grep -q $CLUSTER_NAME; then
  echo "SSH key already exists, skipping."
else
  echo "Creating SSH key..."

  hcloud ssh-key create --name $CLUSTER_NAME --public-key-from-file $SSH_KEY_PATH
fi
