# Frequently Asked Questions

## Allocating Node Resources
   This section describes the CPU and Memory allocable resource for your QHub node group [jupyterlab profiles](https://docs.qhub.dev/en/stable/source/05_reference/02_system_maintenance.html?highlight=node%20groups#setting-specific-jupyterlab-profile-to-run-on-a-nodegroup) to use depending on which provider. The CPU and memory allocation for each provider are [configurable](https://docs.qhub.dev/en/stable/source/02_get_started/04_configuration.html?highlight=profiles#provider-infrastructure) where each node group aggregates the machine type information to generate your cluster. The pods profiles contain the required cpu, memory and image requirements for your intended usage.
### Setting CPU requests and limits
   Requests and limits on CPU and memory are measured in CPU units and in bytes respectfully, with some standard short codes to specify larger amounts, such as Kilobytes (K) or 1,000 bytes, Megabytes (M) or 1,000,000 bytes, and Gigabytes (G) or 1,000,000,000 bytes.

   > There is also the power of 2 versions of these shortcuts. For example, Ki (1,024 bytes), Mi, and Gi. Unlike CPU units, there are no fractions for memory as the smallest unit is a byte.

   While you can enter fractions of the CPU as decimals — for example, 0.5 of a CPU — Kubernetes uses the “millicpu” notation, where 1,000 millicpu (or 1,000m) equals 1 CPU unit.
   When we submit a request for a CPU unit, or a fraction of it, the Kubernetes scheduler will use this value to find a node within a cluster that the Pod can run on. For instance, if a Pod contains a single container with a CPU request of 1 CPU, the scheduler will ensure the node it places this Pod on has 1 CPU resource free.

   When you specify a resource limit for a Container, the [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) enforces those limits so that the running container is not allowed to use more of that resource than the limit you set. If we specify a CPU limit, Kubernetes will try to set the container's upper CPU usage limit. This is not a hard limit, and a container may or may not exceed this limit depending on the containerization technology. Memory limits work in a similar way to CPU limits except they are enforced in a more strict manner. If a container exceeds a memory limit, it might be terminated and potentially restarted with an “out of memory” error, refer [eviction threshold](https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/#eviction-thresholds) documentations on kubernetes for more details.

   For more information on managing resource limits for containers, refer to the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/).

### CPU and Memory Allocations
   Above we discussed the importance of memory and cpu requests and limits for a successful jupyterlab profile deployment. But how do you decide how to assign resources?

   Unfortunately, there isn't a fixed answer as it depends on your cluster. However, there's consensus in the major managed Kubernetes services Google Kubernetes Engine (GKE), Azure Kubernetes Service (AKS), and Elastic Kubernetes Service (EKS), and it's worth discussing how they partition the available resources.

### Google Kubernetes Engine (GKE)
   Google Kubernetes Engine (GKE) has a [well-defined list of rules to assign memory and CPU to a Node](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-architecture#memory_cpu), where Allocatable resources are calculated in the following way:

   `ALLOCATABLE = CAPACITY - RESERVED - EVICTION-THRESHOLD`

#### Example

### Azure Kubernetes Service (AKS)
   Azure kubernetes service has a nice overview and example usage of their [resource allocation](https://docs.microsoft.com/en-us/azure/aks/concepts-clusters-workloads#resource-reservations) based on well explained rules for each allocable and managed resource.

### Elastic Kubernetes Service (EKS)

### Digital Ocean (DO)

   Digital ocean does not directly provides their allocatable resources computation formula as GCP, but they do provide an [available memory chart for node sizes](https://www.digitalocean.com/docs/kubernetes/#allocatable-memory).

   That does not list the requests for CPU but looking at a basic cluster in kube-system the default kube-system pods request almost `~700m` or `70%` of all the CPU available on a 1 CPU node.

If you do have kubectl installed in your machine, you can inspect the node-allocatable resources available in a cluster, running the following command, replacing `<NODE_NAME>` with the name of the node you want to inspect:
`kubectl describe node <NODE_NAME> | grep Allocatable -B 7 -A 6`
The returned output contains Capacity and Allocatable fields with measurements for ephemeral storage, memory, and CPU.

