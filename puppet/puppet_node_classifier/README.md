## Define puppet agent installation and node classification as a service. ##

In order to use this, you will need an RSA key pair - the public side should be stored on the puppet master and used to decrypt the privately signed signature created by this container. A generic autosigning script will be added later to this repo to facilitate this.

To build: <br>
    docker build . \\ <br>
    -t node_classifier \\ <br>
    --build-arg autosign_key=\<private autosign RSA key\> \\ <br>
    --build-arg windows_auth=\<password\> \\ <br>
    --build-arg linux_auth=\<private SSH key\> <br>

To run: <br>
    docker run \\ <br>
    -it \\ <br>
    --rm \\ <br>
    node_classifier \\ <br>
        -c \<FQDN of new node\> \\ <br>
        -o \<operating system\> \\ <br>
        -u \<user to authenticate as\> \\ <br>
        -i \<IP address of new node\> \\ <br>
        -e \<email address of node owner\> <br>
