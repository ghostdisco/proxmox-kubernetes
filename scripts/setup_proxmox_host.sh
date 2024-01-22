#!/bin/bash


SSH_KEYFILE_NAME=fcc
VM_TEMPLATE_NAME=ubuntu-2204
VM_TEMPLATE_ID=9000
BASTION_HOST_NAME=bastion
BASTION_HOST_ID=1049
BASTION_HOST_IP="172.16.0.49"
LAN_GW="172.16.0.1"


#todo: add check for user to exit early if not running on proxmox server host


#region Environment Variables ##

# resolve a relative path to absolute
function abspath {
    if [[ -d "$1" ]]
    then
        pushd "$1" >/dev/null
        pwd
        popd >/dev/null
    elif [[ -e "$1" ]]
    then
        pushd "$(dirname "$1")" >/dev/null
        echo "$(pwd)/$(basename "$1")"
        popd >/dev/null
    else
        echo "$1" does not exist! >&2
        return 127
    fi
}

# set directories
SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$( abspath "$SCRIPTS_DIR/.." )
KUBESPRAY_DIR="${ROOT_DIR}/kubespray"
MODULES_DIR="${ROOT_DIR}/modules"
echo "ROOT_DIR=${ROOT_DIR}"

# set environment arguments
while IFS='=' read -r key value
do
    # skip lines that start with #
    if [[ $key == \#* ]]; then
        continue
    fi

    # trim leading and trailing whitespace
    key=$(echo $key | xargs)
    value=$(echo $value | xargs)

    # set local variables and export them
    export $key="$value"
    # echo "$key=$value"
done < "${ROOT_DIR}/.env"

# verify required environment variables exist
missing_key=''
while read -r key
do
    if [[ $key == \#* ]]; then
        continue
    fi

    if [ -z "${!key}" ]; then
        echo "Missing required variable: ${key}"
        missing_key=true
    fi
done < "${ROOT_DIR}/.req_env"

if [ $missing_key ]; then
    echo "Ensure you have supplied all above required variables, exiting..."
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
sudo apt install -qqy curl

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
    if grep -Fxq $device_name $file ; then
        device_exists='true'
        if grep -Fxqf "$device_config_file" $file ; then
            device_config_matches='true'
        fi
    fi
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
    sudo cat "${device_config_file}" >> $file
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

#endregion


#region Prepare VM Template

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
if ! qm_item_exists $VM_TEMPLATE_NAME $VM_TEMPLATE_ID || $FORCE_TEMPLATE_CREATION ; then

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

#endregion


#region Generate SSH Key Pair

# generate key if needed
ssh_keyfile_path="~/.ssh/${SSH_KEYFILE_NAME}"
if [ ! -f "${ssh_keyfile_path}" ] ; then
    ssh-keygen -t rsa -b 4096 -f "${ssh_keyfile_path}" -C "k8s-admin@cluster.local" -p ""
fi
if [ ! -f "${ssh_keyfile_path}" ] ; then
    echo "failed to generate ssh keys, exiting..."
fi

#endregion


#region Setup Bastion Host

function test_ssh_to_bastion {
    timeout=120
    start_time=$(date +%s)

    while true; do
        ssh -o BatchMode=yes -i "${ssh_keyfile_path}" -n -q "ubuntu@$BASTION_HOST_IP" exit
        exit_status=$?

        # check status
        if [ $exit_status -eq 0 ]; then
            echo "ssh connection to $BASTION_HOST_IP successful"
            return $exit_status
        fi

        # check timeout
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -ge $timeout ]; then
            echo "timed out testing sshconnection to $BASTION_HOST_IP"
            return $exit_status
        fi

        sleep 5
    done
}


# only create if vm doesn't exist
if ! qm_item_exists $VM_TEMPLATE_NAME $VM_TEMPLATE_ID ; then

    # clone template
    sudo qm clone $VM_TEMPLATE_ID $BASTION_HOST_ID --name $BASTION_HOST_NAME --full true
    if ! qm_item_exists $VM_TEMPLATE_NAME $VM_TEMPLATE_ID ; then
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
    if ! test_ssh_to_bastion ; then
        echo "failed to reach bastion host, exiting..."
        exit 1
    fi
fi

#endregion
