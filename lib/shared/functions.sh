instance_name() {
  echo "$CLUSTER_NAME-$1-$2"
}

create_server () {
  INSTANCE_TYPE=$1
  INSTANCE_NAME=$(instance_name $INSTANCE_TYPE $2)

  if hcloud server list | grep -q $INSTANCE_NAME; then
    echo "Instance $INSTANCE_NAME already exists, skipping."
  else
    echo "Creating instance $INSTANCE_NAME..."

    hcloud server create \
      --name $INSTANCE_NAME \
      --image ubuntu-20.04 \
      --firewall $CLUSTER_NAME \
      --network $CLUSTER_NAME \
      --location $LOCATION \
      --ssh-key $CLUSTER_NAME \
      --type $INSTANCE_TYPE \
      --user-data-from-file /tmp/user-data
  fi
}

public_ip () {
  INSTANCE_TYPE=$1
  INSTANCE_NAME=$(instance_name $INSTANCE_TYPE $2)
  IP_LINE=$(hcloud server describe $INSTANCE_NAME | grep "IP:" | head -n1)
  IP=""

  for word in $IP_LINE
  do
    IP=$word
  done

  echo $IP
}

get_latest_release() {
  curl --silent "https://api.github.com/repos/k3s-io/k3s/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}
