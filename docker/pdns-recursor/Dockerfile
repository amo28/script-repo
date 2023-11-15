############################################################
# Dockerfile to build pdns-recursor container
############################################################

FROM rockylinux:9-minimal
LABEL maintainer="Matthew Amalino"

# Create pdns-recursor config
RUN mkdir -p /etc/pdns-recursor

# Copy entrypoint
COPY pdns_recursor.sh /pdns_recursor.sh
RUN chmod +x /pdns_recursor.sh

# Run updates and install pdns-recursor
RUN microdnf update -y && \
    microdnf install -y epel-release && \
    microdnf install -y curl bash glibc-minimal-langpack bash bind-utils && \
    microdnf install -y python3-pip && \
    curl -o /etc/yum.repos.d/powerdns-rec-49.repo https://repo.powerdns.com/repo-files/el-rec-49.repo && \
    microdnf install -y pdns-recursor && \
    microdnf clean all

# pdns config building
ARG CONFIG=/etc/pdns-recursor/recursor.conf

RUN sed -i '/disable-syslog=/cdisable-syslog=yes' "${CONFIG}" && \
    sed -i '/local_port=/clocal_port=53' "${CONFIG}" && \
    sed -i '/forward-zones-recurse=/cforward-zones-recurse=consul=127.0.0.1:8600' "${CONFIG}" && \
    sed -i '/any_to_tcp=/cany_to_tcp=yes' "${CONFIG}" && \
    sed -i '/dnssec=/cdnssec=validate' "${CONFIG}" && \
    sed -i '/dnssec_log_bogus=/cdnssec_log_bogus=yes' "${CONFIG}" && \
    sed -i '/webserver=/cwebserver=no' "${CONFIG}" && \
    sed -i '/version-string=/cversion-string=anonymous' "${CONFIG}" && \
    sed -i '/unique-response-tracking=/cunique-response-tracking=yes' "${CONFIG}" && \
    sed -i '/packetcache-ttl=/cpacketcache-ttl=2' "${CONFIG}" && \
    sed -i '/log-timestamp=/clog-timestamp=no' "${CONFIG}" && \
    sed -i '/local-address=/clocal-address=0.0.0.0' "${CONFIG}" && \
    sed -i '/setuid=/csetuid=pdns-recursor' "${CONFIG}" && \
    sed -i '/setgid=/csetgid=pdns-recursor' "${CONFIG}"

#Expose port 53
EXPOSE 53
EXPOSE 53/udp

#Security requirements
RUN pip install --upgrade pip

#Healthcheck
HEALTHCHECK --start-period=30s \
    CMD host -W 1 -t A google.com || exit 1

#Launch the app
ENTRYPOINT ["/pdns_recursor.sh"]
CMD ["pdns_recursor", "--daemon=no"]
