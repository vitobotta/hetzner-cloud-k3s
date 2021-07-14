NODES=($(kubectl --context $CLUSTER_NAME get nodes --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'))

for NODE in "${NODES[@]}"
do
  :
  echo "Deleting instance $NODE..."

  hcloud server delete $NODE &
done

wait

hcloud network delete $CLUSTER_NAME

hcloud firewall delete $CLUSTER_NAME

hcloud ssh-key delete $CLUSTER_NAME
