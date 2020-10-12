FROM centos:latest
LABEL maintainer='a.j.hudson@hotmail.com'
LABEL description='API calls to a snow instance'

#Pre-reqs
RUN mkdir -p /opt/snow_cmdb_api
RUN yum install -y https://centos7.iuscommunity.org/ius-release.rpm
RUN yum install -y python36u python36u-pip
RUN pip3.6 install --upgrade pip
RUN pip3.6 install requests

#Scripts
#Template data for POST requests:
COPY files/post.json /opt/snow_cmdb_api/post.json
RUN chmod 644 /opt/snow_cmdb_api/post.json

#Authorisation file (service now tokens, accounts etc.):
ARG snow_data
RUN echo "$snow_data" > /opt/snow_cmdb_api/snow_data.json
RUN chmod 644 /opt/snow_cmdb_api/snow_data.json

#Main script:
COPY files/snow_cmdb_api.py /opt/snow_cmdb_api/snow_cmdb_api.py
RUN chmod 755 /opt/snow_cmdb_api/snow_cmdb_api.py

#When container runs it will enter this dir:
WORKDIR /opt/snow_cmdb_api

#The 'snow_cmdb_api.py' script will execute automatically when the container starts
ENTRYPOINT ["/bin/bash", "-c", "/opt/snow_cmdb_api/snow_cmdb_api.py ${*}", "--"]
