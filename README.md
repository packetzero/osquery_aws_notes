# Notes on osquery AWS Logger Plugins
In addition to the integration tests, this guide outlines some best practices on AWS logger plugin usage. *My focus was on Kinesis, but should be relevant to Firehose as well*.

## Credential Considerations
- **Never use the access keys for the root user for the AWS account.**  This would be like putting your AWS console username and password in your osquery config files.

- **How would your environment invalid data or getting spammed with logs?**  Each device running osquery will have configuration containing AWS credentials to write to your AWS Kinesis or Firehose endpoints.  What if an agent had a bug and started sending 1000 messages per minute?  What if a malicious actor takes the credentials and crafts logs that are intended to break your server-side processing?  For these reasons, we need to consider how to mitigate those problems, revoke credentials, and how to control access to them.  There are a few different ways to configure AWS credentials for osquery to help manage those situations.

- **Use tls configuration**  Consider using the TLS configuration, in which the osquery agents fetch the configuration periodically (e.g. 5 minutes) from a server.  This will help recover from changes to AWS credentials.
- **Dropped messages** The AWS Kinesis logger is configured to retry (default 100 times) before dropping a message.  TODO: What happens if user is on the device, but offline?

## Configuring Access Credentials
There are a few ways to provide osquery agents with the security credentials needed to write to AWS Kinesis or Firehose endpoints.

### 1. User security tokens
This is the simplest case, in which the 'Access Keys' for a user account are used (aws_access_key_id, aws_secret_access_key). You will want to create an IAM user with just the access needed:
 - Kinesis / Firehose write access (e.g. PutRecord)
 - no console access (default for new IAM users)

You are unlikely to create IAM user accounts for each osquery endpoint device.  Therefore, if you need to revoke credentials, it will affect all osquery agents.

### 2. STS Tokens for IAM Role
In this scenario, an IAM user is created with the 'sts:AssumeRole' permissions.  Osquery agents are configured with the Access Keys for that user, along with a aws_sts_arn_role flag to specify a role to assume.  That role has restricted permissions to write to Kinesis or Firehose.  The osquery agent will try to assume the role and if successful will be given the new STS Access Keys, SessionToken, and Expiration Time.  When a token expires, osquery will do the assume role request again to reacquire credentials.

### 3. Server provided STS Token
In this scenario, a server provides Access Keys, along with aws_session_token in the configuration.  The periodic refresh of the TLS configuration provides means to update the AWS credentials as needed, with the ability to selectively deny AWS credentials to specific agents.  This is the most flexible, but also the most complicated, as it requires server management of STS tokens.

## Setup
[Setting up for AWS tests](./setup.md)

## Usage
```
$ ruby tools/tests/aws/aws-integration-tests.rb
Usage: aws-integration-tests [options]
    -s, --stream STREAM_NAME         e.g. "osquery-kinesis-stream"
    -r, --role_arn ROLE_ARN_VALUE    e.g. "arn:aws:iam::123456789012:role/osquery-kinesis-streams"
    -p, --path_to_exe PATH           OPTIONAL e.g. ./build/darwin/osquery/aws_logger_integration_tests
    -v, --verbose                    Write each test output to stdout
    -f, --filter TEST_LIST           OPTIONAL Comma-delimited list of test names to run.
		Full list: local_user_creds,osquery_assume_role,provided_session_token,fail_user_creds_invalid,fail_invalid_sts_role,endpoint_override,endpoint_override_provided_session
```

## Example Output

[Test run output](./example-verbose-output.txt)
