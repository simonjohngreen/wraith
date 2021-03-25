echo "Deleting the stack"
aws cloudformation delete-stack --stack-name Wraith 
echo "If you do not want to wait for the delete to finish you can hit cntrl-c"
aws cloudformation wait stack-delete-complete --stack-name Wraith 
echo "All Done"
