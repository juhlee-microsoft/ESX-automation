# This script verifies the capacity amount of the specific ACR.
# it does not give the warning or error.
function get_acr_capacity() {
    subscription_id="$1"
    resource_group_name="$2"
    acr_name="$3"

    echo "$acr_name" ACR capacity in "$resource_group_name"
    az acr show-usage --resource-group "$resource_group_name" --name "$acr_name" --output table --subscription "$subscription_id"
}

if [ $# -lt 3 ]; then
    echo "Error - missing arguments"
    echo "[Usage]: $0 subscription_id resource_group_name acr_name"
    exit 1
fi

get_acr_capacity "$1" "$2" "$3"