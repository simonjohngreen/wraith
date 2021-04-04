# wraith

An automated, scalable, end-point port-scanner, written in AWS CloudFormation

Comming Soon: Rest API Capacity Tesiting. Internet facing endpoint Penetrartion Testing


What Does wraith do:

	Wraith looks to automate those periodic port scans, penetration tests and API capacity, API performance tests and functional API tests, that we are all asked to run from time to time. 

	Wraith then generates reports in xml and pfd, and emails the pdf's to you boss.

	Wraith is automated. You run one script to deploy the whole solution using AWS Cloudformation. 

	Wraith is configurable. you can turn features on and off. You can ask for 100 nodes or 1 node of NMAP scanners to run at 2am every Tuesday. To scan all of your public endpoints IPV4 and IPV6. 

	In between test runs, the autoscaling groups are scaled back to 0 based on a cron, saving $$s on your bill. 

	So far the NMAP scans are ready to go. Other features will be added soon. 
	
	configuration details follow:
	

Configuring Wraith before you deploy it:

	File: deploy-wraith.sh 

	Configure are the four email parameters, add your own email snmp service details (see below for examples)

	If you don't add these, tests will still run, s3 will still get the reports. But you will not receive any emails.

	All other parameters have sensible defaults to get you started.

Telling Wraith what public endpoints to scan:

	File: deployers/wraith-endpoints-ipv4     Add a list of ipv4 names and/or addresses you want port scanned
	File: deployers/wraith-endpoints-ipv6     Add a list of ipv6 names and/or addresses you want port scanned
	File: deployers/wraith-configuration.json This file configures the tests to run, the defaults will get you started and can be left as is.

Installing wraith: (takes < 15 minutes)

	#install aws cli and connect to your AWS account, then enter
	./deploy-wraith.sh

Deleting Wraith: (takes < 5 minutes)

	./delete-wraith.sh

Where are the reports kept?

	When you ran the ./deploy-wrait.sh the output was an s3 bucket. In this wraith-s3stack-*-s3reportbucket-* bucket all past xml and pdf reports are stored. The retention is configurable (5 days is the default)

I don't want to schedule my tests, I just want to run some nodes now. 

	Set parameter NMAPLambdaScheduleStartExpression=null
	No lambda scheduler will run, instead NMAPNumberOfNodes nodes will be fired up now.

Debugging Wraith nodes with ssh:

	./debug-node-ssh-on.sh  (opens up ssh access to the node you select)
	./debug-node-ssh-off.sh (disables ssh access to the node you select)

Where are the logs:

	Cloudwatch log groups: wraith-nmap						Logs when generating NMAP Scans and emails
	Cloudwatch log groups: /aws/lambda/Wraith-NMAPLamdbaS3CopyStack*	The output from the bucket copy
	On the nodes: /tmp/node-install.log 	The cloud-init logs from when the node was built

More details on Emailing Reports:

	For emailing reports I use msmtp (smtp) and configure it using five stack parameter:

                    EmailServerURL
                    EmailUsername
                    EmailPassword
                    EmailFromAddress
                    EmailToAddress

	This works well with most email smtp services, I've tested with icloud, gmail and AWS SES.

	To use gmail to send the report, you need to generate an app password and use that rather than youre account password
	https://support.google.com/accounts/answer/185833?p=InvalidSecondFactor&visit_id=637525499216786581-3978521167&rd=1
	google web portal->security->app password->
                        mail
                        other
                        copy the password and use it as the password for your account

	To use icloud to send the reports again you need create an app password and use that rather than youre account password
	https://support.apple.com/en-gb/HT204397
	Portal https://appleid.apple.com/account/managei
      		In the Security section, click Generate Password below App-Specific Passwords.

	AWS SES you just have to specify the mail servers, login and password. SES will then forward the report emails.
	For SES emails fordwarded to icloud and gmail to be accepted, there is a lot to setup within your AWS account itself, 
	So that the emails are not seen as junk and dropped. This site gives the gorry details https://www.mailmonitor.com/email-delivery-tips-icloud-users/ 


