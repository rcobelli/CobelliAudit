#! /bin/bash

# Setup color variables
red=`tput setaf 1`
green=`tput setaf 2`
blue=`tput setaf 6`
bold=`tput bold`
reset=`tput sgr0`

# Header
echo "+-----------------------------------------------------------------+"
echo "| ${bold}Quarterly Auditing System${reset}"
echo "+-----------------------------------------------------------------+"

echo "+-----------------------------------------------------------------+"
echo "|     Starting AWS Accounts"
echo "+-----------------------------------------------------------------+"

cat accounts | while read ACCOUNT
do
    echo "+-----------------------------------------------------------------+"
    echo "|          Starting ${ACCOUNT}"
    echo "+-----------------------------------------------------------------+"

    # Check that access keys are being rotated daily
    IAM_DATE=$(aws iam list-access-keys --profile $ACCOUNT --user-name localhost | jq '.["AccessKeyMetadata"][0]["CreateDate"]')
    if [ $(expr $(date "+%Y%m%d") - $(echo $IAM_DATE | cut -c2-5,7-8,10-11)) -gt 2 ]
    then
        echo "${red}[$ACCOUNT] ERROR: Access keys are older than 2 days${reset}"
    else
        echo "${green}[$ACCOUNT] Access keys are newer than 2 days${reset}"
    fi

    # Run prowler
    echo "${blue}[$ACCOUNT] Starting prowler${reset}"
    eval "/Users/ryan/Development/prowler/prowler -p $ACCOUNT -f us-east-1 -q -M html"

    # Get a list of all EBS snapshots
    EBS_DATE=$(aws ec2 describe-snapshots --profile ${ACCOUNT} --filters Name=tag:Production,Values=true --query "Snapshots[*].[StartTime]" --output text | sort -n | sed '$!d')
    if [ $(expr $(date "+%Y%m%d") - $(echo $EBS_DATE | cut -c1-4,6-7,9-10)) -gt 2 ]
    then
        echo "${red}[${ACCOUNT}] ERROR: EC2 Snapshots are older than 2 days${reset}"
    else
        echo "${green}[${ACCOUNT}] EC2 Snapshots are younger than 2 days${reset}"
    fi

    # Check that MySQL Backup is working

    # Get the backup bucket name
    BUCKET_NAME=$(aws s3api list-buckets --profile ${ACCOUNT} --query "Buckets[].Name" --output text | sed $'s/\t/\\\n/g' | grep db-backup)

    # Check that a bucket was found
    if [ ! -z "$var" ]
    then
        # Check that there are recent files
        SQL_DATE=$(aws s3api list-objects --profile ${ACCOUNT} --bucket ${BUCKET_NAME} --query 'Contents[].[LastModified]' --output text | sort -n | sed '$!d')
        if [ $(expr $(date "+%Y%m%d") - $(echo $SQL_DATE | cut -c1-4,6-7,9-10)) -gt 2 ]
        then
            echo "${red}[${ACCOUNT}] ERROR: MySQL Backups are older than 2 days${reset}"
        else
            echo "${green}[${ACCOUNT}] MySQL backups are younger than 2 days${reset}"
        fi

        # Check that the files are large enough to be a backup
        SQL_SIZE=$(aws s3api list-objects --profile ${ACCOUNT} --bucket ${BUCKET_NAME} --query 'Contents[].[Size]' --output text | sort -n | sed '$!d')
        if (( $SQL_SIZE < 150 ));
        then
            echo "${red}[${ACCOUNT}] ERROR: MySQL Backups are too small${reset}"
        else
            echo "${green}[${ACCOUNT}] MySQL backups are working${reset}"
        fi
    fi
done

echo "+-----------------------------------------------------------------+"
echo "|     Starting Databases"
echo "+-----------------------------------------------------------------+"

cat databases | while read ACCOUNT
do
    echo "+-----------------------------------------------------------------+"
    echo "|          Starting ${ACCOUNT}"
    echo "+-----------------------------------------------------------------+"

    # Check that there are recent files
    SQL_DATE=$(aws s3api list-objects --profile rybel --bucket ${ACCOUNT} --query 'Contents[].[LastModified]' --output text | sort -n | sed '$!d')
    if [ $(expr $(date "+%Y%m%d") - $(echo $SQL_DATE | cut -c1-4,6-7,9-10)) -gt 2 ]
    then
        echo "${red}[${ACCOUNT}] ERROR: MySQL Backups are older than 2 days${reset}"
    else
        echo "${green}[${ACCOUNT}] MySQL backups are younger than 2 days${reset}"
    fi

    # Check that the files are large enough to be a backup
    SQL_SIZE=$(aws s3api list-objects --profile rybel --bucket ${ACCOUNT} --query 'Contents[].[Size]' --output text | sort -n | sed '$!d')
    if (( $SQL_SIZE < 150 ));
    then
        echo "${red}[${ACCOUNT}] ERROR: MySQL Backups are too small${reset}"
    else
        echo "${green}[${ACCOUNT}] MySQL backups are working${reset}"
    fi

done

echo "+-----------------------------------------------------------------+"
echo "|          Web Checks"
echo "+-----------------------------------------------------------------+"

echo "${blue} Starting favicon checker${reset}"
cat urls | while read ACCOUNT
do
    osascript -e 'tell application "Safari" to open location "https://realfavicongenerator.net/favicon_checker?protocol=http&site='$ACCOUNT'"'
done


echo "${blue} Starting dead link checker${reset}"
osascript -e 'tell application "Safari" to open location "https://www.deadlinkchecker.com/multisite.asp"'


echo "+-----------------------------------------------------------------+"
echo "|     Checking Source for Credential Leaks"
echo "+-----------------------------------------------------------------+"

eval "gitleaks --no-git -q --path=/Users/ryan/Sites/clients/ --report=/Users/ryan/Desktop/clients.json > /dev/null 2>&1"
echo "${blue}Completed clients credentials scan${reset}"
eval "gitleaks --no-git -q --path=/Users/ryan/Sites/personal/ --report=/Users/ryan/Desktop/personal.json > /dev/null 2>&1"
echo "${blue}Completed personal credentials scan${reset}"
