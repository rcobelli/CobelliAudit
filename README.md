# CobelliAudit

My personal auditing automation

I have a number of different applications running across multiple AWS accounts and it is a good idea to audit that everything is behaving as expected. I personally run this script every quarter but there is no reason why it couldn't be run more often.

## Setup
Create a file called `urls` that contains a list of all the public domains that you would like to audit (1 per line). Then simply run `audit.sh`. All the other data will be automatically pulled in via the AWS CLI

## Checks
For each account, the script will run:
  - [AWS Prowler](https://github.com/toniblyx/prowler)
  - Ensure that access keys are recent (rotated in the last 48 hours)
  - Ensure that EBS snapshots are recent (created within the last 48 hours)
  - Ensure S3 database backup buckets are working properly (the backup was made within the last 48 hours and large enough to actually be a database dump)
    - A S3 bucket is considered a backup bucket if it follows the regex pattern `rybel-.*-backup`

For each url, the script will direct you to [realfavicongenerator.net](https://realfavicongenerator.net)'s favicon checker and to [deadlinkchecker.com](https://www.deadlinkchecker.com/multisite.asp)'s dead link checker tool

The script will also scan your source code using [gitleaks](https://github.com/zricethezav/gitleaks) to check for any leaked credentials
