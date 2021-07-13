#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source $SCRIPT_DIR/lib/upgrade/parse_arguments.sh

KUBECONFIG=$KUBECONFIG_PATH
WORKER_UPGRADE_CONCURRENCY=$((WORKER_COUNT-1))

source $SCRIPT_DIR/lib/upgrade/functions.sh

source $SCRIPT_DIR/lib/upgrade/parse_arguments.sh

echo "Configuring cluster $CLUSTER_NAME for upgrade to k3s version $TO_VERSION ..."


echo
echo "Preparing master for upgrade..."

kubectl label nodes $(instance_name $MASTER_INSTANCE_TYPE master) k3s-upgrade=true


COUNTER=0
while [  $COUNTER -lt $WORKER_COUNT ]; do
  let COUNTER=COUNTER+1

  INSTANCE_NAME=$(instance_name $WORKER_INSTANCE_TYPE worker$COUNTER)

  echo
  echo "Preparing worker $COUNTER for upgrade..."

  kubectl label nodes $INSTANCE_NAME k3s-upgrade=true
done



kubectl apply -f - <<EOF
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-server
  namespace: system-upgrade
  labels:
    k3s-upgrade: server
spec:
  concurrency: 1
  version: $TO_VERSION
  nodeSelector:
    matchExpressions:
      - {key: k3s-upgrade, operator: Exists}
      - {key: k3s-upgrade, operator: NotIn, values: ["disabled", "false"]}
      - {key: node-role.kubernetes.io/master, operator: In, values: ["true"]}
  serviceAccountName: system-upgrade
  tolerations:
  - key: "CriticalAddonsOnly"
    operator: "Equal"
    value: "true"
    effect: "NoExecute"
  cordon: true
#  drain:
#    force: true
  upgrade:
    image: rancher/k3s-upgrade
---
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-agent
  namespace: system-upgrade
  labels:
    k3s-upgrade: agent
spec:
  concurrency: $WORKER_UPGRADE_CONCURRENCY # in general, this should be the number of workers - 1
  version: $TO_VERSION
  nodeSelector:
    matchExpressions:
      - {key: k3s-upgrade, operator: Exists}
      - {key: k3s-upgrade, operator: NotIn, values: ["disabled", "false"]}
      - {key: node-role.kubernetes.io/master, operator: NotIn, values: ["true"]}
  serviceAccountName: system-upgrade
  prepare:
    # Since v0.5.0-m1 SUC will use the resolved version of the plan for the tag on the prepare container.
    # image: rancher/k3s-upgrade:v1.17.4-k3s1
    image: rancher/k3s-upgrade
    args: ["prepare", "k3s-server"]
  # drain:
  #   force: true
  #   skipWaitForDeleteTimeout: 60 # set this to prevent upgrades from hanging on small clusters since k8s v1.18
  upgrade:
    image: rancher/k3s-upgrade
EOF


echo
read -p "Upgrade will now start. You will be able to monitor the version change after pressing any key... " -n1 -s

watch kubectl get nodes
