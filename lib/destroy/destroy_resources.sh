destroy_server $MASTER_INSTANCE_TYPE master &

COUNTER=0
while [  $COUNTER -lt $WORKER_COUNT ]; do
  let COUNTER=COUNTER+1
  destroy_server $WORKER_INSTANCE_TYPE worker$COUNTER &
done

wait

hcloud network delete $CLUSTER_NAME

hcloud firewall delete $CLUSTER_NAME

hcloud ssh-key delete $CLUSTER_NAME
