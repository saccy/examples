#!/usr/bin/python3.6

#TODO: move imports and vars to main script

import requests

url   = '<your puppet master URL>'
token = '<your puppet token>'

#Send GET request to puppet DB API
def get_db(node):
    resp = requests.get(
        url + ':8081/pdb/query/v4/nodes/' + node,
        headers={'X-Authentication': token},
        verify=False
    )
    return resp

#Send GET request to puppet CA API
def get_ca(node):
    resp = requests.get(
        url + ':8140/puppet-ca/v1/certificate_status/' + node,
        verify=False
    )
    return resp

#Send GET request to puppet node classifier (nc) API
def get_nc(endpoint):
    resp = requests.get(
        url + ':4433/classifier-api/v1/' + endpoint,
        headers={'X-Authentication': token},
        verify=False
    )
    return resp

#Send POST request to puppet node classifier (nc) API
def post_nc(endpoint, data):
    resp = requests.post(
        url + ':4433/classifier-api/v1/' + endpoint,
        headers={'X-Authentication': token},
        json=data,
        verify=False
    )
    return resp
