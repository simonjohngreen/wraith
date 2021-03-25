aws cloudformation create-stack \
  --capabilities CAPABILITY_IAM \
  --stack-name Wraith \
  --disable-rollback \
  --template-url https://wraithdeployer.s3.eu-west-3.amazonaws.com/wraith-root.json \
  --parameters \
ParameterKey=KeyName,ParameterValue="wraithkey" \
ParameterKey=VPCCIDR1,ParameterValue="100.72.100.0/22" \
ParameterKey=SiteName,ParameterValue="wraith" \
ParameterKey=NumberOfNodes,ParameterValue="1"
#the stacks are deploying lets check they come up and let the user know when its all ready
while [[ $(aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[].StackStatus" --output text) != "CREATE_COMPLETE" ]];
do
     RESULT=$(aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[].StackStatus" --output text)
     echo "$RESULT waiting for cloudformation stack to complete."
     sleep 20
done
aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[0].Outputs[]" --output table
echo "All Done"
