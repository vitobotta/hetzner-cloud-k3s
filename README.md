# A fully functional, super cheap Kubernetes cluster in Hetzner Cloud in 1m30s or less

This repository contains some scripts to create, upgrade and destroy a Kubernetes cluster in [Hetzner Cloud](https://www.hetzner.com/cloud) using the lightweight Kubernetes distribution [k3s](https://k3s.io/), from [Rancher](https://rancher.com/). The scripts manage all the resources required for a secure cluster (firewall and private network together with instances).

This may well be the quickest, easiest, and cheapest way to create a self managed Kubernetes cluster. A cluster with master and a couple of worker nodes using the fast cpx21 instances (3 cores, 4GB each) costs just 28 euros per month!

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

### Conventions:

- the name of the cluster should ideally be URL compatible - such as in a few words separated by dashes - to avoid issues
- the create script will overwrite the file at the path you specify with --kubeconfig-path
- k3s-token: this can be any valid string. It is used for authenticated communication between master and workers
- master and instance types: these are the short codes for the instance types you want to use for the master and the workers. You can find the list of available instance types either in the Hetzner Cloud control panel or by running this curl command with your Hetzner token:

```bash
curl \
	-H "Authorization: Bearer $HETZNER_API_TOKEN" \
	'https://api.hetzner.cloud/v1/server_types'
```

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
- installs Rancher's system upgrade controller to make Kubernets upgrades super easy and really fast (more on this in the next section)

---

## Upgrades

To perform an upgrade of the Kubernetes/k3s version, first find the newer release you want to upgrade to. You can see the list of available releases with the following script:

```bash
./releases.sh
```

Next, switch to the Hetzner context for the right project:

Then run the following command to initiate the upgrade:

```bash
./upgrade_cluster.sh \
  --cluster-name <cluster name> \
  --to-version <new k3s version> \
  --master-instance-type <master instance type> \
  --worker-instance-type <worker instance type> \
  --worker-count <number of workers>
```

The master/worker instance types and the worker count are required to correctly generate the names of the instances to upgrade. This is to avoid problems if you happen to have multiple Kubernetes clusters in the same Hetzner project; I strongly recommend keeping a separate project for each cluster though.

The script will create upgrade "plans", which will be picked by the system upgrade controller to initiate the upgrade. It will first upgrade the master, and then the workers with a concurrency that equals the number of workers minus 1. The process takes around a minute or less.


## Destroying the cluster

To destroy the cluster, first switch to the correct Hetzner context:

```bash
hcloud context use hcloud-prod
```

Then run the destroy script:

```bash
./destroy_cluster.sh \
  --hetzner-token <hetzner token> \
  --cluster-name <cluster name> \
  --master-instance-type <master instance type> \
  --worker-instance-type <worker instance type> \
  --worker-count <number of workers>
```

Like for upgrades, the master/worker instance types and the number of workers are needed to determine the names of the resources to destroy. This takes just a few seconds.


## Notes

In this setup, the control plane has a single master and therefore is not HA. Even some managed Kubernetes services such as the one offered by [DigitalOcean](https://www.digitalocean.com/products/kubernetes/) have a non-HA control plane, because if for example the master is temporarily unavailable due to maintenance or else, the actual workloads are not affected in most cases, so this is fine in most cases.

k3s also supports HA configurations with multiple master either with external datastores such as MySQL or Postgres, or with an embedded etcd, so I may add this support to my scripts in the future. For now I am happy with a single master and like I said it's fine in most cases.
