## About the project

This README and this repo's content has been extended to include all steps used in the original walkthrough: [here](https://www.khanhph.com/install-proxmox-kubernetes).
The walkthrough has also been downloaded under './guide'.

This project allows you to create a Kubernetes cluster on [Proxmox VE](https://pve.proxmox.com/wiki/Main_Page) using [Terraform](https://www.terraform.io/) and [Kubespray](https://github.com/kubernetes-sigs/kubespray) in a declarative manner.

![Proxmox Kubernetes clusters](proxmox-kubernetes.png)

## Prerequisites

### Software requirements

Ensure the following software versions are installed:

* [Proxmox VE](https://www.proxmox.com/en/proxmox-ve/get-started/) `>=7.3.3`
* [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli/) `>=1.3.3`

> Kubespray will be set up automatically.

### Usage

Follow these steps to use the project:

1. Clone the repo on a machine with access to the Proxmox API:

    ```sh
    git clone https://github.com/khanh-ph/proxmox-kubernetes.git
    ```

2. Create a `.env` file and populate it with the environment variables provided in `.req_env`.

3. Run `make setup` or `./scripts/setup_dev_environment.sh` on machine running this deployment to ensure all pre-reqs are met.

4. Copy this repo, along with your changes, to the proxmox host if that's not where you've been working. Also copy the .env file. For now the `TF_VAR_ssh_public_keys` and `TF_VAR_ssh_private_keys` variables can be empty strings.

5. Run `./scripts/setup_proxmox_host.sh` on the proxmox host to setup networking, VM template, SSH key pair, and Bastion host.

6. Grab the ssh keys created by the `setup_proxmox_host.sh` script on proxmox host, base64 encode the key files content and store them in the .env file as `TF_VAR_ssh_public_keys` and `TF_VAR_ssh_private_keys`. The key file encoded MUST end with an empty line!

7. If performing the remaining steps on the proxmos host, continue to next step. Otherwise:
    * Run `update_dev_environment.sh` to get copy down our ssh config from the proxmox server.

8. Copy `example.tfvars`, naming it to match the environment being built (i.e. `test.tfvars`), then update the values to match the desired outcome.

9. Pull in the environment variables we've been using.

    ```sh
    source ./scripts/set_vars.sh
    ```

10. Initialize the Terraform working directory.

    ```sh
    terraform init
    ```

11. Generate an execution plan and review the output to ensure that the planned changes align with your expectations.

    ```sh
    terraform plan -var-file="test.tfvars" -out "test_plan"
    ```

12. If you're satisfied with the plan and ready to apply the changes. Run the following command, specifying your plan name.

    ```sh
    terraform apply "test_plan"
    ```

## Terraform configurations

The project provides several Terraform variables that allow you to customize the cluster to suit your needs. Please see the following:

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | The stage of the development lifecycle for the k8s cluster. Example: `prod`, `dev`, `qa`, `stage`, `test` | `string` | `"test"` | no |
| <a name="input_location"></a> [location](#input\_location) | The city or region where the cluster is provisioned | `string` | `null` | no |
| <a name="input_cluster_number"></a> [cluster\_number](#input\_cluster\_number) | The instance count for the k8s cluster, to differentiate it from other clusters. Example: `00`, `01` | `string` | `"01"` | no |
| <a name="input_cluster_domain"></a> [cluster\_domain](#input\_cluster\_domain) | The cluster domain name | `string` | `"local"` | no |
| <a name="input_use_legacy_naming_convention"></a> [use\_legacy\_naming\_convention](#input\_use\_legacy\_naming\_convention) | A boolean value that indicates whether to use legacy naming convention for the VM and cluster name. If your cluster was provisioned using version <= 3.x, set it to `true` | `bool` | `false` | no |
| <a name="input_pm_api_url"></a> [pm\_api\_url](#input\_pm\_api\_url) | The base URL for Proxmox VE API. See https://pve.proxmox.com/wiki/Proxmox_VE_API#API_URL | `string` | n/a | yes |
| <a name="input_pm_api_token_id"></a> [pm\_api\_token\_id](#input\_pm\_api\_token\_id) | The token ID to access Proxmox VE API. | `string` | n/a | yes |
| <a name="input_pm_api_token_secret"></a> [pm\_api\_token\_secret](#input\_pm\_api\_token\_secret) | The UUID/secret of the token defined in the variable `pm_api_token_id`. | `string` | n/a | yes |
| <a name="input_pm_tls_insecure"></a> [pm\_tls\_insecure](#input\_pm\_tls\_insecure) | Disable TLS verification while connecting to the Proxmox VE API server. | `bool` | n/a | yes |
| <a name="input_pm_host"></a> [pm\_host](#input\_pm\_host) | The name of Proxmox node where the VM is placed. | `string` | n/a | yes |
| <a name="input_pm_parallel"></a> [pm\_parallel](#input\_pm\_parallel) | The number of simultaneous Proxmox processes. E.g: creating resources. | `number` | `2` | no |
| <a name="input_pm_timeout"></a> [pm\_timeout](#input\_pm\_timeout) | Timeout value (seconds) for proxmox API calls. | `number` | `600` | no |
| <a name="input_internal_net_name"></a> [internal\_net\_name](#input\_internal\_net\_name) | Name of the internal network bridge | `string` | `"vmbr1"` | no |
| <a name="input_internal_net_subnet_cidr"></a> [internal\_net\_subnet\_cidr](#input\_internal\_net\_subnet\_cidr) | CIDR of the internal network | `string` | `"10.0.1.0/24"` | no |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | SSH private key in base64, will be used by Terraform client to connect to the VM after provisioning | `string` | n/a | yes |
| <a name="input_ssh_public_keys"></a> [ssh\_public\_keys](#input\_ssh\_public\_keys) | SSH public keys in base64 | `string` | n/a | yes |
| <a name="input_vm_user"></a> [vm\_user](#input\_vm\_user) | The default user for all VMs | `string` | `"ubuntu"` | no |
| <a name="input_vm_sockets"></a> [vm\_sockets](#input\_vm\_sockets) | Number of the CPU socket to allocate to the VMs | `number` | `1` | no |
| <a name="input_vm_max_vcpus"></a> [vm\_max\_vcpus](#input\_vm\_max\_vcpus) | The maximum CPU cores available per CPU socket to allocate to the VM | `number` | `2` | no |
| <a name="input_vm_cpu_type"></a> [vm\_cpu\_type](#input\_vm\_cpu\_type) | The type of CPU to emulate in the Guest | `string` | `"host"` | no |
| <a name="input_vm_os_disk_storage"></a> [vm\_os\_disk\_storage](#input\_vm\_os\_disk\_storage) | Default storage pool where OS VM disk is placed | `string` | n/a | yes |
| <a name="input_add_worker_node_data_disk"></a> [add\_worker\_node\_data\_disk](#input\_add\_worker\_node\_data\_disk) | A boolean value that indicates whether to add a data disk to each worker node of the cluster | `bool` | `false` | no |
| <a name="input_worker_node_data_disk_storage"></a> [worker\_node\_data\_disk\_storage](#input\_worker\_node\_data\_disk\_storage) | The storage pool where the data disk is placed | `string` | `""` | no |
| <a name="input_worker_node_data_disk_size"></a> [worker\_node\_data\_disk\_size](#input\_worker\_node\_data\_disk\_size) | The size of worker node data disk in Gigabyte | `string` | `10` | no |
| <a name="input_vm_ubuntu_tmpl_name"></a> [vm\_ubuntu\_tmpl\_name](#input\_vm\_ubuntu\_tmpl\_name) | Name of Cloud-init template Ubuntu VM | `string` | `"ubuntu-2204"` | no |
| <a name="input_bastion_ssh_ip"></a> [bastion\_ssh\_ip](#input\_bastion\_ssh\_ip) | IP of the bastion host, could be either public IP or local network IP of the bastion host | `string` | `""` | no |
| <a name="input_bastion_ssh_user"></a> [bastion\_ssh\_user](#input\_bastion\_ssh\_user) | The user to authenticate to the bastion host | `string` | `"ubuntu"` | no |
| <a name="input_bastion_ssh_port"></a> [bastion\_ssh\_port](#input\_bastion\_ssh\_port) | The SSH port number on the bastion host | `number` | `22` | no |
| <a name="input_vm_k8s_control_plane"></a> [vm\_k8s\_control\_plane](#input\_vm\_k8s\_control\_plane) | Control Plane VM specification | `object({ node_count = number, vcpus = number, memory = number, disk_size = number })` | <pre>{<br>  "disk_size": 20,<br>  "memory": 1536,<br>  "node_count": 1,<br>  "vcpus": 2<br>}</pre> | no |
| <a name="input_vm_k8s_worker"></a> [vm\_k8s\_worker](#input\_vm\_k8s\_worker) | Worker VM specification | `object({ node_count = number, vcpus = number, memory = number, disk_size = number })` | <pre>{<br>  "disk_size": 20,<br>  "memory": 2048,<br>  "node_count": 2,<br>  "vcpus": 2<br>}</pre> | no |
| <a name="input_create_kubespray_host"></a> [create\_kubespray\_host](#input\_create\_kubespray\_host) | Kubernetes settings ####################################################################### | `bool` | `true` | no |
| <a name="input_kubespray_image"></a> [kubespray\_image](#input\_kubespray\_image) | n/a | `string` | `"khanhphhub/kubespray:v2.22.0"` | no |
| <a name="input_kube_version"></a> [kube\_version](#input\_kube\_version) | Kubernetes version | `string` | `"v1.24.6"` | no |
| <a name="input_kube_network_plugin"></a> [kube\_network\_plugin](#input\_kube\_network\_plugin) | The network plugin to be installed on your cluster. Example: `cilium`, `calico`, `kube-ovn`, `weave` or `flannel` | `string` | `"calico"` | no |
| <a name="input_enable_nodelocaldns"></a> [enable\_nodelocaldns](#input\_enable\_nodelocaldns) | A boolean value that indicates whether to enable nodelocal dns cache on your cluster | `bool` | `false` | no |
| <a name="input_podsecuritypolicy_enabled"></a> [podsecuritypolicy\_enabled](#input\_podsecuritypolicy\_enabled) | A boolean value that indicates whether to enable pod security policy on your cluster (RBAC must be enabled either by having 'RBAC' in authorization\_modes or kubeadm enabled) | `bool` | `false` | no |
| <a name="input_persistent_volumes_enabled"></a> [persistent\_volumes\_enabled](#input\_persistent\_volumes\_enabled) | A boolean value that indicates whether to add Persistent Volumes Storage Class for corresponding cloud provider (supported: in-tree OpenStack, Cinder CSI, AWS EBS CSI, Azure Disk CSI, GCP Persistent Disk CSI) | `bool` | `false` | no |
| <a name="input_helm_enabled"></a> [helm\_enabled](#input\_helm\_enabled) | A boolean value that indicates whether to enable Helm on your cluster | `bool` | `false` | no |
| <a name="input_ingress_nginx_enabled"></a> [ingress\_nginx\_enabled](#input\_ingress\_nginx\_enabled) | A boolean value that indicates whether to enable Nginx ingress on your cluster | `bool` | `false` | no |
| <a name="input_argocd_enabled"></a> [argocd\_enabled](#input\_argocd\_enabled) | A boolean value that indicates whether to enable ArgoCD on your cluster | `bool` | `false` | no |
| <a name="input_argocd_version"></a> [argocd\_version](#input\_argocd\_version) | The ArgoCD version to be installed | `string` | `"v2.4.12"` | no |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Blog posts

For more detailed instructions, refer to the following blog post: [Create a Kubernetes cluster on Proxmox with Terraform & Kubespray](https://www.khanhph.com/install-proxmox-kubernetes/)
