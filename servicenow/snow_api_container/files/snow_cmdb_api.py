#!/usr/bin/python3.6

#TODO:
# Error + timeout handling - not currently working properly
# Include secrets as run time args in container + update dockerfile to reflect this

import sys
import json
import requests
import argparse
import base64
from base64 import b64encode

class StoreDictKeyPair(argparse.Action):
    def __init__(self, option_strings, dest, nargs=None, **kwargs):
        self._nargs = nargs
        super(StoreDictKeyPair, self).__init__(option_strings, dest, nargs=nargs, **kwargs)
    def __call__(self, parser, namespace, values, option_string=None):
        my_dict = {}
        for kv in values:
            k,v = kv.split("=")
            my_dict[k] = v
        setattr(namespace, self.dest, my_dict)

def get_ci(url, user, passwd, token, key, secret):
    try:
        return requests.get(
            url,
            auth=(user, passwd),
            headers={
                "Proxy-Authorization": "Basic {}".format(token),
                "apikey": key,
                "apikeysecret": secret
            }
        )
    except requests.exceptions.Timeout:
        print('Request timed out. This usually means it still worked but nothing was returned. Continuing.')
        print(e)
    except requests.exceptions.RequestException as e:
        print(e)
        sys.exit(1)


def create_ci(url, user, passwd, token, key, secret, data):
    try:
        return requests.post(
            url,
            auth=(user, passwd),
            headers={
                "Proxy-Authorization": "Basic {}".format(token),
                "apikey": key,
                "apikeysecret": secret,
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            data=data
        )
    except requests.exceptions.Timeout:
        print('Request timed out. This usually means it still worked but nothing was returned. Continuing.')
        print(e)
    except requests.exceptions.RequestException as e:
        print(e)
        sys.exit(1)

def update_ci(url, user, passwd, token, key, secret, data):
    try:
        return requests.put(
            url,
            auth=(user, passwd),
            headers={
                "Proxy-Authorization": "Basic {}".format(token),
                "apikey": key,
                "apikeysecret": secret,
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            data=data
        )
    except requests.exceptions.Timeout:
        print('Request timed out. This usually means it still worked but nothing was returned. Continuing.')
        print(e)
    except requests.exceptions.RequestException as e:
        print(e)
        sys.exit(1)

def delete_ci(url, user, passwd, token, key, secret):
    try:
        return requests.delete(
            url,
            auth=(user, passwd),
            headers={
                "Proxy-Authorization": "Basic {}".format(token),
                "apikey": key,
                "apikeysecret": secret
            }
        )
    except requests.exceptions.Timeout:
        print('Request timed out. This usually means it still worked but nothing was returned. Continuing.')
        print(e)
    except requests.exceptions.RequestException as e:
        print(e)
        sys.exit(1)

def main(envir, action, ci_data):

    #Import the auth file
    with open('snow_data.json') as f:
        auth = json.load(f)

    #Define tokens ready for API calls
    token  = b64encode(b"%b%b%b" % (str.encode(auth[envir]['user']), str.encode(':'), str.encode(auth[envir]['token']))).decode("ascii")
    
    #URL
    server_tn = 'cmdb_ci_server'
    url       = "{}/{}".format(auth[envir]['url'], server_tn)

    if action == 'get':
        if 'name' in ci_data:
            query   = '?sysparm_query=name={}'.format(ci_data['name'])
            get_url = "{}{}".format(url, query)
        elif 'sys_id' in ci_data:
            get_url = "{}/{}".format(url, ci_data['sys_id'])
        
        get_resp = get_ci(get_url, auth['svc']['acct'], auth['svc']['pass'], token, auth[envir]['api_key'], auth[envir]['api_secret'])
        print(get_resp)
        get_json = json.loads(get_resp.text.encode('utf-8'))
        print(json.dumps(get_json, indent=2))

    if action == 'create':
        with open('post.json') as f:
            post_data = json.load(f)

        #Populate JSON object with data from cmd line
        #environment
        post_data['used_for']       = envir
        post_data['classification'] = envir
        
        #name
        post_data['name'] = ci_data['name']
        post_data['fqdn'] = "{}.server.com".format(ci_data['name'])

        #os
        if ci_data['os'] == 'rhel':
            post_data['u_ci_type']      = 'cmdb_ci_linux_server'
            post_data['sys_class_name'] = 'cmdb_ci_linux_server'
            post_data['os_version']     = ci_data['version']
            post_data['os']             = "Redhat"
        elif ci_data['os'] == 'windows':
            post_data['u_ci_type']      = 'cmdb_ci_windows_server'
            post_data['sys_class_name'] = 'cmdb_ci_windows_server'
            post_data['os_version']     = ci_data['version']
            post_data['os']             = "Windows"

        #ip
        post_data['ip_address'] = ci_data['ip']

        #status        
        post_data['operational_status']      = '1'
        post_data['install_status']          = '1'
        post_data['u_existing_asset_status'] = 'In use'

        create_resp = create_ci(url, auth['svc']['acct'], auth['svc']['pass'], token, auth[envir]['api_key'], auth[envir]['api_secret'], json.dumps(post_data))
        print(create_resp)
        create_json = json.loads(create_resp.text.encode('utf-8'))
        print(json.dumps(create_json, indent=2))
        sys_id = create_json['result']['sys_id']
        print(sys_id)

    #TODO: currently only supports updating status field (for decomming a server)
    if action == 'update':
        if 'sys_id' in ci_data:
            update_url = "{}/{}".format(url, ci_data['sys_id'])
        elif 'name' in ci_data:
            query      = '?sysparm_query=name={}'.format(ci_data['name'])
            get_url    = "{}{}".format(url, query)
            get_resp   = get_ci(get_url, auth['svc']['acct'], auth['svc']['pass'], token, auth[envir]['api_key'], auth[envir]['api_secret'])
            get_json   = json.loads(get_resp.text.encode('utf-8'))
            update_url = "{}/{}".format(url, get_json['result'][0]['sys_id'])

        put_data = {}

        #status: 1 = operational, 2 = non operational
        if ci_data['status'] == '1':
            put_data['operational_status']       = '1'
            put_data['install_status']           = '1'
            post_data['u_existing_asset_status'] = 'In use'
        elif ci_data['status'] == '2':
            put_data['operational_status']      = '2'
            put_data['install_status']          = '2'
            put_data['u_existing_asset_status'] = '2'

        update_resp = update_ci(update_url, auth['svc']['acct'], auth['svc']['pass'], token, auth[envir]['api_key'], auth[envir]['api_secret'], json.dumps(put_data))
        print(update_resp)
        update_json = json.loads(update_resp.text.encode('utf-8'))
        #print(json.dumps(update_json, indent=2))
        #print(update_json['result']['operational_status'])

    if action == 'delete':
        if 'sys_id' in ci_data:
            del_url  = "{}/{}".format(url, ci_data['sys_id'])
        elif 'name' in ci_data:
            query    = '?sysparm_query=name={}'.format(ci_data['name'])
            get_url  = "{}{}".format(url, query)
            get_resp = get_ci(get_url, auth['svc']['acct'], auth['svc']['pass'], token, auth[envir]['api_key'], auth[envir]['api_secret'])
            get_json = json.loads(get_resp.text.encode('utf-8'))
            del_url  = "{}/{}".format(url, get_json['result'][0]['sys_id'])
        
        del_resp = delete_ci(del_url, auth['svc']['acct'], auth['svc']['pass'], token, auth[envir]['api_key'], auth[envir]['api_secret'])
        print(del_resp)
        del_json = json.loads(del_resp.text.encode('utf-8'))
        print(json.dumps(del_json, indent=2))

if __name__ == "__main__":
    env_choices    = ['stage', 'prod']
    action_choices = ['get', 'create', 'update', 'delete']
    create_params  = ['name', 'os', 'version', 'ip']

    parser = argparse.ArgumentParser(description='Build CMDB.')
    parser.add_argument('-e', '--environment', dest="envir", required=True,
        help='Environment to perform action on.',
        choices=env_choices)
    parser.add_argument('-a', '--action', dest="action", required=True,
        help='Performs an action on a snow CMDB CI.',
        choices=action_choices)
    parser.add_argument('-c', "--ci-data", dest="ci_data", action=StoreDictKeyPair,
        nargs="+", metavar="KEY=VAL", help='The CI to perform an action on.')
    args = parser.parse_args(sys.argv[1:])

    #name OR sys_id
    if (args.action == 'get' and not 'name' in args.ci_data) and (args.action == 'get' and not 'sys_id' in args.ci_data):
        parser.error("name=value OR sys_id=value required, i.e.: -a get -c name=my-server")
    
    #all elements in list needed
    if args.action == 'create':
        for param in create_params:
            if param not in create_params:
                parser.error("{}=value required".format(param))

    #status AND (name OR sys_id)
    if args.action == 'update':
        if 'status' not in args.ci_data:
            parser.error("status=1 OR status=2 required, i.e.: -a update -c status=2 name=my-server")
        if ('name' not in args.ci_data) and ('sys_id' not in args.ci_data):
            parser.error("name=value OR sys_id=value required, i.e.: -a update -c status=1 name=my-server")

    #name OR sys_id
    if (args.action == 'delete' and not 'name' in args.ci_data) and (args.action == 'delete' and not 'sys_id' in args.ci_data):
        parser.error("name=value OR sys_id=value required, i.e.: -a get -c name=my-server")
    
    main(args.envir, args.action, args.ci_data)
