# Subscritoion ID separated by space
#subscription_ids=("d38281d5-7b5a-4204-8ce6-f30dd97af189" "54b70dbd-f506-448d-b12e-7d05c9f1dda3" "13cb9335-70e4-4eb9-b054-eeb246b9264e")
subscription_ids=("d38281d5-7b5a-4204-8ce6-f30dd97af189")

# Resource Group Name
resource_group_name="bicep-rg"

# Create Resource Group for each subscription
for sub in ${subscription_ids[@]}; do
  az account set --subscription $sub
  az group create --name $resource_group_name --location japaneast
  az deployment group create --resource-group $resource_group_name --template-file aoai.bicep
done