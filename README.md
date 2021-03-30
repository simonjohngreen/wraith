# wraith
An automated, scalable, end-point and rest-api; capacity, penetration and port-scanner based on AWS CloudFormation

To Do:
Add IPV6
Add power scheduling

What Does wraith do:

	Wraith builds an aws infrastructure designed to test API's and public addresses with a distributed attack
	The infrastructure can be scaled up to hundreds of public nodes (see stack parameters)
	Tests are ran each time a node starts. 
        Each time a Node is started, new tests are executed and new reports are generated 
	Scanner nodes execute port scans based on the wraith-config.json and report.
	The pdf reports for each scan are then emailed to the recipient 
	Reports are then uploaded into wraiths s3 bucket (see stack outputs)

Configuring Wraith so you can deploy the stack:

	In deploy-wraith.sh 

	The only stack parameters you must configure are the email parameters, add your own email snmp service details (see below)
	If you do not do this, tests will still run, s3 will get the reports. You will not receive emails.
	All other parameters have sensible defaults, nd can be configured as you need,

Configuring the Wraith Services:

	deployers/wraith-endpoints-ipv4     (a list of ipv4 names and addresses you want port scanned)
	deployers/wraith-configuration.json (configures all parameters for all nodes, the defaults should get you started)

Installing wraith: (takes < 10 minutes)

	#install aws cli and connect to your account
	./deploy-wraith.sh

Deleting Wraith: (takes < 5 minutes)

	./delete-wraith.sh

Debugging Wraith nodes with ssh:

	./debug-node-ssh-on.sh  (opens up ssh access to the node you select)
	./debug-node-ssh-off.sh (disables ssh access to the node you select)

	Usefull logs on the nodes:
					Build logs /tmp/node-install.log
					Wraith logs /var/log/wraith.log

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


