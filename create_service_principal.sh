# Need to change target (container registry name) and the subscription
# This is running in az cli, bash prompt or with WSL
target="your service principal display name"
subscription_id="your Azure subscription"

for sp_name in $target; do
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
done