FROM fedora:37

RUN yum install gcc wget apr-devel apr-util-devel openssl-devel pcre-devel redhat-rpm-config wcstools git autoconf -y

ENV HTTPD=https://dlcdn.apache.org/httpd/httpd-2.4.57.tar.gz
ENV SOURCES=https://github.com/modcluster/mod_proxy_cluster
ENV BRANCH=main
ENV CONF=https://raw.githubusercontent.com/modcluster/mod_proxy_cluster/main/test/httpd/mod_proxy_cluster.conf

ADD install.sh /tmp

CMD /tmp/install.sh


