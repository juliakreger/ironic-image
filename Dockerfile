FROM docker.io/centos:centos7

RUN yum install -y python-requests && \
    curl https://raw.githubusercontent.com/openstack/tripleo-repos/master/tripleo_repos/main.py | python - current-tripleo && \
    yum update -y && \
    yum install -y uwsgi uwsgi-plugin-python openstack-ironic-api openstack-ironic-conductor crudini \
        iproute iptables dnsmasq httpd qemu-img-ev iscsi-initiator-utils parted gdisk ipxe-bootimgs psmisc sysvinit-tools \
        mariadb-server python-PyMySQL python2-chardet && \
    yum install -y python-ironic-prometheus-exporter && \
    yum clean all

RUN mkdir /tftpboot && \
    cp /usr/share/ipxe/undionly.kpxe /usr/share/ipxe/ipxe.efi /tftpboot/

COPY ./ironic.conf /tmp/ironic.conf
RUN crudini --merge /etc/ironic/ironic.conf < /tmp/ironic.conf && \
    rm /tmp/ironic.conf

COPY ./runironic-api.sh /bin/runironic-api
COPY ./runironic-conductor.sh /bin/runironic-conductor
COPY ./runironic-exporter.sh /bin/runironic-exporter
COPY ./rundnsmasq.sh /bin/rundnsmasq
COPY ./runhttpd.sh /bin/runhttpd
COPY ./runmariadb.sh /bin/runmariadb
COPY ./configure-ironic.sh /bin/configure-ironic.sh

# TODO(dtantsur): remove these 3 scripts and squash runexporterapp into
# runironic-exporter if we decide to stop supporting running all 3 processes
# via one entry point.
COPY ./runexporterapp.sh /bin/runexporterapp
COPY ./runhealthcheck.sh /bin/runhealthcheck
COPY ./runironic.sh /bin/runironic

COPY ./dnsmasq.conf /etc/dnsmasq.conf
COPY ./inspector.ipxe /tmp/inspector.ipxe
COPY ./dualboot.ipxe /tmp/dualboot.ipxe

ENTRYPOINT ["/bin/runironic"]
