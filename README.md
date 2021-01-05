# CobelliAudit

My personal auditing automation

I have a number of different applications running across multiple AWS accounts and it is a good idea to audit that everything is behaving as expected. I personally run this script every quarter but there is no reason why it couldn't be run more often.

## Setup
Create the following files and populate them with the respective values (one value per line). Then simply run `audit.sh`.

#### accounts
This is a list of all the AWS profiles on your device that you would like to checker

#### databases
This is a list of all the AWS S3 bucket names that you are storing database backups in

#### urls
This is a list of all the public domains that you would like to auditing

## Checks
For each account, the script will run [AWS Prowler](https://github.com/toniblyx/prowler), ensure that access keys are recent, ensure that EBS snapshots are recent, and _(if applicable)_ that associated S3 database backup buckets are working properly (the backup is recent and large enough to actually be a database dump)

For each database, the script will ensure that the database backup S3 bucket is working properly (the backup is recent and large enough to actually be a database dump)

For each url, the script will direct you to [realfavicongenerator.net](https://realfavicongenerator.net)'s favicon checker and to [deadlinkchecker.com](https://www.deadlinkchecker.com/multisite.asp)'s dead link checker tool

The script will also scan your source code using [gitleaks](https://github.com/zricethezav/gitleaks) to check for any leaked credentials
