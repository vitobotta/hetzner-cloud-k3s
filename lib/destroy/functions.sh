instance_name() {
  echo "$CLUSTER_NAME-$1-$2"
}

destroy_server () {
  INSTANCE_TYPE=$1
  INSTANCE_NAME=$(instance_name $INSTANCE_TYPE $2)

  echo "Deleting instance $INSTANCE_NAME..."

  hcloud server delete $INSTANCE_NAME
}
