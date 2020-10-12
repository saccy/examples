#!/bin/bash

#AWS Key Management Service

#TODO: 
#      ssl verify
#      source the exteral key (the "BYOK")
#      command line args for aws environment, alias, BYOK, wrapping algorithm
#      usage function

error_handler() {
    err_code="$1"
    err_info="$2"
    if [ "$1" != 0 ]; then
        echo "$err_info"
        echo "Exiting with error code: $err_code"
        exit $err_code
    fi
}

create_key_placeholder() {
    aws --no-verify-ssl kms create-key \
        --description "$1" \
        --origin EXTERNAL
    error_handler $? 'key placeholder creation failed'
}

alias() {
    aws --no-verify-ssl kms "${1}-alias" \
        --alias-name "alias/${2}" \
        --target-key-id "$3"
    error_handler $? 'alias creation failed'
}

get_params() {
    aws --no-verify-ssl kms get-parameters-for-import \
        --key-id "$1" \
        --wrapping-algorithm "$2" \
        --wrapping-key-spec "$3"
    error_handler $? 'Failed to fetch import params'
}

import_key() {
    aws --no-verify-ssl kms import-key-material \
        --key-id "$1" \
        --import-token "$2" \
        --encrypted-key-material "$3"
    error_handler $? 'Failed to import key into AWS KMS'
}

#accepted algorithms:
#  RSAES_PKCS1_V1_5
#  RSAES_OAEP_SHA_1
#  RSAES_OAEP_SHA_256

envir=$1
[[ ! -n "$envir" ]] && echo 'provide env' && exit 1
source ./.awscli_keys
alias='ahudson_test_key1'
wrap_alg='RSAES_OAEP_SHA_256'
wrap_spec='RSA_2048'

#Create key and store key-id in a var
key_id=$(create_key_placeholder "$alias" | grep KeyId | cut -d'"' -f4)
echo "Key ID: $key_id"

#Give the key a name
alias 'create' "$alias" "$key_id"

#Fetch import parameters
import_token=$(get_params "$key_id" "$wrap_alg" "$wrap_spec" | grep ImportToken | cut -d'"' -f4)

#Import key into AWS KMS
import_key "$key_id" "$import_token" "$byok"
