#!/bin/bash

#TODO: slack integration for progress updates

usage() {
    echo "usage: ${0} [-c clientcert] [-o operating system] [-u user] [-i instance ID] [-p IP address] [-e email]"
    echo "  -c <clientcert> The puppet clientcert of the node (usually FQDN)"
    echo "  -i <ip>         IP address of new node"
    echo "  -o <os>         Operating System of node [windows|linux]"
    echo "  -u <user>       User to authenticate as"
    echo "  -e <email>      Email address of owner"
    echo "  -h <help>       Display this message"
    echo "example: ${0} -c server.domain.com -o windows -u john -i 10.142.1.1 -e john.smith@email.com"
    exit 1
}

error_handler() {
    local _RC=$1
    local _msg="$2"
    if [ $_RC != 0 ]; then
        >&2 echo "Error encountered: $_msg"
        exit $_RC
    fi
}

#Builds bolt inventory file (defines defaults when connecting to nodes)
bolt_inv() {
    local os=$1
    local ip=$2
    local user=$3
    local node_auth=$4
    local bolt_inv_file='/root/.puppetlabs/bolt/inventory.yaml'
    echo 'groups:' > $bolt_inv_file
    echo "  - name: $bolt_group
    nodes:" >> $bolt_inv_file
    echo "      - $ip" >> $bolt_inv_file
    if [ "$os" == 'windows' ]; then
      echo "    config:
      transport: winrm
      winrm:
        ssl: false
        #cacert: '/path/to/cert'
        connect-timeout: 60
        user: $user
        password: $(cat $node_auth)" >> $bolt_inv_file
    elif [ "$os" == 'linux' ]; then
      echo "    config:
      transport: ssh
      ssh:
        host-key-check: false
        connect-timeout: 60
        user: $user
        run-as: root
        private-key: $node_auth" >> $bolt_inv_file
    fi
}

lock_check() {
    #Check if puppet running
    while [ $(bolt script run $check_lock -n $bolt_group | grep STDOUT -A1 | grep -v STDOUT | awk '{print $1}') == 'waiting' ]; do
        error_handler $? "Error when checking if puppet lock is in place on $clientcert"
        echo 'Waiting for puppet run to finish'
        sleep 30
    done
}

restart_vm() {
    #TODO: add a timeout
    echo "Rebooting $clientcert"
    case $os in
        'windows')
            bolt command run "Restart-Computer -f" -n $bolt_group > /dev/null 2>&1
            sleep 60
            while ! bolt command run "Write-Host 'Hello, World!'" -n $bolt_group > /dev/null 2>&1; do
                echo "Waiting for $clientcert to reboot"
                sleep 30
            done
            ;;
        'linux')
            bolt command run 'sudo reboot' -n $bolt_group > /dev/null 2>&1
            sleep 20
            while ! bolt command run "echo 'Hello, World!'" -n $bolt_group > /dev/null 2>&1; do
                echo "Waiting for $clientcert to reboot"
                sleep 20
            done
            ;;
    esac
}

#Main
while getopts "c:i:o:u:e:h" opt; do
    case $opt in
        'c')
            clientcert="$OPTARG"
            ;;
        'i')
            ip="$OPTARG"
            ;;
        'o')
            os="$OPTARG"
            ;;
        'u')
            user="$OPTARG"
            ;;
        'e')
            email="$OPTARG"
            ;;
        'h')
            usage
            ;;
        *)
            echo "Invalid flag: \"-${OPTARG}\"" >&2
            usage
            ;;
    esac
done

owner="$(echo $email | cut -d'@' -f1 | sed 's/\./ /g')"
app_dir='/opt/node_classifier'
bolt_group='node'
csr_attributes="$(${app_dir}/bin/create_signature.sh $clientcert)"
timestamp=$(echo "$csr_attributes" | grep creation_time | awk '{print $2}')
signature=$(echo "$csr_attributes" | grep signature | awk '{print $2}')
node_auth="/root/.puppetlabs/bolt/.${os}_auth"

echo
echo 'Building puppet bolt inventory file'
bolt_inv $os $ip $user $node_auth
echo

if ! bolt command run "echo 'Hello, World!'" -n $bolt_group > /dev/null 2>&1; then
    error_handler 1 "Unable to connect/authenticate to $clientcert"
fi

case $os in
    'windows')
        install_script="${app_dir}/bin/windows/install_puppet.ps1"
        check_lock="${app_dir}/bin/windows/check_lock.ps1"
        puppet='puppet'
        ;;
    'linux')
        install_script="${app_dir}/bin/linux/install_puppet.sh"
        check_lock="${app_dir}/bin/linux/check_lock.sh"
        puppet='sudo /opt/puppetlabs/bin/puppet'
        
        echo "Setting correct hostname on linux node $clientcert"
        echo
        bolt command run "hostnamectl set-hostname $clientcert" -n $bolt_group  > /dev/null 2>&1
        error_handler $? 'Unable to set hostname on VM'
        bolt_opts='--tty'
        ;;
    *)
        error_handler 1 "os not supported: $os"
        ;;
esac

#Inject puppet facts into install script
sed -i "s~\${sig}~'$signature'~g" $install_script
sed -i "s~\${ts}~'$timestamp'~g" $install_script
sed -i "s~\${clientcert}~'$clientcert'~g" $install_script

echo "Installing puppet on $clientcert"
bolt script run $install_script -n $bolt_group $bolt_opts > /dev/null 2>&1
RC=$?
if [ "$os" == 'windows' ]; then
    error_handler $RC 'puppet did not install correctly'
fi
echo

if [[ "$os" == 'linux' ]]; then
    echo "Ensuring puppet service is running"
    bolt command run "systemctl start puppet" -n $bolt_group > /dev/null 2>&1
    bolt script run ${app_dir}/bin/linux/check_service.sh -n $bolt_group > /dev/null 2>&1
    error_handler $? 'Puppet is not running - installation error'
    echo
fi

#Wait for initial auto sign run to finish
lock_check
echo

echo "Classifiying $clientcert on the puppet master"
${app_dir}/bin/puppet_api.py --group $os --node $clientcert > /dev/null 2>&1
error_handler $? 'API call to puppet master failed'
echo

#Reboot needed for binary/executable to be added to path
restart_vm
echo
lock_check
echo

#TODO: local admin is not able to RDP after AD is setup - fix that
#      flying blind after last reboot
echo "Running puppet on $clientcert and applying configuration"
bolt command run "$puppet agent -t" -n $bolt_group $bolt_opts > /dev/null 2>&1
rc=$?
echo
if [ $rc != 0 ] && [ $os == 'windows' ]; then
    restart_vm
    #lock_check
    #echo
    #echo "Running puppet on $clientcert and applying configuration for the second time"
    #restart_vm
else
    error_handler $rc 'Puppet run did not complete successfully'
fi

echo 'Classification completed successfully'
exit 0

#TODO: notify owner
