#!/bin/bash

#region Local Variables

VM_TEMPLATE_NAME=ubuntu-2204
VM_TEMPLATE_ID=9000
BASTION_USERNAME=ubuntu
BASTION_HOST_NAME=bastion
BASTION_HOST_ID=1049
BASTION_HOST_IP="172.16.0.49"
LAN_GW="172.16.0.1"


if ! sudo qm list >/dev/null 2>&1 ; then 
    echo "qm not found!"
    echo "script must be run on a proxmox host!"
    echo "if this is a proxmox host, be sure qm is in this user's PATH"
    exit 1
fi

#endregion


#region Environment Variables ###

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPTS_DIR}/set_vars.sh"
if [ $? -ne 0 ] ; then 
    exit 1
fi

#endregion


#region Install Pre-Reqs ###

# install sudo  (cwd = ROOT_DIR)
if ! sudo --version >/dev/null 2>&1 ; then 
    echo "installing sudo..."
    su root
    apt install -qqy sudo
    exit
fi
if ! sudo --version >/dev/null 2>&1 ; then 
    echo 'failed to install sudo, exiting...'
    exit 1
fi

# utilities
if ! curl --version >/dev/null 2>&1 ; then 
    echo "installing curl..."
    sudo apt install -qqy curl
fi
if ! curl --version >/dev/null 2>&1 ; then 
    echo 'failed to install curl, exiting...'
    exit 1
fi

#endregion


#region Configure Internal Network ###

file="/etc/network/interfaces"
backup_file="${file}.original_0"
device_config_file="${SCRIPTS_DIR}/files/interfaces.part"
device_name='vmbr1'
device_exists=''
device_config_matches=''

# determine if current configuration is desired
if [ -f "$file" ] ; then
    echo "file exists: \"$file\""
    if grep -Fq $device_name $file ; then
        echo "device \"$device_name\" already defined in file"
        device_exists=true

        # check if the device configuration matches   
        device_config_matches=true     
        while IFS= read -r line; do
            if ! grep -Fxqe "$line" "$file"; then
                device_config_matches=''
                break
            fi
        done < "$device_config_file"
    fi
else
    echo "creating \"$file\""
    sudo touch "$file"
fi

# exit if the device exists but the config doesn't match our device config file
if [ -f "$file" ] && [ $device_exists ] && [ ! $device_config_matches ] ; then
    echo "config for ${device_name} doesn't match!"
    echo "compare ${file} content with ${device_config_file}"
    echo "exiting..."
    exit 1
fi

# handle adding config to interfaces
if [ ! $device_config_matches ] ; then

    # backup the existing file
    if [ -f "$file" ] ; then

        echo "backing up \"$file\""

        # new file name
        suffix=0

        # determine new file name
        while [ -f "$backup_file" ]; do
            ((suffix++))
            backup_file="${file}.original_${suffix}"
        done

        # copy file
        sudo cp "$file" "$backup_file"
        echo "file copied to $backup_file"
    fi

    # append config
    sudo cat "${device_config_file}" | sudo tee -a "$file" > /dev/null
    echo "device configuration added to network"

    # validate configuration added to file
    if ! grep -Fxqf "$device_config_file" $file ; then
        echo "failed to add device to configuration, exiting..."
        exit 1
    fi

    # reload config
    sudo ifreload -a

    # validate device added
    if ! ip link show $device_name > /dev/null 2>&1 ; then 
        echo "device not showing, exiting..."
        exit 1
    fi
fi

echo "network configuration complete"

#endregion


#region Prepare VM Template ###

# checks whether the template exists
function qm_item_exists {
    if [ $# -ge 2 ] ; then
        sudo qm list | grep "$1" | grep "$2" &> /dev/null
    else
        sudo qm list | grep "$1" &> /dev/null
    fi
    return $?
}

# create template only if it doesn't exist or if FORCE_TEMPLATE_CREATION
if ! qm_item_exists $VM_TEMPLATE_NAME $VM_TEMPLATE_ID || [ $FORCE_TEMPLATE_CREATION ] ; then

    echo "creating vm template"

    # verify presence of script to create VM template
    template_script_url="https://raw.githubusercontent.com/${GH_USERNAME}/proxmox-scripts/master/create-vm-template/script.sh"
    http_status=$(curl -o /dev/null -s -I -w '%{http_code}' "$template_script_url")
    if [ "$http_status" -ne 200 ]; then
        echo "404 ${template_script_url}"
        echo "${GH_USERNAME} must fork \"https://github.com/khanh-ph/proxmox-scripts\""
        echo "or edit this script to use \"https://raw.githubusercontent.com/khanh-ph/proxmox-scripts/master/create-vm-template/script.sh\""
        echo "exiting..."
        exit 1
    fi

    # create template using script
    curl -s $template_script_url | sudo bash
fi

# verify template exists
if ! qm_item_exists $VM_TEMPLATE_NAME $VM_TEMPLATE_ID ; then
    echo "template not found!"
    exit 1
fi

echo "vm template creation complete"

#endregion


#region Generate SSH Key Pair ###

# generate key if needed
ssh_keyfile_path="${SSH_KEY_DIR}/${SSH_KEYFILE_NAME}"
if [ ! -f "${ssh_keyfile_path}" ] ; then
    echo "creating ssh key"
    ssh-keygen -t rsa -b 4096 -f "${ssh_keyfile_path}" -C "k8s-admin@cluster.local" -N ""
fi
if [ ! -f "${ssh_keyfile_path}" ] ; then
    echo "failed to generate ssh keys, exiting..."
fi

echo "ssh key generation complete"

#endregion


#region Setup Bastion Host ###

function test_ssh {
    timeout=120
    start_time=$(date +%s)

    while true; do
        ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i "${ssh_keyfile_path}" -n -q "$1" exit
        exit_status=$?

        # check status
        if [ $exit_status -eq 0 ]; then
            echo "ssh connection to $1 successful"
            return $exit_status
        fi

        # check timeout
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge $timeout ]; then
            echo "timed out testing ssh connection to $1"
            return $exit_status
        fi

        sleep 5
    done
}


# only create if vm doesn't exist
if ! qm_item_exists $BASTION_HOST_NAME $BASTION_HOST_ID ; then

    echo "creating bastion host"

    # clone template
    sudo qm clone $VM_TEMPLATE_ID $BASTION_HOST_ID --name $BASTION_HOST_NAME --full true
    if ! qm_item_exists $BASTION_HOST_NAME $BASTION_HOST_ID ; then
        echo "failed to create bastion vm, exiting..."
        exit 1
    fi
    
    # set ssh keys
    sudo qm set $BASTION_HOST_ID --sshkey "${ssh_keyfile_path}.pub"

    # connect to vmbr0 (LAN)
    sudo qm set $BASTION_HOST_ID --net0 virtio,bridge=vmbr0 --ipconfig0 ip=$BASTION_HOST_IP/24,gw=$LAN_GW

    # connect to vmbr1 (K8S)
    sudo qm set $BASTION_HOST_ID --net1 virtio,bridge=vmbr1 --ipconfig1 ip=10.0.1.2/24,gw=10.0.1.1

    # start the vm
    sudo qm start $BASTION_HOST_ID

    # validate we can connect
    echo "testing connection to ubuntu@$BASTION_HOST_IP using $ssh_keyfile_path..."
    if ! test_ssh "ubuntu@${BASTION_HOST_IP}" ; then
        echo "failed to reach bastion host, exiting..."
        exit 1
    fi
fi

echo "bastion host created"

#endregion


#region Create SSH Config for Bastion ###

echo "setup config for connections to bastion"

# check if bastion host exists in proxmox's ssh config
file="/home/${USER}/.ssh/config"
backup_file="${file}.original_0"
host_config_content="#BASTION
Host ${BASTION_HOST_IP}
   HostName ${BASTION_HOST_IP}
   PreferredAuthentications publickey
   User ${BASTION_USERNAME}
   IdentityFile ${ssh_keyfile_path}"
host_identifier="Host ${BASTION_HOST_IP}"
host_exists=''
host_config_matches=''

# determine if current configuration is desired
if [ -f "$file" ] ; then
    echo "file exists: \"$file\""
    if grep -Fq "$host_identifier" $file >/dev/null 2>&1; then
        echo "\"$host_identifier\" already defined in file"
        host_exists=true

        # check if the device configuration matches   
        host_config_matches=true     
        while IFS= read -r line; do
            if ! grep -Fxqe "$line" "$file"; then
                device_config_matches=''
                break
            fi
        done <<< "$host_config_content"
    fi
else
    echo "creating \"$file\""
    touch "$file"
fi

# exit if the host exists but the config doesn't match our device config file
if [ -f "$file" ] && [ $host_exists ] && [ ! $host_config_matches ] ; then
    echo "config for ${host_identifier} doesn't match!"
    echo "compare ${file} content with \$host_config_content in this setup_proxmox_host.sh"
    echo "exiting..."
    exit 1
fi

# handle adding host to ssh config
if [ ! $host_config_matches ] ; then

    # backup the existing file
    if [ -f "$file" ] ; then

        echo "backing up \"$file\""

        # new file name
        suffix=0

        # determine new file name
        while [ -f "$backup_file" ]; do
            ((suffix++))
            backup_file="${file}.original_${suffix}"
        done

        # copy file
        sudo cp "$file" "$backup_file"
        echo "file copied to $backup_file"
    fi

    # append config
    sudo echo "${host_config_content}" | sudo tee -a "$file" > /dev/null
    echo "host configuration added to config"

    # validate configuration added to file
    host_config_matches=true     
    while IFS= read -r line; do
        if ! grep -Fxqe "$line" "$file"; then
            host_config_matches=''
            break
        fi
    done <<< "$host_config_content"
    if ! $host_config_matches ; then
        echo "failed to add device to configuration, exiting..."
        exit 1
    fi
fi

echo "config for bastion connections created"

#endregion


#region Create SSH Config for Bastion ###

echo "copying keys to bastion and trusting the bastion host"

# trust bastion's fingerprint
if ! ssh-keygen -F ${BASTION_HOST_IP} >/dev/null 2>&1 ; then
    ssh-keyscan -H ${BASTION_HOST_IP} >/dev/null 2>&1 >> ~/.ssh/known_hosts
fi

# copy the keys to bastion
scp ${ssh_keyfile_path} ${BASTION_HOST_IP}:~/.ssh/id_rsa
scp ${ssh_keyfile_path}.pub ${BASTION_HOST_IP}:~/.ssh/id_rsa.pub

echo "connections to bastion should now be trusted"

#endregion

echo -e "\n\n---===   Proxmox Host Setup Completed Successfully   ===---"
