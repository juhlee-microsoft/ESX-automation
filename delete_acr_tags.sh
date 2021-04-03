function delete_act_tags() {

    if [ $# -lt 2 ]; then
        echo "Error - missing arguments"
        echo "[Usage]: $0 acr_name subscription_id"
        return 1
    fi
    acr_name=$1s
    subscription_id=$2
    # It supports multiple acr_name with parallelism.
    az acr repository list --name $acr_name --output table --subscription $subscription_id > $acr_name_delete_acr_target_names.txt

    # Removed the first 2 lines from the original output
    sed -i "1,2d" $acr_name_delete_acr_target_names.txt

    # Create the original copy for recovery purpose
    cp $acr_name_delete_acr_target_names.txt $acr_name_delete_acr_target_names.original

    # Pick up a container name from the $acr_name_delete_acr_target_names.txt file
    while IFS= read -r repoName
    do
        echo "ACR repository name: $repoName"
        az acr repository show-manifests --name $acr_name --repository $repoName --orderby time_asc -o tsv --query "[?timestamp < '2021-01-01'].[digest]" > $repoName.txt
        echo "Completed the menifest data collection from $repoName.txt file"
        while IFS= read -r tagline
        do
            # Delete the tag of the acr repository
            az acr repository delete --name $acr_name --image $repoName@$tagline --yes
            echo $tagline is removed from $repoName
        done < "$repoName.txt"
        # delete the first line after job done
        sed -i "1d" $acr_name_delete_acr_target_names.txt

    done < "$acr_name_delete_acr_target_names.txt"
}

delete_act_tags $1 $2
#delete_act_tags "skylinkintacr" "851bc778-eff0-4350-96bd-62f3c6363e55"
