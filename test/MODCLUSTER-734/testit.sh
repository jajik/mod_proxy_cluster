#!/bin/bash

# if ran from main testsuite, change directory
pwd | grep MODCLUSTER-734
if [ $? ]; then
    PREFIX=MODCLUSTER-734
else
    PREFIX="."
fi

. includes/common.sh

clean() {
    tomcat_all_remove
    # clean httpd
    docker stop MODCLUSTER-734
    docker rm MODCLUSTER-734
}


# first stop any previously running tests.
tomcat_all_stop
tomcat_all_remove
httpd_all_clean

# build httpd + mod_proxy_cluster
rm -f nohup.out
MPC_CONF=https://raw.githubusercontent.com/modcluster/mod_proxy_cluster/main/test/MODCLUSTER-734/mod_proxy_cluster.conf MPC_NAME=MODCLUSTER-734 httpd_run

# wait until httpd is started
httpd_wait_until_ready || clean_and_exit

sleep 10

# start tomcat8080 and tomcat8081.
tomcat_start_two

# wait until they are in mod_proxy_cluster tables
tomcat_wait_for_n_nodes 2

# copy the test page in ROOT to tomcat8080
docker cp $PREFIX/ROOT tomcat8080:/usr/local/tomcat/webapps/ROOT
docker cp $PREFIX/ROOT_OK tomcat8081:/usr/local/tomcat/webapps/ROOT

# after a while the health check will get the Under maintenance status.jsp
# and mark the node not OK.
sleep 15
curl -s http://localhost:6666/mod_cluster_manager | grep "Status: NOTOK"
if [ $? -eq 0 ]; then
    echo "MODCLUSTER-734 Done!"
else
    echo "MODCLUSTER-734 Failed!"
    clean
    exit 1
fi

clean