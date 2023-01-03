#!/bin/bash
export VAULT_TOKEN=$(</home/appuser/.aws/token)
DATE=`date +%Y-%m-%d-%H-%M-%S`
vault operator raft snapshot save /tmp/vaultsnapshot-$DATE.snap
/usr/local/bin/aws s3 cp /tmp/vaultsnapshot-$DATE.snap s3://$S3BUCKET/
rm /tmp/vaultsnapshot-$DATE.snap
echo "Completed the backup - " $DATE