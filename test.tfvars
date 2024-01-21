# Environment
########################################################################
env_name       = "test"
location       = null
cluster_number = "01"
cluster_domain = "local"
# If using this project version >= 4.0.0 with a previously provisioned cluster,
# check this setting: https://github.com/khanh-ph/proxmox-kubernetes/releases/tag/4.0.0
use_legacy_naming_convention = false

# Proxmox VE
########################################################################
# Proxmox VE API details and VM hosting configuration
# API token guide: https://registry.terraform.io/providers/Telmate/proxmox/2.9.14/docs
pm_api_url          = "https://172.16.0.11/api"
pm_api_token_id     = "terraform@pve!terraform"
# pm_api_token_secret = "your-api-token-secret"
pm_tls_insecure     = false
pm_host             = "proxmox"
pm_parallel         = 2
pm_timeout          = 600


# Common infrastructure configurations
########################################################################
# Kubernetes internal network
internal_net_name = "vmbr1"
# Internal network CIDR
internal_net_subnet_cidr = "10.0.1.0/24"
# Base64 encoded keys for Kubernetes admin authentication
ssh_public_keys = "c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFDQVFEQ3pyai82WWU3Nmh4aVovSmZnYWQzcUM0T05IbktsRHltODRFc09sK09kbklWV3JuZzF6cDhZdFdLMnVXZE9GTFdwYUw0aDltZGRib1FUM25va2hoY2ZTQmMraGVFZXlBemxqeEtoQUZJSnZYS3NiZDVFc0lRRm9sUi9JOHFHSDJ6OGpxTTRtdUFvT2kvWnRZdDZnekFGS2h0Y252OVJUZFB3Y0hzTDl1K2EvRU8zRENLWnFWaUhTOFpYYldXTGRPSSt4d0JORWFENjU0QlN2RHBFVXlQVDJKRlE4S2VmMHZiUUYyWTdRRFpGbUJRWnVvTnB6blVTZXVJQnVHMlF4aThHeGtUZHJzcFlrZEMxbXhVOHRwaFcyUlFaSHBhTjJTSXltenYwaWxXWTU3K1V1VzRkSHBEMDFBd011Tm5scENqZGhGRHhUTVBweDhZL3JlOVRHbWlzd0NhNWdYc253VktMbnp0aFBCWHN3QXhOS2FUVUJuZ3VHTHpmS3RtSTRpNU5NQXowSW5sSDEyTy80NW9palNlZHFwZjJQZDNUUlRGMEFNbS9tNG1MTk5ZYVEyaU9lRVdjTFhkK2lsdUpDNmtPQ1hnR2tGeVBXbUQxUThvelV3dm9hZFBqVmN0bG1DM1BWaW92N3NUUENsUXJpdGtXUG05NGpDSVptSE9SbWtmUUg4TEJKTWJ0M2R4S3BmbEFNcFh4VEY5OHExbjBUNnhFZjE1c0QvZW5WS0lkZTRZYlhuUmhjTnByaGNDK0VoNVJkcEZ4VlBzUXJhR3dYekdoa2RyQlIxRlVZSUxRVVJTNjV1WHlxK0hSSkRhRG1RWUlGWHVEMEo4ZW5VaTd3RyttVXUrbXlMY3g0YUtTelRsUElmanZrNWM3SVJnRHJrYmcySTN2bHJ6anc9PQ=="
# Caution: In production, follow https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables
# to protect the sensitive variable `ssh_private_key` 
# ssh_private_key = "put-base64-encoded-private-key-here"

# Default disk storage for the VMs. Uncomment the following line if needed
vm_os_disk_storage = "vms"

# Bastion host details. This is required for the Terraform client to 
# connect to the Kubespray VM that will be placed into the internet network
bastion_ssh_ip   = "192.168.1.131"
bastion_ssh_user = "ubuntu"
bastion_ssh_port = 22

# VM specifications
########################################################################
# Maximum cores that your Proxmox VE server can give to a VM
vm_max_vcpus = 2
# Control plane VM specifications
vm_k8s_control_plane = {
  node_count = 1
  vcpus      = 2
  memory     = 2048
  disk_size  = 20
}
# Worker nodes VM specifications
vm_k8s_worker = {
  node_count = 3
  vcpus      = 2
  memory     = 3072
  disk_size  = 20
}

# Kubernetes settings
########################################################################
kube_version               = "v1.24.6"
kube_network_plugin        = "calico"
enable_nodelocaldns        = false
podsecuritypolicy_enabled  = false
persistent_volumes_enabled = false
helm_enabled               = false
ingress_nginx_enabled      = false
argocd_enabled             = false
argocd_version             = "v2.4.12"