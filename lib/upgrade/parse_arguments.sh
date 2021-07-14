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
  --to-version)
    TO_VERSION="$2"
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

[[ -z "$TO_VERSION" ]] && { echo "Please specify thenew k3s version with '--to-version <version>'" ; exit 1; }
