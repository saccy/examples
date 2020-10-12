#!/bin/bash

error_handler() {
    local RC=$1
    local msg="$2"
    if [ $RC != 0 ]; then
        echo "Error encountered: $msg"
        exit $RC
    fi
}

if [ ${#1} -eq 0 ]; then
    error_handler 1 'no arg provided, exiting'
fi

if [ ! -d /tmp/csr_attr ]; then
    mkdir /tmp/csr_attr
fi

clientcert=$1
base64_sig='/tmp/csr_attr/base64_sig'
binary_sig='/tmp/csr_attr/binary_sig'
prv_key='/opt/node_classifier/key/autosign_key'
file2sign='/tmp/csr_attr/signme'
time=$(date +%s)

echo $clientcert > $file2sign
echo $time >> $file2sign

if [ ! -f $prv_key ]; then
    error_handler 1 "Private key not found: $prv_key"
fi

#echo 'Generating file signature in binary'
openssl dgst -sha256 -sign $prv_key -out $binary_sig $file2sign

#echo 'Encoding binary signature in base64'
openssl base64 -in $binary_sig -out $base64_sig

echo "creation_time: $time"
echo "signature: $(cat $base64_sig | tr -d '\n')"

rm -f /tmp/csr_attr/*
