# Wraith

![Https wraith](https://static.wikia.nocookie.net/stargate/images/a/a3/HiveInfection11.jpg/revision/latest/scale-to-width-down/1000?cb=20200608010055)

## What Does Wraith do:

* Wraith automates those periodic internet based port scans, penetration tests, API capacity and performance tests and functional API tests, that we are all asked to run manualy. 

* Wraith also generates reports in xml and pdf. Emails the pdf's in an easy to digest format. Then stores the pdf and xml reports in an S3 bucket.

* Wraith is fully automated within a nested cloudformation stack. You run one small script to deploy the whole solution. There is no need to login to the nodes.

* Wraith is configurable. you can modify it using the cloudformation parameters and config.xml. Turn features on and off. Ask for 100 nodes or 1 node of NMAP scanners to run at 2am every Tuesday. Ask it to scan all of your public endpoints. You can also add your own scans to the config.json. 

* Wraith supports scans on IPV4 and IPV6.

* In between scaning, the autoscaling groups are scheduled to scale back to 0, saving on compute $$s.

* So far the NMAP scans are ready to go. Other scans and features will be added soon. 
	
## Configuration details follow:
	
### Configuring Wraith before you deploy it:

File: deploy-wraith.sh 

* You just need to Configure your existing EC2 SSH key name (KeyName) and the four email smtp parameters (see below for email SMTP server configuration examples)

* If you don't update these email parameters the tests will still run, s3 will still get the reports. But you will not receive any emails.

 * All other parameters have sensible defaults to get you started.

### Telling Wraith what public endpoints to scan:

File: deployers/wraith-endpoints-ipv4     

* Add a list of ipv4 names and/or addresses you want port scanned

File: deployers/wraith-endpoints-ipv6     
* Add a list of ipv6 names and/or addresses you want port scanned

File: deployers/wraith-configuration.json 

* This file configures the tests to run, the defaults will get you started and can be left as is.

### Installing wraith: (takes < 15 minutes)

* install aws cli and connect to your AWS account, then enter
``` 
./deploy-wraith.sh
```

### Deleting Wraith: (takes < 5 minutes)
```
./delete-wraith.sh
```

### Besides Emails, where are the reports kept?

* When you ran the ./deploy-wrait.sh the output was an s3 bucket. 
* In this wraith-s3stack-*-s3reportbucket-* bucket all past xml and pdf reports are stored. 
* The retention is configurable (5 days is the default)

### I don't want to schedule my tests, I just want to run some nodes now. 

* Set parameter NMAPLambdaScheduleStartExpression=null
* No lambda scheduler will run, instead NMAPNumberOfNodes nodes will be fired up now.

### Debugging Wraith nodes with ssh:
```
#opens up ssh access to the node you select
./debug-node-ssh-on.sh 
#disables ssh access to the node you select 
./debug-node-ssh-off.sh 
```
###  Besides emails, where are the logs:

* Cloudwatch log groups: wraith-nmap						Logs when generating NMAP Scans and emails
* 	Cloudwatch log groups: /aws/lambda/Wraith-NMAPLamdbaS3CopyStack*	The output from the bucket copy
* Cloudwatch log groups: /aws/lambda/Wraith-NMAPLamdbaSchedulerStack*	The output from the scheduler
* On the nodes: /tmp/node-install.log 	The cloud-init logs from when the node was built

## More details on Emailing Reports:

### Email In General 
* For emailing reports I use msmtp (smtp) and configure it using five stack parameter:
	* EmailServerURL
    * EmailUsername
    * EmailPassword
    * EmailFromAddress
    * EmailToAddress

* This works well with most email smtp services, I've tested with icloud, gmail and AWS SES.
### Gmail 
* To use gmail to send the report, you need to generate an app password and use that rather than youre account password
* Info: https://support.google.com/accounts/answer/185833?p=InvalidSecondFactor&visit_id=637525499216786581-3978521167&rd=1
* google web portal->security->app password->
   	* mail
	* other
	* copy the password and use it as the password for your account

Example: 
```
ParameterKey=EmailServerURL,ParameterValue="smtp.gmail.com" \
ParameterKey=EmailUsername,ParameterValue="my.email@gmail.com" \
ParameterKey=EmailPassword,ParameterValue="yl45fGtfsfwr" \
ParameterKey=EmailFromAddress,ParameterValue="my.email@gmail.com" \
ParameterKey=EmailToAddress,ParameterValue="my.email@gmail.com"
```
### ICloud 
* To use icloud to send the reports again you need create an app password and use that rather than youre account password
* Info: https://support.apple.com/en-gb/HT204397
* Portal: https://appleid.apple.com/account/managei
* In the Security section, click Generate Password below App-Specific Passwords.

Example: 
```
ParameterKey=EmailServerURL,ParameterValue="smtp.mail.me.com" \
ParameterKey=EmailUsername,ParameterValue="my.email@icloud.com" \
ParameterKey=EmailPassword,ParameterValue="jkfk-dfeefds-345fdf-gbsc" \
ParameterKey=EmailFromAddress,ParameterValue="my.email@icloud.com" \
ParameterKey=EmailToAddress,ParameterValue="my.email@icloud.com"
```
### AWS SES
* AWS SES you just have to specify the mail servers, login and password. SES will then forward the report emails.
* For SES emails fordwarded to icloud and gmail to be accepted, there is a lot to setup within your AWS account itself, 
* So that the emails are not seen as junk and dropped. This site gives the gorry details https://www.mailmonitor.com/email-delivery-tips-icloud-users/ 

Example: 
```
ParameterKey=EmailServerURL,ParameterValue="email-smtp.eu-central-1.amazonaws.com" \
ParameterKey=EmailUsername,ParameterValue="AKRGFTHGFG67G7K" \
ParameterKey=EmailPassword,ParameterValue="BKfkjrdoifv79fdyYTW" \
ParameterKey=EmailFromAddress,ParameterValue="my.email@mydomain.com \"
ParameterKey=EmailToAddress,ParameterValue="my.email@mydomain"
```

