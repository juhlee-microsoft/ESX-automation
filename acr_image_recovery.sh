
repo_name="$1"
missing_tag="$2"
acr_name="$3"
backup_acr_name="$4"

# expect failure
az acr repository show-tags --name $acr_name --repository $repo_name --orderby time_asc -o tsv --detail | grep $missing_tag
if [ $? ]; then
    echo "verified the image not found in $acr_name"
else
    echo "found the image in $acr_name. Stop here."
    exit 1
fi

# expect success
az acr repository show-tags --name "$backup_acr_name" --repository $repo_name --orderby time_asc -o tsv --detail | grep $missing_tag
if [ !$? ]; then
    echo "found the backup image in $backup_acr_name. Continue recovery process"
else
    echo "Not found the backup image in $backup_acr_name. Can not proceed the recovery"
    exit 1
fi

# pull down that speific tag of the acr repo
docker pull $backup_acr_name.azurecr.io/$repo_name:$missing_tag

# re-tag of the downloaded image
docker tag $backup_acr_name.azurecr.io/$repo_name:$missing_tag $acr_name.azurecr.io/$repo_name:$missing_tag

# push the new image to $acr_name ACR
docker push $acr_name.azurecr.io/$repo_name:$missing_tag

# verify this shows the new result.
az acr repository show-tags --name $acr_name --repository $repo_name --orderby time_asc -o tsv --detail | grep $missing_tag
