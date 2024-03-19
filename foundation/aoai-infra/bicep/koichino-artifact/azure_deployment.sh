# Subscritoion ID separated by space
#subscription_ids=("d38281d5-7b5a-XXXXXx" "54b70dbd-f506-XXXXXx" "13cb9335-70e4-XXXXXx")
subscription_ids=("d38281d5-7b5a-XXXXXx")

# Resource Group Name
resource_group_name="bicep-rg"

# Create Resource Group for each subscription
for sub in ${subscription_ids[@]}; do
  az account set --subscription $sub
  az group create --name $resource_group_name --location japaneast
  az deployment group create --resource-group $resource_group_name --template-file aoai.bicep
done
