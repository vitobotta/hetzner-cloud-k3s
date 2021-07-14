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
  *)
    POSITIONAL+=("$1")
    shift
  ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

[[ -z "$CLUSTER_NAME" ]] && { echo "Please specify the cluster name with '--cluster-name <name>'" ; exit 1; }

[[ -z "$HETZNER_TOKEN" ]] && { echo "Please specify the Hetzner token with '--hetzner-token <token>'" ; exit 1; }
