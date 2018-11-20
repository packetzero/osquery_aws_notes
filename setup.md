# Setup for AWS Logger Integration Tests

This will guide you through the creation of AWS user and role, as well as the docker proxy to test aws_endpoint_override setting.

## Create Kinesis Write-only role
It's possible to use the stock KinesisFullAccess role, but in practice, we want to prevent the situation where anyone with access to osquery agent AWS credentials can read data for all deployed agents!  Create an IAM role named 'osquery-kinesis-streams' with the following inline policy.  The role will have a ARN like `arn:aws:iam::123456789012:role/osquery-kinesis-streams`, where `123456789012` will be replaced with your account number.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "kinesis:PutRecord",
                "kinesis:PutRecords",
                "kinesis:DescribeStream"
            ],
            "Resource": "arn:aws:kinesis:*:*:stream/*"
        }
    ]
}
```

## Create osquery-user
Create an IAM user named **osquery-user** with *inline-policy* like the following.  It only permits AssumeRole.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "arn:aws:iam::123456789012:role/osquery-kinesis-streams"
        }
    ]
}
```

For the purpose of the tests, Add an additional policy for the user to write to Kinesis.  The test script will flag tests that successfully log, but fail to get STS token.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "kinesis:PutRecord",
                "kinesis:PutRecords",
                "kinesis:DescribeStream"
            ],
            "Resource": "*"
        }
    ]
}
```
## Get the Access Keys for osquery-user

On the osquery-user detail page, click on the 'Security credentials' tab.  In the 'Access keys' section, click 'Create access key' button.  You will be presented with a dialog that shows the new access key ID, but the secret is hidden.  Either click the download .csv file or click the *Show* link and copy/paste these ID and secret into a ~/.aws/credentials file.  The credentials file should have the following format.

```
[default]
aws_access_key_id = AKIAJEXAMPLEXEG2JICEA
aws_secret_access_key = 9drTJvcXLB89EXAMPLELB8923FB892xMFI
```

## Docker for Endpoint Override Test
There is an option to have AWS clients connect to a host different from the standard API gateway (e.g. 'kinesis.us-east-1.amazonaws.com').  To test this we can run a docker container with a local nginx proxy.  Once you have docker installed, cd to nginx-proxy directory in a terminal and run `build_and_run_container.sh`.  You will see the setup, and then it will wait for connections.  When connections are made, it will log the access log to stdout (like last 2 lines here).
```
$ ./build_and_run_container.sh
AWSHOST='kinesis.us-east-2.amazonaws.com'
Sending build context to Docker daemon  11.78kB
Step 1/7 : FROM nginx:stable-alpine
 ---> 77bae8d00654
Step 2/7 : COPY etc/nginx/* /etc/nginx/
 ---> Using cache
 ---> 344acbfea526
Step 3/7 : COPY entrypoint.sh /root/entrypoint.sh
 ---> Using cache
 ---> 46207ffdd1d5
Step 4/7 : RUN chmod 775 /root/entrypoint.sh
 ---> Using cache
 ---> 78b4b8179b24
Step 5/7 : ENV AWSHOST kinesis.us-east-1.amazonaws.com
 ---> Using cache
 ---> 602a0ba61543
Step 6/7 : EXPOSE 443
 ---> Using cache
 ---> b25155adca13
Step 7/7 : CMD ["/root/entrypoint.sh"]
 ---> Using cache
 ---> 3d6f48cfe201
Successfully built 3d6f48cfe201
Successfully tagged ngprox:latest
AWSHOST=kinesis.us-east-2.amazonaws.com

172.17.0.1 - - [20/Nov/2018:20:12:13 +0000] "POST / HTTP/1.1" 403 138 "-" "aws-sdk-cpp/1.4.55 Darwin/17.7.0 x86_64"
172.17.0.1 - - [20/Nov/2018:20:42:11 +0000] "POST / HTTP/1.1" 200 146 "-" "aws-sdk-cpp/1.4.55 Darwin/17.7.0 x86_64"
```


## Should Fail: Kinesis access from STS user
We only gave this user permission to assume roles, so attempting to get information on a Kinesis stream should fail.  Assuming that you have a kinesis stream named 'osquery-kinesis-stream', the command-line is:
```
$ aws kinesis describe-stream --stream-name osquery-kinesis-stream

An error occurred (AccessDeniedException) when calling the DescribeStream operation: User: arn:aws:iam::123456789012:user/osquery-user is not authorized to perform: kinesis:DescribeStream on resource: arn:aws:kinesis:us-east-2:123456789012:stream/osquery-kinesis-stream
```


## Test assume-role
We can test this on the command-line.  If successful, it will output some JSON that contains a **SessionToken**, along with new **AccessKeyId** and **SecretAccessKey** .  If you need to debug a problem where assume-role is working in osquery, but unable to write to kinesis, you can put these creds in a ~/.aws/credentials file and test using aws command-line.
```
aws sts assume-role --role-arn "arn:aws:iam::123456789012:role/osquery-kinesis-streams" --role-session-name osquery-test1
```
