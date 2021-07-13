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
  --hetzner-token)
    HETZNER_TOKEN="$2"
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
  --worker-count)
    WORKER_COUNT="$2"
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

[[ -z "$HETZNER_TOKEN" ]] && { echo "Please specify the Hetzner token with '--hetzner-token <token>'" ; exit 1; }

[[ -z "$MASTER_INSTANCE_TYPE" ]] && { echo "Please specify the type of the master instance with '--master-instance-type <instance type>'" ; exit 1; }

[[ -z "$WORKER_INSTANCE_TYPE" ]] && { echo "Please specify the type of the worker instances with '--worker-instance-type <instance type>'" ; exit 1; }
[[ -z "$WORKER_COUNT" ]] && { echo "Please specify the number of workers with '--worker-count <number>'" ; exit 1; }
