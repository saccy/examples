#!/bin/bash

if [[ $(systemctl status puppet | awk 'NR==3{print $3}' | tr -d '(|)') != 'running' ]]; then
    exit 1
else
    exit 0
fi
