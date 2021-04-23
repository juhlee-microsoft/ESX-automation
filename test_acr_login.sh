# new service princal name should have AcrPull role in the ACR.
new_service_principal_name="$1"
new_service_principal_password="$2"
acr_name="$3"
testing_repo="$4"
testing_tag="$5"
invalid_tag="noway"

# clean out the cached credential in the previous login
docker logout
if [ $? ]; then
    echo "logout successful"
else
    echo "logout failed"
    exit 1
fi

# login with the user name and password. The user name is the service principal
docker login --username $new_service_principal_name --password $new_service_principal_password $acr_name.azurecr.io
if [ $? ]; then
    echo "login successful"
else
    echo "login failed"
    exit 1
fi

# ACR pull the testing repo/tag
docker pull $acr_name.azurecr.io/$testing_repo:$testing_tag
if [ $? ]; then
    echo "login successful"
else
    echo "login failed"
    exit 1
fi

docker tag $acr_name.azurecr.io/$testing_repo:$testing_tag $acr_name.azurecr.io/$testing_repo:$invalid_tag
echo "Changed the tag from $testing_tag to $invalid_tag"

docker push $acr_name.azurecr.io/$testing_repo:$invalid_tag
if [ !$? ]; then
    echo "ACR push failed as expected. TEST PASSED"
else
    echo "ACR push successful. TEST FAILED"
    exit 1
fi

test_image_id=$(docker images $acr_name.azurecr.io/$testing_repo:$testing_tag -q)
docker rmi $test_image_id --force

docker images