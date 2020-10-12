#!/bin/bash

#Generic/standard az cli functions. Can be sourced within other scripts by:
# source ./function_library
#and utilised the same as a local function:
# check_rg MyRG

#TODO: add error handling (delte_vm function is an example)
#      login using service principal

#Check if we are logged in
check_session() {
    if ! az identity list &>/dev/null; then
        error_handler 1 'You need to login to az cli first: $ az login'
    else
        echo 'Login session is valid'
    fi
}

check_rg() {
    local res_grp="$1"
    az group exists \
        -n $res_grp
}

check_as() {
    local res_grp="$1"
    local as="$2"

    az vm availability-set show \
        --resource-group $res_grp \
        --name $as | \
        jq -r ."name"
}

check_lb() {
    local res_grp="$1"
    local lb="$2"

    az network lb show \
        --resource-group $res_grp \
        --name $lb | \
        jq -r ."provisioningState"
}

check_vnet() {
    local res_grp="$1"
    local vnet="$2"

    az network vnet show \
        -g $res_grp \
        -n $vnet | \
        jq -r ."provisioningState"
}

check_subnet() {
    local res_grp="$1"
    local vnet="$2"
    local subnet="$3"

    az network vnet subnet show \
        --resource-group $res_grp \
        --vnet-name $vnet \
        --name $subnet | \
        jq -r ."provisioningState"
}

error_handler() {
    local RC=$1
    local msg="$2"
    if [ $RC != 0 ]; then
        echo "Error encountered: $msg"
        exit $RC
    fi
}

create_rg() {
    local loc="$1"
    local res_grp="$2"
    local -n tags="$3"

    az group create \
        --location $loc \
        --name $res_grp \
        --tags $(echo "${tags[@]}")
}

create_vnet() {
    local res_grp="$1"
    local vnet="$2"
    local addr_pre="$3"
    local -n tags="$4"

    az network vnet create \
        -g $res_grp \
        -n $vnet \
        --address-prefix $addr_pre \
        --tags $(echo "${tags[@]}")
        #--address-prefix 10.0.0.0/16
}

create_subnet() {
    local res_grp="$1"
    local vnet="$2"
    local addr_pre="$3"
    local subnet="$4"

    az network vnet subnet create \
        -g $res_grp \
        --vnet-name $vnet \
        --address-prefix $addr_pre \
        -n $subnet
}

#Create an availability set
create_as() {
    local res_grp="$1"
    local as="$2"
    local -n tags="$3"

    az vm availability-set create \
        --resource-group $res_grp \
        --name $as \
        --tags $(echo "${tags[@]}")
}

#Create a load balancer
create_lb() {
    local res_grp="$1"
    local lb="$2"
    local subnet="$3"
    local be_pool="$4"
    local -n tags="$5"

    az network lb create \
        --resource-group $res_grp \
        --name $lb \
        --subnet $subnet \
        --backend-pool-name $be_pool \
        --tags $(echo "${tags[@]}") \
        --public-ip-address ""
}

create_vm () {
    local res_grp="$1"
    local vm_name="$2"
    local vm_user="$3"
    local vm_img="$4"
    local vm_size="$5"
    local avail_set="$6"
    local vnet="$7"
    local subnet="$8"
    local ssh_pub="$9"
    local -n tags="${10}"

    az vm create --resource-group "$res_grp" \
        --name "$vm_name" \
        --admin-username "$vm_user" \
        --image "$vm_img" \
        --size "$vm_size" \
        --availability-set $avail_set \
        --vnet-name "$vnet" \
        --subnet "$subnet" \
        --ssh-key-value "$ssh_pub" \
        --tags $(echo "${tags[@]}") \
        --public-ip-address ""
}

#Create a storage account
create_strg_account() {
    local name="$1"
    local res_grp="$2"
    local sku="$3"
    local asc="$4"
    local asck="$5"

    export AZURE_STORAGE_ACCOUNT="$asc"
    export AZURE_STORAGE_ACCESS_KEY="$asck"

    az storage account create \
        --name $name \
        --resource-group $res_grp \
        --sku $sku \
        --kind StorageV2 \
        --encryption blob
}

#Create a storage container
create_strg_cont() {
    local cont_name="$1"

    az storage container create --name $cont_name
}

#Upload file to blob inside container
#TODO: automate key upload??
upload_blob() {
    local file_name="$1"
    local cont_name="$2"
    local blob_name="$3"
    
    az storage blob upload \
        --file $file_name \
        --container-name $cont_name \
        --name $blob_name
}

#Encrypts a VM's disks
encrypt_vm() {
    local res_grp="$1"
    local keyvault_name="$2"
    local vm_name="$3"
    local key="$4"
    local sp_id="$5"
    local sp_pass="$6"
    local vol_type="$7"

    az keyvault set-policy --name $keyvault_name --spn $sp_id \
        --key-permissions wrapKey \
        --secret-permissions set

    az vm encryption enable \
        --resource-group $res_grp \
        --name $vm_name \
        --aad-client-id $sp_id \
        --aad-client-secret $sp_pass \
        --disk-encryption-keyvault $keyvault_name \
        --key-encryption-key $key \
        --volume-type $vol_type
}

#Show encryption status of a VM
get_encrypt() {
    local res_grp="$1"
    local name="2"

    az vm encryption show \
        --resource-group $res_grp \
        --name $name
}

#Get vnet details
get_vnet(){
    local res_grp="$1"
    local vnet="$2"

    az network vnet show \
        --resource-group $res_grp \
        --name $vnet
}

#Get subnet details
get_subnet(){
    res_grp="$1"
    vnet="$2"
    subnet="$3"

    az network vnet subnet show \
        --resource-group $res_grp \
        --vnet-name $vnet \
        --name $subnet
}

#Resizes a VM
#TODO: test if size is available in region
resize_vm() {
    local res_grp="$1"
    local vm_name="$2"
    local size="$3"

    az vm resize \
        -g $res_grp \
        -n $vm_name \
        --size $size
}

#Add a disk to a VM
add_disk() {
    local res_grp="$1"
    local vm_name="$2"
    local disk_size="$3"

    az vm disk attach \
        -g $res_grp \
        --vm-name $vm_name \
        --disk "${vm_name}_data_disk" \
        --size-gb $disk_size \
        --new
}

delete_vm() {
    local res_grp="$1"
    local vm_name="$2"

    if [ "${#res_grp}" -lt 1 ]; then
        echo 'Please provide a resource group'
        echo 'Existing groups:'
        az group list | jq 'to_entries[] | .value.name' | tr -d \"
        exit 1
    fi

    if [ "${#vm_name}" -lt 1 ]; then
        echo 'Please provide a VM to delete'
        echo 'Existing VMs:'
        az vm list -g $res_grp | grep -wP '\s{4}"name"' | head -1 | cut -d \" -f4
        exit 1
    fi

    local res_grp_state=$(check_rg $res_grp)

    if [ "$res_grp_state" != 'Succeeded' ]; then
        error_handler 1 "Resource group not ready: $res_grp"
    fi

    az vm delete \
        -g $res_grp \
        -n $vm_name \
        -y
}

delete_rg() {
    local name="$1"
    az group delete \
        --name $name \
        --yes
}

#TODO: delete nic, nsg, disks, set subscription reminders etc.
