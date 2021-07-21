# A fully functional, super cheap Kubernetes cluster in Hetzner Cloud in 1m30s or less

This repository contains some scripts to create, upgrade and destroy a Kubernetes cluster in [Hetzner Cloud](https://www.hetzner.com/cloud) using the lightweight Kubernetes distribution [k3s](https://k3s.io/), from [Rancher](https://rancher.com/). The scripts manage all the resources required for a secure cluster (firewall and private network together with instances).

This may well be the quickest, easiest, and cheapest way to create a self managed Kubernetes cluster. A cluster with master and a couple of worker nodes using the fast cpx21 instances (3 cores, 4GB each), as well as a load balancer, costs just 25 euros per month!

## Prerequisites

- An Hetzner Cloud account
- A cloud project
- An API token with read **and write** permissions on the project
- the Hetzner Cloud [CLI](https://github.com/hetznercloud/cli) installed
- the Kubernetes CLI (kubectl) installed

## Creating a cluster

1. Create an Hetzner Cloud context with the hcloud CLI using the token you've created in the project (`hcloud context create <cluster name>` and then enter the token)
2. Ensure that the hcloud CLI can connect to the project via API with the command `hcloud server list`. It should return an empty list if the project is empty, but with no errors
3. Clone this repo
4. Run the following command:

```bash
./create_cluster.sh \
  --hetzner-token <hetzner token> \
  --cluster-name <name of the cluster> \
  --kubeconfig-path ~/.kube/config \
  --k3s-token <a token/password for master-workers communication> \
  --k3s-version <the k3s version you want to deploy> \
  --master-instance-type <instance type> \
  --worker-instance-type <instance type> \
  --flannel-interface <private network interface> \
  --location <location> \
  --ssh-key-path ~/.ssh/id_rsa.pub \
  --worker-count <number of workers>
```

The whole process takes 1m30s or less for a couple of nodes so it's extremely fast.

### High availability setup

By default the cluster will be created with a single master, which means that the control plane is not highly available. If you wish to set it up in HA mode for production use, you can pass the following additional arguments:

```bash
--ha --master-count 3
```

`--master-count` must be an odd number greater than or equal to 3. When set up in HA mode, k3s will use an embedded etcd for storage.

### Conventions:

- the name of the cluster should ideally be URL compatible - such as in a few words separated by dashes - to avoid issues
- the create script will overwrite the file at the path you specify with --kubeconfig-path
- k3s-token: this can be any valid string. It is used for authenticated communication between master and workers
- master and instance types: these are the short codes for the instance types you want to use for the master and the workers. You can find the list of available instance types either in the Hetzner Cloud control panel or by running this command with your Hetzner token:

```bash
./instance_types.sh --hetzner-token <hetzner token>
```
It will show a list of the instance types with their information (name, price, memory, cpu, etc) in json format
- flannel-interface: this is the name of the private network interface that will be used for the private communication between the nodes, so that no services (other than the Kubernetes API on the port 6443 on the master) are exposed to the public Internet. Be aware that in Hetzner Cloud the name of the private network interface changes depending on the instance type. For simplicity, the script assumes that both master and worker nodes are of the same instance type class (e.g. all from the CPX series), so it requires that you specify only one interface in the arguments
- location: this is the short code for the datacenter location. Currently the available locations are nbg1 (Nuremberg, Germany), fsn1 (Falkenstein, Germany) and hel1 (Helsinki, Finland)
- ssh key path: this is the path of your public ssh key that you want to add to the servers, so that your computer can run commands on them; this argument is optional and if omitted the script will assume ~/.ssh/id_rsa.pub as the path of the public key
- worker-count: the number of worker nodes

### Recommendations

- I recommend that you use nbg1 (Nuremberg) as the location since the latency is pretty good outside Europe as well (for example for US users)
- I use instances with shared cores of the cpx series since they offer the best performance/cost ratio. I currently use the cpx21 model for my main cluster because it's the best value in terms of cores/memory/price
- if you also use the cpx instances, the name of the private network interface that you need to specify with the create command is "enp7s0". If you choose another instance type, create a temp instance of that type and check what is the name of the interface for that kind of instance

### What this script does

This script creates:

- a firewall that only opens the port 6443 for the Kubernetes API, and the port 22 for SSH; it also allows full communication between nodes on the private network
- a private network with the default 10.0.0.0/16 range
- the instances you specify for the master and worker nodes

The script also

- installs fail2ban on the instances to ban IPs from which brute force attacks on SSH originate
- disables the password authentication for SSH, so that a key is required

When deploying Kubernetes (k3s):

- installs the Hetzner cloud controller manager so that you can provision load balancers for your services as soon as the cluster is ready
- installs the Hetzner CSI driver so that you can provision persistent volumes using Hetzner's block storage
- installs Rancher's system upgrade controller to make Kubernetes upgrades super easy and really fast (more on this in the next section)

### Idempotency

The script can be run with exactly the same arguments as many times as you want, for example to add worker nodes, in which case you will only change the --worker-count argument.
## Upgrades

To perform an upgrade of the Kubernetes/k3s version, first find the newer release you want to upgrade to. You can see the list of available releases with the following script:

```bash
./releases.sh
```

Please note that the script requires the jq utility to format the release names in a user friendly format.

Next, switch to the Hetzner context for the right project:

```bash
hcloud context use <cluster-name>
```

Then run the following command to initiate the upgrade:

```bash
./upgrade_cluster.sh \
  --cluster-name <cluster name> \
  --to-version <new k3s version>
```

The script will create upgrade "plans", which will be picked by the system upgrade controller to initiate the upgrade. It will first upgrade the master, and then the workers with a concurrency that equals the number of workers minus 1. The process takes around a minute or less.

Notes:
- the upgrade requires that the metrics server be running (the metrics server is installed automatically when you create the cluster)
- the script assumes that there is a kube context with the same name as the cluster. You should have it with the kubeconfig generated when you created the cluster in first place.
- if something goes wrong or some nodes are not upgraded, you can re-run the script but first you need to delete the existing upgrade plans/jobs and restart the upgrade controller:

```bash
kubectl --context $CLUSTER_NAME -n system-upgrade delete job --all
kubectl --context $CLUSTER_NAME -n system-upgrade delete plan --all
kubectl --context $CLUSTER_NAME -n system-upgrade rollout restart deploy system-upgrade-controller
```

Wait for the controller's pod to be running and run the script again. You can also check the status of the upgrade jobs and pods if something isn't working as expected.

## Destroying the cluster

To destroy the cluster, first switch to the correct Hetzner context:

```bash
hcloud context use hcloud-prod
```

Then run the destroy script:

```bash
./destroy_cluster.sh \
  --hetzner-token <hetzner token> \
  --cluster-name <cluster name>
```

Note: the script assumes that there is a kube context with the same name as the cluster. You should have it with the kubeconfig generated when you created the cluster in first place.


## Load balancers

Once the cluster is ready, you can already provision services of type LoadBalancer thanks to the Hetzner Cloud Controller Manager that is installed automatically.

There are some annotations that you can add to your services to configure the load balancers. I personally use the following:

```yaml
  service:
    annotations:
      load-balancer.hetzner.cloud/hostname: <a valid fqdn>
      load-balancer.hetzner.cloud/http-redirect-https: 'false'
      load-balancer.hetzner.cloud/location: nbg1
      load-balancer.hetzner.cloud/name: <lb name>
      load-balancer.hetzner.cloud/uses-proxyprotocol: 'true'
      load-balancer.hetzner.cloud/use-private-ip: "true"
```

I set `load-balancer.hetzner.cloud/hostname` to a valid hostname that I configure (after creating the load balancer) with the IP of the load balancer; I use this together with the annotation `load-balancer.hetzner.cloud/uses-proxyprotocol: 'true'` to enable the proxy protocol. Reason: I enable the proxy protocol on the load balancers so that my ingress controller and applications can "see" the real IP address of the client. However when this is enabled, there is a problem where cert-manager fails http01 challenges; you can find an explanation of why [here](https://github.com/compumike/hairpin-proxy) but the easy fix provided by some providers including Hetzner, is to configure the load balancer so that it uses a hostname instead of an IP. Again, read the explanation for the reason but if you care about seeing the actual IP of the client then I recommend you use these two annotations.

The annotation `load-balancer.hetzner.cloud/use-private-ip: "true"` ensures that the communication between the load balancer and the nodes happens through the private network, so we don't have to open any ports on the nodes (other than the port 6443 for the Kubernetes API server).

The other annotations should be self explanatory. You can find a list of the available annotations [here](https://github.com/hetznercloud/hcloud-cloud-controller-manager/blob/master/internal/annotation/load_balancer.go).


## Persistent volumes

Once the cluster is ready you can create persistent volumes out of the box with the default storage class `hcloud-volumes`, since the Hetzner CSI driver is installed automatically. This will use Hetzner's block storage (based on Ceph so it's replicated and highly available) for your persistent volumes. Note that the minimum size of a volume is 10Gi. If you specify a smaller size for a volume, the volume will be created with a capacity of 10Gi anyway.

