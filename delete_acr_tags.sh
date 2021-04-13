function delete_act_tags() {
    acr_name=$1s
    subscription_id=$2
    # It supports multiple acr_name with parallelism.
    echo "Save all repo names from ACR $acr_name to $acr_name_delete_acr_target_names"
    az acr repository list --name $acr_name --output table --subscription $subscription_id > $acr_name_delete_acr_target_names.txt

    # Removed the first 2 lines from the original output
    sed -i "1,2d" $acr_name_delete_acr_target_names.txt

    # Create the original copy for recovery purpose
    cp $acr_name_delete_acr_target_names.txt $acr_name_delete_acr_target_names.original

    # Pick up a container name from the $acr_name_delete_acr_target_names.txt file
    while IFS= read -r repoName
    do
        echo "Save all information of ACR repository $repoName to $repoName.txt"
        az acr repository show-tags --name $acr_name --repository $repoName --orderby time_asc -o tsv --detail > $repoName.txt
        # Save all tags and its manifest data in the file.
        echo "Completed the manifest data collection from $repoName.txt file"
        while IFS= read -r line
        do
            timestamp=$(echo $line | cut -d " " -f1)
            manifest=$(echo $line | cut -d " " -f2)
            tag=$(echo $line | cut -d " " -f4)

            # PR image build stays for 30 days. Others 90 days.
            if [[ $tag == *"-PR-"* ]];
            then
                availability=30
            else
                # Keep the else-block for future change if we want to manage the official image build
                continue
            fi
            limitdate=$(date +%Y-%m-%d -d "$availability days ago")
            _timestamp=$(date -d $(echo $timestamp | cut -d 'T' -f 1) +'%Y-%m-%d')

            if [[ $_timestamp < $limitdate ]]; then
                echo The deadline is $limitdate. This tag $tag with $timestamp and $manifest should be removed.
                # Delete the tag of the acr repository
                az acr repository delete --name $acr_name --image $repoName@$manifest --yes
                echo $repoName@$manifest is removed.
            fi
        done < "$repoName.txt"

        # delete the first line after job done
        sed -i "1d" $acr_name_delete_acr_target_names.txt

    done < "$acr_name_delete_acr_target_names.txt"
}

if [ $# -lt 2 ]; then
    echo "Error - missing arguments"
    echo "[Usage]: $0 acr_name subscription_id"
    return 1
fi

delete_act_tags $1 $2
