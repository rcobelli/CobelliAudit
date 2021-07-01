#! /bin/bash

# Header
echo "+-----------------------------------------------------------------+"
echo "| Quarterly Auditing System"
echo "+-----------------------------------------------------------------+"


echo "+-----------------------------------------------------------------+"
echo "|          App Deployment Checks"
echo "+-----------------------------------------------------------------+"
ls /Users/ryan/Sites/clients | while read ACCOUNT
do
    # Check if iOS has been updated in the last 6 months
    if [ -d "/Users/ryan/Sites/clients/$ACCOUNT/ios" ]
    then

        eval lastCommit=$(git --git-dir /Users/ryan/Sites/clients/$ACCOUNT/ios/.git log -1 --format=%ct)
        diff=$(($(date +'%s') - $lastCommit))

        if [ $diff -gt 15552000 ]
        then
            echo "[$ACCOUNT][iOS][ERROR] App hasn't been updated in the last 6 months"
        fi

    fi

    # Check if there are commits (changes) since the last tag (release)
    if [ -d "/Users/ryan/Sites/clients/$ACCOUNT/ios" ]
    then

        recentCommitCount=$(/usr/bin/git -C /Users/ryan/Sites/clients/$ACCOUNT/ios log $(/usr/bin/git -C /Users/ryan/Sites/clients/$ACCOUNT/ios describe --tags --abbrev=0 )..HEAD --oneline | wc -l)

        if [ $recentCommitCount -gt 0 ]
        then
            echo "[$ACCOUNT][iOS][ERROR] App has unpublished changes"
        fi

    fi

    # Check if Pods have been updated in the last quarter
    if [ -f "/Users/ryan/Sites/clients/$ACCOUNT/ios/Podfile.lock" ]
    then

        lastEdit=$(stat -f "%m" "/Users/ryan/Sites/clients/$ACCOUNT/ios/Podfile.lock")
        diff=$(($(date +'%s') - $lastEdit))

        if [ $diff -gt 7776000 ]
        then
            echo "[$ACCOUNT][iOS][ERROR] Pods haven't been updated in the last 3 months"
        fi
    fi

    # Check if Android has been updated in the last 6 months
    if [ -d "/Users/ryan/Sites/clients/$ACCOUNT/android" ]
    then

        eval lastCommit=$(git --git-dir /Users/ryan/Sites/clients/$ACCOUNT/android/.git log -1 --format=%ct)
        diff=$(($(date +'%s') - $lastCommit))

        if [ $diff -gt 15552000 ]
        then
            echo "[$ACCOUNT][Android][ERROR] App hasn't been updated in the last 6 months"
        fi

    fi

    # Check if there are commits (changes) since the last tag (release)
    if [ -d "/Users/ryan/Sites/clients/$ACCOUNT/android" ]
    then

        recentCommitCount=$(/usr/bin/git -C /Users/ryan/Sites/clients/$ACCOUNT/android log $(/usr/bin/git -C /Users/ryan/Sites/clients/$ACCOUNT/android describe --tags --abbrev=0 )..HEAD --oneline | wc -l)

        if [ $recentCommitCount -gt 0 ]
        then
            echo "[$ACCOUNT][Android][ERROR] App has unpublished changes"
        fi

    fi
done

echo "+-----------------------------------------------------------------+"
echo "|     Starting AWS Accounts"
echo "+-----------------------------------------------------------------+"

/usr/local/bin/aws configure list-profiles | while read ACCOUNT
do
    echo "+-----------------------------------------------------------------+"
    echo "|          Starting ${ACCOUNT}"
    echo "+-----------------------------------------------------------------+"

    # Check that access keys are being rotated daily
    IAM_DATE=$(/usr/local/bin/aws iam list-access-keys --profile $ACCOUNT --user-name localhost | jq '.["AccessKeyMetadata"][0]["CreateDate"]')
    if [ $(expr $(date "+%Y%m%d") - $(echo $IAM_DATE | cut -c2-5,7-8,10-11)) -gt 2 ]
    then
        echo "[$ACCOUNT][ERROR] Access keys are older than 2 days"
    else
        echo "[$ACCOUNT] Access keys are newer than 2 days"
    fi

    # Get a list of all EBS snapshots
    EBS_DATE=$(/usr/local/bin/aws ec2 describe-snapshots --profile ${ACCOUNT} --filters Name=tag:Production,Values=true --query "Snapshots[*].[StartTime]" --output text | sort -n | sed '$!d')
    if [ $(expr $(date "+%Y%m%d") - $(echo $EBS_DATE | cut -c1-4,6-7,9-10)) -gt 2 ]
    then
        echo "[${ACCOUNT}][ERROR] EC2 Snapshots are older than 2 days"
    else
        echo "[${ACCOUNT}] EC2 Snapshots are younger than 2 days"
    fi

    # Check that MySQL Backup is working

    # Get the backup bucket name
    /usr/local/bin/aws s3api list-buckets --query "Buckets[].[Name]" --output text --profile ${ACCOUNT} | grep "rybel-.*-backup" | while read BUCKET_NAME
    do
        # Check that there are recent files
        SQL_DATE=$(/usr/local/bin/aws s3api list-objects --profile ${ACCOUNT} --bucket ${BUCKET_NAME} --query 'Contents[].[LastModified]' --output text | sort -n | sed '$!d')
        if [ $(expr $(date "+%Y%m%d") - $(echo $SQL_DATE | cut -c1-4,6-7,9-10)) -gt 2 ]
        then
            echo "[${ACCOUNT}][${BUCKET_NAME}][ERROR] MySQL Backups are older than 2 days"
        else
            echo "[${ACCOUNT}][${BUCKET_NAME}] MySQL backups are younger than 2 days"
        fi

        # Check that the files are large enough to be a backup
        SQL_SIZE=$(/usr/local/bin/aws s3api list-objects --profile ${ACCOUNT} --bucket ${BUCKET_NAME} --query 'Contents[].[Size]' --output text | sort -n | sed '$!d')
        if (( $SQL_SIZE < 150 ));
        then
            echo "[${ACCOUNT}][${BUCKET_NAME}][ERROR] MySQL Backups are too small"
        else
            echo "[${ACCOUNT}][${BUCKET_NAME}] MySQL backups are working"
        fi
    done
done

echo "+-----------------------------------------------------------------+"
echo "|          Web Checks"
echo "+-----------------------------------------------------------------+"

echo " Starting favicon checker"
cat urls | while read ACCOUNT
do
    /usr/bin/osascript -e 'tell application "Safari" to open location "https://realfavicongenerator.net/favicon_checker?protocol=http&site='$ACCOUNT'"'
    /usr/bin/osascript -e 'tell application "Safari" to open location "https://www.ssllabs.com/ssltest/analyze.html?d='$ACCOUNT'&hideResults=on&latest"'
done


echo " Starting dead link checker"
/usr/bin/osascript -e 'tell application "Safari" to open location "https://www.deadlinkchecker.com/multisite.asp"'


echo "+-----------------------------------------------------------------+"
echo "|     Checking Source for Credential Leaks"
echo "+-----------------------------------------------------------------+"

echo "Starting clients credentials scan..."
eval "/usr/local/bin/gitleaks --no-git -q --path=/Users/ryan/Sites/clients/"
echo "Completed clients credentials scan"
