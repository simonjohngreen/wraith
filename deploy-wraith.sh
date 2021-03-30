#!/bin/bash
# vars to build up the temp s3 folder
UUID=`python  -c 'import uuid; print uuid.uuid4()'`
TempS3bucket="tmp-wraith-"${UUID}
tempS3bucketURL="https://$TempS3bucket.s3-eu-west-3.amazonaws.com"
aws s3 mb s3://${TempS3bucket}
echo "${YELLOW}Uploading files to s3${RESTORE} "
aws s3 sync --quiet deployers s3://${TempS3bucket}
echo "creating cloudformation stack"
aws cloudformation create-stack \
  --capabilities CAPABILITY_IAM \
  --stack-name Wraith \
  --disable-rollback \
  --template-url $tempS3bucketURL/wraith-root.json \
  --parameters \
ParameterKey=KeyName,ParameterValue="wraithkey" \
ParameterKey=VPCCIDR1,ParameterValue="100.72.100.0/22" \
ParameterKey=SiteName,ParameterValue="wraith" \
ParameterKey=NumberOfNodes,ParameterValue="1" \
ParameterKey=tempS3bucketURL,ParameterValue="$tempS3bucketURL" \
ParameterKey=TempS3bucket,ParameterValue="$TempS3bucket" \
ParameterKey=EmailServerURL,ParameterValue="smtp.gmail.com" \
ParameterKey=EmailUsername,ParameterValue="example@gmail.com" \
ParameterKey=EmailPassword,ParameterValue="xxxxxx" \
ParameterKey=EmailFromAddress,ParameterValue="example@gmail.com" \
ParameterKey=EmailToAddress,ParameterValue="example@gmail.com"
#the stacks are deploying lets check they come up and let the user know when its all ready
while [[ $(aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[].StackStatus" --output text) != "CREATE_COMPLETE" ]];
do
     RESULT=$(aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[].StackStatus" --output text)
     echo "$RESULT waiting for cloudformation stack to complete."
     sleep 20
done
if [ -n ${TempS3bucket} ];
then
        aws s3 rb s3://${TempS3bucket} --force
else
        echo "TempS3bucket was not set for some reason so we could not clean up s3"
fi
echo "========"
echo "All Done"
echo "========"
aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[0].Outputs[]" --output table
