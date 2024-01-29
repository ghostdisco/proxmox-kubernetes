#!/bin/bash

#region Environment Variables ###

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPTS_DIR}/set_vars.sh"
if [ $? -ne 0 ] ; then 
    exit 1
fi

#endregion

#region

echo -e "\n\n---===   Terraform Plan Applied Successfully   ===---"
