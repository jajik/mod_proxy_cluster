#!/usr/bin/sh

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

if [ ! -d logs ]; then
    mkdir logs
fi

. includes/common.sh

httpd_create  > /dev/null 2>&1 || exit 2
tomcat_create > /dev/null 2>&1 || exit 3

# clean everything at first
httpd_all_clean
tomcat_all_remove

res=0

# IMG name might include specific version, we have to handle that
IMG_NOVER=$(echo $IMG | cut -d: -f1)

for tomcat_version in "8.5" "9.0" "10.1"
do
    IMG="$IMG_NOVER:$tomcat_version" tomcat_create $tomcat_version > /dev/null 2>&1 || exit 3
    IMG="$IMG_NOVER:$tomcat_version" run_test basetests.sh "Basic tests with tomcat $tomcat_version"
    res=$(expr $res + $?)
done
run_test hangingtests.sh            "Hanging tests"
res=$(expr $res + $?)
run_test maintests.sh               "Main tests"
res=$(expr $res + $?)
run_test JBCS-1236/testit.sh        "JBCS-1236"
res=$(expr $res + $?)
run_test MODCLUSTER-640/testit.sh   "MODCLUSTER-640"
res=$(expr $res + $?)
run_test MODCLUSTER-734/testit.sh   "MODCLUSTER-734"
res=$(expr $res + $?)
run_test MODCLUSTER-755/testit.sh   "MODCLUSTER-755"
res=$(expr $res + $?)
run_test MODCLUSTER-785/testit.sh   "MODCLUSTER-785"
res=$(expr $res + $?)
run_test MODCLUSTER-794/testit.sh   "MODCLUSTER-794"
res=$(expr $res + $?)

echo "Clean remaining httpd containers"
httpd_all_clean 

if [ $res -eq 0 ]; then
    echo "Tests finished successfully!"
else
    echo "Tests finished, but some failed."
fi

exit $res
