#!/bin/bash

#region Environment Variables ###

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPTS_DIR}/set_vars.sh"
if [ $? -ne 0 ] ; then 
    exit 1
fi

#endregion


#region Copy SSH Config From Proxmox ###

echo "setup config for connections to bastion"

# copy down ssh keys and config for bastion from proxmox
bastion_keyfile_path="/home/${USER}/.ssh/bastion"
if [ ! -f "${bastion_keyfile_path}" ] ; then
    scp "${PROXMOX_HOST_USER}@${PROXMOX_HOST_IP}:/home/${PROXMOX_HOST_USER}/.ssh/${SSH_KEYFILE_NAME}" "$bastion_keyfile_path"
    scp "${PROXMOX_HOST_USER}@${PROXMOX_HOST_IP}:/home/${PROXMOX_HOST_USER}/.ssh/${SSH_KEYFILE_NAME}.pub" "${bastion_keyfile_path}.pub"
fi

# check if bastion host exists in proxmox's ssh config
file="/home/${USER}/.ssh/config"
backup_file="${file}.original_0"
host_config_content="#BASTION
Host ${BASTION_HOST_IP}
   HostName ${BASTION_HOST_IP}
   PreferredAuthentications publickey
   User ${BASTION_USERNAME}
   IdentityFile ${bastion_keyfile_path}"
host_identifier="Host ${BASTION_HOST_IP}"
host_exists=''
host_config_matches=''

echo "$host_config_content" > /home/${USER}/.ssh/bastion_config

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

# trust bastion's fingerprint
if ! ssh-keygen -F ${BASTION_HOST_IP} >/dev/null 2>&1 ; then
    ssh-keyscan -H ${BASTION_HOST_IP} >/dev/null 2>&1 >> ~/.ssh/known_hosts
fi

echo "config for bastion connections created"

#endregion


#region Update SSH Key Values in .env ###

base64_encoded_public_key=$(base64 -w 0 "${bastion_keyfile_path}.pub")
base64_encoded_private_key=$(base64 -w 0 "${bastion_keyfile_path}")

sed -i "s/^TF_VAR_ssh_public_keys.*/TF_VAR_ssh_public_keys=\"${base64_encoded_public_key}\"/" "${ROOT_DIR}/.env"
sed -i "s/^TF_VAR_ssh_private_key.*/TF_VAR_ssh_private_key=\"${base64_encoded_private_key}\"/" "${ROOT_DIR}/.env"

#endregion

echo -e "\n\n---===   Dev Environment Update Completed Successfully   ===---\n"
