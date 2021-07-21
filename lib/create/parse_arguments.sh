POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  --cluster-name)
    CLUSTER_NAME="$2"
    shift # past argument
    shift # past value
  ;;
  --kubeconfig-path)
    KUBECONFIG_PATH="$2"
    shift # past argument
    shift # past value
  ;;
  --hetzner-token)
    HETZNER_TOKEN="$2"
    shift # past argument
    shift # past value
  ;;
  --k3s-token)
    K3S_TOKEN="$2"
    shift # past argument
    shift # past value
  ;;
  --k3s-version)
    K3S_VERSION="$2"
    shift # past argument
    shift # past value
  ;;
  --master-instance-type)
    MASTER_INSTANCE_TYPE="$2"
    shift
    shift
  ;;
  --worker-instance-type)
    WORKER_INSTANCE_TYPE="$2"
    shift
    shift
  ;;
  --location)
    LOCATION="$2"
    shift
    shift
  ;;
  --ha)
    HA="true"
    shift
  ;;
  --master-count)
    MASTER_COUNT="$2"
    shift
    shift
  ;;
  --worker-count)
    WORKER_COUNT="$2"
    shift
    shift
  ;;
  --flannel-interface)
    FLANNEL_INTERFACE="$2"
    shift
    shift
  ;;
  --cluster-cidr)
    FLANNEL_INTERFACE="$2"
    shift
    shift
  ;;
  --ssh-user)
    SSH_USER="$2"
    shift
    shift
  ;;
  --ssh-key-path)
    SSH_KEY_PATH="$2"
    shift
    shift
  ;;
  *)
    POSITIONAL+=("$1")
    shift
  ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

[[ -z "$CLUSTER_NAME" ]] && { echo "Please specify the cluster name with '--cluster-name <name>'" ; exit 1; }

[[ -z "$KUBECONFIG_PATH" ]] && { echo "Please specify the path where to save the kubeconfig with '--kubeconfig-path <path>'" ; exit 1; }

[[ -z "$K3S_TOKEN" ]] && { echo "Please specify the k3s token with '--k3s-token <token>'" ; exit 1; }

[[ -z "$HETZNER_TOKEN" ]] && { echo "Please specify the Hetzner token with '--hetzner-token <token>'" ; exit 1; }

[[ -z "$MASTER_INSTANCE_TYPE" ]] && { echo "Please specify the type of the master instance with '--master-instance-type <instance type>'" ; exit 1; }

[[ -z "$WORKER_INSTANCE_TYPE" ]] && { echo "Please specify the type of the worker instances with '--worker-instance-type <instance type>'" ; exit 1; }
[[ -z "$WORKER_COUNT" ]] && { echo "Please specify the number of workers with '--worker-count <number>'" ; exit 1; }

[[ -z "$LOCATION" ]] && { echo "Please specify the location with '--location <location>'" ; exit 1; }

[[ -z "$FLANNEL_INTERFACE" ]] && { echo "Please specify the Flannel interface with '--flannel-interface <interfacce>'" ; exit 1; }


CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
SSH_USER=${SSH_USER:-"root"}
SSH_KEY_PATH=${SSH_KEY_PATH:-"$HOME/.ssh/id_rsa.pub"}
LATEST_VERSION=$(get_latest_release)
K3S_VERSION=${K3S_VERSION:-"$LATEST_VERSION"}
HA=${HA:-"false"}
MASTER_COUNT=${MASTER_COUNT:-"1"}


if [ "$HA" == "true" ]; then
  if [ "$MASTER_COUNT" -lt "3" ] || [ $(($MASTER_COUNT%2)) -eq 0 ]; then
    echo "With high availability enabled, the master count must an odd number greater or equal to 3."
    exit 1
  fi
else
  if [ "$MASTER_COUNT" != "1" ]; then
    echo "Ignoring the master count parameter because high availability is disabled."
  fi
fi



