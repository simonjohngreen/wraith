echo "Deleting the stack"
aws s3 rm s3://$(aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[0].Outputs[]" --output text | grep S3BucketID | awk 'NF{ print $NF }') --recursive
aws cloudformation delete-stack --stack-name Wraith 
echo "If you do not want to wait for the delete to finish you can hit cntrl-c"
aws cloudformation wait stack-delete-complete --stack-name Wraith 
echo "All Done"
