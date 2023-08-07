# Build the image
```bash
docker build -t quay.io/${USER}/mod_cluster_tomcat .
```

# Run image
**Note the ENV variables:**

* tomcat_port: port on which tomcat will listen (default: 8080)
* tomcat_shutdown_port: port on which tomcat will listen to SHUTDOWN command (default 8005)
* tomcat_ajp_port: port on which AJP will be listener (default: 8009)
* cluster_port: port on which the httpd counterpart listens (default: 6666)
* jvm_route: route name of the tomcat
* tomcat_address: ip address of the tomcat

For example:
```bash
docker run --network=host -e tomcat_ajp_port=8010 -e tomcat_address=127.0.0.15 -e jvm_route=tomcat15 --name tomcat15 quay.io/${USER}/mod_cluster_tomcat
```

then you can uload a webapp into your running instance by executing

```bash
docker cp webapp.war tomcat1:/usr/local/tomcat/webapps/
```