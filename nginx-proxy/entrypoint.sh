#!/bin/sh
echo "AWSHOST=${AWSHOST}"
sed -i s/_AWSHOST_/${AWSHOST}/ /etc/nginx/nginx.conf
nginx -g "daemon off;"
