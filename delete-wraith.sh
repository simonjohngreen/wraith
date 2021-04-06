REGION="eu-north-1"
echo "deleting any left over tmp-wraith buckets in my region"
for BUCKET in $(aws s3api list-buckets | jq '.Buckets[].Name' -r | grep tmp-wraith-);
do
    BUCKET_REGION=$(aws s3api get-bucket-location --bucket $BUCKET | jq '.LocationConstraint' -r)
    echo "checking bucket $BUCKET in region $BUCKET_REGION"
    if [ "$BUCKET_REGION" = "$REGION" ];
    then
        echo "deleting bucket $bucket"
        aws s3 rb s3://$BUCKET --force
    fi
done
echo "deleting any left over wraith-s3stack- buckets in my region"
for BUCKET in $(aws s3api list-buckets | jq '.Buckets[].Name' -r | grep wraith-s3stack-);
do
    BUCKET_REGION=$(aws s3api get-bucket-location --bucket $BUCKET | jq '.LocationConstraint' -r)
    echo "checking bucket $BUCKET in region $BUCKET_REGION"
    if [ "$BUCKET_REGION" = "$REGION" ];
    then
        echo "deleting bucket $bucket"
        aws s3 rb s3://$BUCKET --force
    fi
done
echo "deleting the wraith s3 bucket"
aws s3 rm s3://$(aws cloudformation describe-stacks --stack-name Wraith --query "Stacks[0].Outputs[]" --output text | grep S3BucketID | awk 'NF{ print $NF }') --recursive
#fixes a problem with cloudformation deletes hanging when lambda custom resources are present
for LAMBDA in $(aws lambda list-functions --query "Functions[].FunctionName" --o table | grep LamdbaS3CopyStack | tr -d ' ' | tr -d '|');
do
    echo "deleting lamdba function $LAMBDA"
    aws lambda delete-function --function-name $LAMBDA 
done
echo "deleting the cloudformation stack"
aws cloudformation delete-stack --stack-name Wraith 
echo "If you do not want to wait for the delete to finish you can hit cntrl-c"
aws cloudformation wait stack-delete-complete --stack-name Wraith 
echo "All Done"