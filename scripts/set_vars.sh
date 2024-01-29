
#region Environment Variables ###

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
export SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export ROOT_DIR=$( abspath "$SCRIPTS_DIR/.." )
export KUBESPRAY_DIR="${ROOT_DIR}/kubespray"
export MODULES_DIR="${ROOT_DIR}/modules"
export SSH_KEY_DIR=$( abspath ~/.ssh)
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

    # handle boolean
    if [ "$value" == 'false' ] ; then
        value=''
    fi

    # set local variables and export them
    export $key="$value"
    # echo "$key=$value"
done < "${ROOT_DIR}/.env"

# verify required environment variables exist
missing_key=''
while read -r key
do
    if [[ $key == \#* ]] || [[ -z $key ]]; then
        continue
    fi

    if ! [[ -v $key ]]; then
        echo "Missing required variable: ${key}"
        missing_key=true
    fi
done < "${ROOT_DIR}/.req_env"

if [ $missing_key ]; then
    echo "Ensure you have supplied all above required variables, exiting..."
    exit 1
fi

#endregion
