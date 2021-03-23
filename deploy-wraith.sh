aws cloudformation create-stack \
  --capabilities CAPABILITY_IAM \
  --stack-name Wraith \
  --disable-rollback \
  --template-url https://s3-eu-central-1.amazonaws.com/rancher-contrail/rancher-root-rke2.json \
  --parameters \
ParameterKey=VPCCIDR1,ParameterValue="100.72.100.0/22" \
ParameterKey=DeployContrailBastion,ParameterValue="true" \
ParameterKey=SiteName,ParameterValue="wraith" \
ParameterKey=NumberOfClusters,ParameterValue="1"
#the stacks are deploying lets check they come up and let the user know when its all ready
while [[ $(aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[].StackStatus" --output text) != "CREATE_COMPLETE" ]];
do
     RESULT=$(aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[].StackStatus" --output text)
     echo "$RESULT waiting for cloudformation stack to complete."
     sleep 60
done
aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[0].Outputs[]" --output table
echo "All Done"
