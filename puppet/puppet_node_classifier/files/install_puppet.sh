#!/bin/bash
#timestamp and signature will be inserted by node_classifier.sh script

ip='<your puppet master IP/hostname>'
port='8140'

wget https://${ip}:${port}/packages/current/install.bash --no-check-certificate -O /tmp/install.bash
bash /tmp/install.bash \
    custom_attributes:1.3.6.1.4.1.34380.1.1.100=${ts} \
    custom_attributes:1.3.6.1.4.1.34380.1.1.101=${sig} \
    main:certname=${clientcert}
