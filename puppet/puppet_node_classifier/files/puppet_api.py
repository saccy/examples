#!/usr/bin/python3.6

#a.j.hudson@hotmail.com v0.0.1

import sys
import json
import time
import argparse
from puppet_api_functions import *
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

#Parse command line args
parser = argparse.ArgumentParser(description='Classify a new machine.')
parser.add_argument('--node', dest="node", required=True,
    help='Puppet clientcert (usually the FQDN of the new node')
parser.add_argument('--group', dest="group", required=True,
    help='The group that the node will be assigned to')

args  = parser.parse_args()
node  = args.node
group = args.group

def main():
    #Get info on currently available groups
    groups_resp = get_nc('groups')
    groups      = json.loads(groups_resp.text)
    groups_len  = len(groups)

    #Find the correct group ID
    for i in range(0, groups_len):
        if groups[i]['name'] == group:
            group_id = groups[i]['id']

    #JSON data to be sent in API request
    node_data = {
        'nodes': [
            node
        ]
    }

    #Classify the node
    try:
        node_resp = post_nc('groups/' + group_id + '/pin', node_data)
    except:
        sys.exit('HTTP error when posting classification for ' + node)

    #Check if node is registered in DB
    try:
        db_status = get_db(node)
    except:
        sys.exit('HTTP error when retrieving DB status for ' + node)

    attempt = 0
    while 'error' in json.loads(db_status.text):
        print('Waiting for node to register with puppet DB')
        time.sleep(20)
        attempt += 1
        if attempt == 5:
            sys.exit('Error registering node with puppet DB (timeout after 1 minute): ' + json.loads(db_status.text)["error"])

if __name__== "__main__":
    main()
