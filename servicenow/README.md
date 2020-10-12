#Build the container
<p>
##You must populate the 'snow_api_auth.json' file under ./files before building
docker build . --build-arg auth="$(cat ./files/snow_api_auth.json)" -t snow_cmdb_api<br>
</p>

#Example of creating a windows server CI in stage snow instance
<p>docker run \<br>
    --rm snow_cmdb_api \<br>
        -e stage \<br>
        -a create \<br>
        -c name=my-server os=windows version=2016 ip=10.1.2.3.4<br>
</p>

#Example of decomming a server CI in prod snow instance
<p>docker run \<br>
    --rm snow_cmdb_api \<br>
        -e prod \<br>
        -a update \<br>
        -c name=my-server status=2<br>
</p>