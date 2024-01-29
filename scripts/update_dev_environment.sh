#!/bin/bash

#region Environment Variables ###

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPTS_DIR}/set_vars.sh"
if [ $? -ne 0 ] ; then 
    exit 1
fi

#endregion


#region Copy Down Bastion Info From Proxmox

if [ ! -f ~/.ssh/bastion ] ; then
    scp "${PROXMOX_HOST_USER}@${PROXMOX_HOST_IP}:/home/${PROXMOX_HOST_USER}/.ssh/${SSH_KEYFILE_NAME}" ~/.ssh/bastion
    scp "${PROXMOX_HOST_USER}@${PROXMOX_HOST_IP}:/home/${PROXMOX_HOST_USER}/.ssh/${SSH_KEYFILE_NAME}.pub" ~/.ssh/bastion.pub
fi


#endregion

echo -e "\n\n---===   Dev Environment Update Completed Successfully   ===---"
