# Need to change target (container registry name) and the subscription
# This is running in az cli, bash prompt or with WSL
function create_sp() {
    sp_name=$1
    subscription_id=$2

    echo "working on $sp_name"
    # role assignment is placed below
    output=$(az ad sp create-for-rbac --name $sp_name --skip-assignment --years 2)
    if [ $? -ne 0 ]; then
        echo -e "\nError creating sp $sp_name. Skipping."
        continue
    else
        echo "\nSuccessfull created sp $sp_name"
        # You will need this app id as service principal
        app_id=$(echo $output | jq -r .appId)
        echo "app id: $app_id"
        # You store this password in key vault secret
        app_pwd=$(echo $output | jq -r .password)
        echo "app password: $app_pwd"
        sp_info=$(az ad sp show --id $app_id)
        echo "sp_info $sp_info"
        dir_id=$(echo $sp_info | jq -r .appOwnerTenantId)
        echo "tenant id: $dir_id"
        obj_id=$(az ad app show --id $app_id | jq -r .objectId)
        echo "obj id: $obj_id"
        cli_id=$(echo $sp_info | jq -r .objectId)
        echo "client id: $cli_id"

        # AcrPull role, static value
        az role assignment create --role "AcrPull" --assignee "$app_id" --subscription "$subscription_id"
        echo $?
    fi
    echo "--------------------------------------------------------------------"
    read -p "Enter "
}

if [ $# -lt 2 ]; then
    echo "Error - missing arguments"
    echo "[Usage]: $0 new_service_principal_display_name(s) subscription_id"
    echo "new_service_principal_display_name(s) could be a list of strings"
    exit 1
fi

target=$1
subscription_id=$2

for sp_name in $target; do
    create_sp $sp_name $subscription_id
done
