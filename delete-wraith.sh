echo "Deleting the stack"
aws s3 rm s3://$(aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[0].Outputs[]" --output text | grep S3BucketID | awk 'NF{ print $NF }') --recursive
#fixes a problem with cloudformation deletes hanging when lambda custom resources are present
LAMBDA=$(aws lambda list-functions --query "Functions[].FunctionName" --o table | grep Wraith-NMAPLamdbaS3CopyStack | tr -d ' ' | tr -d '|')
aws lambda delete-function --function-name $LAMBDA 
aws cloudformation delete-stack --stack-name Wraith 
echo "If you do not want to wait for the delete to finish you can hit cntrl-c"
aws cloudformation wait stack-delete-complete --stack-name Wraith 
echo "All Done"
