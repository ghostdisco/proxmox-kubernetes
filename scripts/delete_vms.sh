#!/bin/bash
vmids=( 101 102 103 104 105 1049 ) # VMIDs of VMs to delete
for vmid in "${vmids[@]}"
do
    status=$(sudo qm status "$vmid")
    if [ "$status" = "status: running" ]; then
      sudo qm stop $vmid
    fi
    sudo qm destroy $vmid
done
