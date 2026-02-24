#!/usr/bin/sh
# exits with 0 if everything went well
# exits with 1 if some test failed
# exits with 2 if httpd container build failed
# exits with 3 if tomcat container build failed

# configuration of variables
# if you want tests to pass much faster, decrease these values
if [ -z ${FOREVER_PAUSE+x} ]; then
    export FOREVER_PAUSE=3600 # sleep period length during which tomcats are run & stopped
fi
if [ -z ${TOMCAT_CYCLE_COUNT+x} ]; then
    export TOMCAT_CYCLE_COUNT=100 # the number of repetitions of a test cycle
fi
if [ -z ${ITERATION_COUNT+x} ]; then
    export ITERATION_COUNT=50 # the number of iteration of starting/stopping a tomcat
fi
if [ -z ${IMG+x} ]; then
    export IMG=mod_proxy_cluster-testsuite-tomcat
fi
if [ -z ${HTTPD_IMG+x} ]; then
    export HTTPD_IMG=mod_proxy_cluster-testsuite-httpd
fi

echo "Test parameters are:"
echo "        FOREVER_PAUSE=$FOREVER_PAUSE"
echo "        TOMCAT_CYCLE_COUNT=$TOMCAT_CYCLE_COUNT"
echo "        ITERATION_COUNT=$ITERATION_COUNT"
echo "        IMG=$IMG"
echo "        HTTPD_IMG=$HTTPD_IMG"
if [ ! -z ${MPC_CONF+x} ]; then
    echo "        MPC_CONF=$MPC_CONF"
fi

if [ ! -d logs ]; then
    mkdir logs
fi

. includes/common.sh

if [ ! -d tomcat/target ]; then
    echo "Missing dependencies. Please run setup-dependencies.sh and then try again"
    exit 4 
fi

echo -n "Creating docker containers..."
if [ ! -z ${DEBUG+x} ]; then
     httpd_create  || exit 2
     tomcat_create || exit 3
else
     httpd_create  > /dev/null 2>&1 || exit 2
     tomcat_create > /dev/null 2>&1 || exit 3
fi
echo " Done"

# clean everything at first
echo -n "Cleaning possibly running containers..."
httpd_remove   > /dev/null 2>&1
tomcat_all_remove > /dev/null 2>&1
echo " Done"

res=0

# IMG name might include specific version, we have to handle that
IMG_NOVER=$(echo $IMG | cut -d: -f1)

while [ "$res" -eq 0 ]; do
    run_test MODCLUSTER-736/testit.sh   "MODCLUSTER-736"
    res=$(expr $res + $?)
done;

echo -n "Cleaning containers if any..."
httpd_remove   > /dev/null 2>&1
tomcat_all_remove > /dev/null 2>&1
echo " Done" 

if [ $res -eq 0 ]; then
    echo "Tests finished successfully!"
else
    echo "Tests finished, but some failed."
    res=1
fi

exit $res
