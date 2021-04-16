#!/bin/bash
# This script needs to docker login in advance.

#set -euo pipefail

if [ $# -lt 4 ]; then
    echo "Error - missing arguments"
    echo "[Usage]: $0 acr_repo_name missing_tag acr_name backup_acr_name"
    exit 1
fi

repo_name="$1"
missing_tag="$2"
acr_name="$3"
backup_acr_name="$4"

# expect failure
ret=$(az acr repository show-tags --name $acr_name --repository $repo_name --orderby time_asc -o tsv --detail | grep $missing_tag)

if [[ -z "$ret" ]]; then
    echo "Verified that the image is missing in $acr_name. Proceed the recovery process."
else
    echo "Found the image in $acr_name. Stop here."
    echo $ret
    exit 1
fi

# expect success
ret=$(az acr repository show-tags --name "$backup_acr_name" --repository $repo_name --orderby time_asc -o tsv --detail | grep $missing_tag)
if [[ $ret ]]; then
    echo "Found the backup image in $backup_acr_name. Continue the recovery process."
    echo $ret
else
    echo "Not found the backup image in $backup_acr_name. Can not proceed the recovery"
    exit 1
fi

# pull down that speific tag of the acr repo
docker pull $backup_acr_name.azurecr.io/$repo_name:$missing_tag
echo "Pulled down the image from $backup_acr_name"

# re-tag of the downloaded image
docker tag $backup_acr_name.azurecr.io/$repo_name:$missing_tag $acr_name.azurecr.io/$repo_name:$missing_tag
echo "Re-tag it in $acr_name"

# push the new image to $acr_name ACR
docker push $acr_name.azurecr.io/$repo_name:$missing_tag
echo "Pushged the new tag to $acr_name"

# verify this shows the new result.
$ret=$(az acr repository show-tags --name $acr_name --repository $repo_name --orderby time_asc -o tsv --detail | grep $missing_tag)

if [[ $ret ]]; then
    echo "Verified that the new image in $acr_name successfully. Recovery successful."
    echo $ret
else
    echo "Not found the image still. Recovery failed."
    exit 1
fi