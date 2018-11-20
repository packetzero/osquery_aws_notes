#!/bin/bash

# try to figure out AWS destination

SVC='kinesis'
REGION=`aws configure get region`
if [ "${REGION}" == "" ] ; then
  REGION=us-east-1
fi
AWSHOST="${SVC}.${REGION}.amazonaws.com"

echo "AWSHOST='${AWSHOST}'"

docker build -t ngprox .
docker run -it --rm -p 443:443 -e AWSHOST=${AWSHOST} --name ngprox ngprox
