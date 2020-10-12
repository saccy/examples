#!/bin/bash

#Check if puppet run lock exists
path='/opt/puppetlabs/puppet/cache/state/agent_catalog_run.lock'

if [ -f $path ]; then
    echo 'waiting'
else
    exit 0
fi
