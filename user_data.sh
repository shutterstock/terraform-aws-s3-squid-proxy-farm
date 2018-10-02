#!/bin/bash

yum install -y squid

cat <<EOF > /etc/squid/squid.conf
# Example rule allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
acl all src all
acl localnet src ${proxy_allowed_cidr}

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 443         # https
acl Safe_ports port 1025-65535  # unregistered ports
acl CONNECT method CONNECT

#
# Recommended minimum Access Permission configuration:
#
# Deny requests to certain unsafe ports
http_access deny !Safe_ports

# Deny CONNECT to other than secure SSL ports
http_access deny CONNECT !SSL_ports

# Only allow cachemgr access from localhost
#http_access allow all
http_access allow localhost manager
http_access deny manager

# Allowing access only to AWS sites.
acl allowed_http_sites dstdomain .amazonaws.com
http_access allow allowed_http_sites

# Example rule allowing access from your local networks.
# Adapt localnet in the ACL section to list your (internal) IP networks
# from where browsing should be allowed
#http_access allow all
http_access allow localnet
http_access allow localhost

# And finally deny all other access to this proxy
http_access deny all

# Listen port
http_port ${proxy_port}
EOF

# The Yum installation automatically starts the squid daemon...
# Let's give it a second before we restart it with new config.
# Admittedly, this is probably overkill.
sleep 10
systemctl restart squid
