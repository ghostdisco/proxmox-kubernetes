#!/bin/bash



#todo: add check for user to exit early if not running on proxmox server host


#region Set Paths ##

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

#endregion


#region Configure Internal Network ###

file="/etc/network/interfaces"
backup_file="${file}.original_0"
device_config_file="${SCRIPTS_DIR}/files/interfaces.part"
device_name='vmbr1'
device_exists=false
device_config_matches=false

# determine if current configuration is desired
if [ -f "$file" ] ; then
    if grep -Fxq $device_name $file ; then
        device_exists=true
        if grep -Fxqf "$device_config_file" $file ; then
            device_config_matches=true
        fi
    fi
fi

# exit if the device exists but the config doesn't match our device config file
if [ -f "$file" && $device_exists && ! $device_config_matches ] ; then
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

# download script


#endregion


#region Generate SSH Key Pair

#endregion


#region Setup Bastion Host

#endregion
