#!/bin/bash
echo "this script deletes the ssh SG rules for an instance to secure it, it should work on mac an linux"
export PUBLICIPLIST=( $(aws ec2 describe-instances --filters Name=tag:Name,Values="*Wraith*" "Name=instance-state-code,Values=16" --query "Reservations[].Instances[].PublicIpAddress" --output text) )
export INSTANCEIDLIST=( $(aws ec2 describe-instances --filters Name=tag:Name,Values="*Wraith*" "Name=instance-state-code,Values=16" --query "Reservations[].Instances[].InstanceId" --output text) )
export INSTANCESGLIST=( $(aws ec2 describe-instances --filters Name=tag:Name,Values="*Wraith*" "Name=instance-state-code,Values=16" --query "Reservations[].Instances[].NetworkInterfaces[].Groups[].GroupId" --output text) )
export INSTANCENAMELIST=( $(aws ec2 describe-instances --filters Name=tag:Name,Values="*Wraith*" "Name=instance-state-code,Values=16" --query "Reservations[].Instances[].Tags[?Key=='Name'].Value" --output text) )
export MYPUBLICIP=`dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | tr -d \"`
echo "Your laptop ip is 		$MYPUBLICIP"
echo "*****************************************"
echo "Which instance SG would you like remove the ssh rule on"
echo "*****************************************"
createmenu ()
{
  arrsize=$1
  select option in "${@:2}"; do
    if [ "$REPLY" -eq "$arrsize" ];
    then
      echo "Exiting..."
      break;
    elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $((arrsize-1)) ];
    then
      echo "You selected $option which is option $REPLY"
      break;
    else
      echo "Incorrect Input: Select a number 1-$arrsize"
    fi
  done
}
createmenu "${#INSTANCEIDLIST[@]}" "${INSTANCEIDLIST[@]}"
NODESGID=$(aws ec2 describe-security-groups --filters Name=group-name,Values="*NodeGroupStack*" --query "SecurityGroups[].GroupId" --output text)
aws ec2 revoke-security-group-ingress --group-id ${INSTANCESGLIST[$REPLY-1]} --protocol tcp --port 22 --cidr $MYPUBLICIP/32
