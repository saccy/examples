FROM centos:latest
LABEL maintainer='a.j.hudson@hotmail.com'
LABEL description="Puppet node classifier" 

#TODO: secure secret handling

#Pre-reqs
RUN yum -y install http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm
RUN yum -y install git which java openssl
RUN yum install -y https://centos7.iuscommunity.org/ius-release.rpm
RUN yum install -y python36u python36u-pip
RUN pip3.6 install --upgrade pip
RUN pip install requests

#Puppet bolt
RUN rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
RUN yum install -y puppet-bolt
RUN mkdir -p /root/.puppetlabs/bolt
ARG windows_auth
RUN echo ${windows_auth} > /root/.puppetlabs/bolt/.windows_auth
ARG linux_auth
RUN echo "${linux_auth}" > /root/.puppetlabs/bolt/.linux_auth

#Node classifier
RUN mkdir -p /opt/node_classifier/bin/windows mkdir -p /opt/node_classifier/bin/linux /opt/node_classifier/key
WORKDIR /opt/node_classifier
COPY files/node_classifier.sh ./bin/node_classifier.sh
COPY files/puppet_api.py ./bin/puppet_api.py
COPY files/puppet_api_functions.py ./bin/puppet_api_functions.py
COPY files/create_signature.sh ./bin/create_signature.sh
COPY files/install_puppet.ps1 /opt/node_classifier/bin/windows/install_puppet.ps1
COPY files/check_lock.ps1 /opt/node_classifier/bin/windows/check_lock.ps1
COPY files/check_reboot.ps1 /opt/node_classifier/bin/windows/check_reboot.ps1
COPY files/install_puppet.sh /opt/node_classifier/bin/linux/install_puppet.sh
COPY files/check_lock.sh /opt/node_classifier/bin/linux/check_lock.sh
COPY files/check_service.sh /opt/node_classifier/bin/linux/check_service.sh
RUN chmod 755 ./bin/node_classifier.sh ./bin/puppet_api.py ./bin/puppet_api_functions.py ./bin/create_signature.sh
ARG autosign_key
RUN echo "${autosign_key}" > ./key/autosign_key

ENTRYPOINT ["/bin/bash", "-c", "/opt/node_classifier/bin/node_classifier.sh ${*}", "--"]
