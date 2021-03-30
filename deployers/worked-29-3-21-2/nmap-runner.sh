echo " add TCP IPV6 Scan"

######works##################Generate the nmap reports mased on the config json############################
mkdir -p reports-xml
mkdir -p reports-pdf
DATEANDTIME="$(date +"%m-%d-%y-%T")"
for k in $(jq '.wraith.nmap.report | keys | .[]' wraith-config.json); do
	XMLREPORTFILENAME=nmap-scan-$(jq -r ".wraith.nmap.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.xml;
	PDFREPORTFILENAME=nmap-scan-$(jq -r ".wraith.nmap.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.pdf;
	NMAPOPTION=$(jq -r ".wraith.nmap.report[$k] .command" wraith-config.json);
	#echo "k = $k";
	#echo "XMLREPORTFILENAME $XMLREPORTFILENAME";
	#echo "PDFREPORTFILENAME $PDFREPORTFILENAME";
	#echo "NMAPOPTION $NMAPOPTION";
	nmap $NMAPOPTION -oX ./reports-xml/$XMLREPORTFILENAME -iL ./wraith-endpoints-ipv4;
	sed -i '/DOCTYPE/d' ./reports-xml/$XMLREPORTFILENAME;
	fop -xml ./reports-xml/$XMLREPORTFILENAME -xsl nmap-fo.xsl -pdf ./reports-pdf/$PDFREPORTFILENAME;
done 
###########################################################

sort out email.

apt-get -y install mutt
mkdir -p /home/ubuntu/Mail
mkdir -p /root/Mail
DATEANDTIME="$(date +"%m-%d-%y-%T")"
mutt -s "NMAP Reports" -a reports-pdf/nmap-scan-nse-scripts-03-27-21-19\:42\:31.pdf < /dev/null -- mail@mail.com
mutt -s "NMAP Reports" -a reports-pdf/nmap-scan-nse-scripts-03-27-21-19\:42\:31.pdf -- simon.j.green@icloud.com

mutt -s "NMAP Reports" -a reports-pdf/nmap-scan-nse-scripts-03-27-21-19\:42\:31.pdf reports-pdf/nmap-scan-tcp-03-27-21-19\:42\:31.pdf reports-pdf/nmap-scan-udp-03-27-21-19\:42\:31.pdf -- simon.j.green@icloud.com

echo "NMAP Reports for site are attached" | mutt -a "./reports-pdf/nmap-scan-tcp-03-27-21-19:42:31.pdf" -s "NMAP Report" -- simon.j.green@icloud.com

DEBIAN_FRONTEND=noninteractive apt-get install -y mailutils
echo "NMAP Reports for site are attached" | mailx -s "NMAP Report" -a reports-pdf/nmap-scan-tcp-03-27-21-19\:42\:31.pdf simon.j.green@icloud.com

----

#######gmail didn't quite work as it required the account to enable app passwords##################
First, it will want to know the “General type of mail configuration.” Since we’re only interested in sending email from the server, and since we’re using an external SMTP server, select Satellite system

Next, it will want to know the mailname. For this you’ll want to enter your hostname, E.g example.com
ec2-15-237-56-158.eu-west-3.compute.amazonaws.com


DEBIAN_FRONTEND=noninteractive apt-get -y install postfix mailutils libsasl2-2 ca-certificates libsasl2-modules
cat << EOF > /etc/postfix/main.cf
relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CApath = /etc/ssl/certs
smtpd_tls_CApath = /etc/ssl/certs
smtp_use_tls = yes
EOF
cat << EOF > /etc/postfix/sasl_passwd
[smtp.gmail.com]:587    mr.simon.john.green@gmail.com:L0ngG00dFr1day123_
EOF
cat << EOF > /etc/aliases
mailer-daemon: postmaster
postmaster: root
nobody: root
hostmaster: root
usenet: root
news: root
webmaster: root
www: root
ftp: root
abuse: root
noc: root
security: root
root: user
user: mr.simon.john.green@gmail.com
EOF
sudo newaliases
sudo chmod 400 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo /etc/init.d/postfix start
sudo /etc/init.d/postfix reload
echo "Test mail thingy" | mail -s "Test Postfix Subject" mr.simon.john.green@gmail.com 


######aws ses########
######currently trying this one#####
#https://docs.aws.amazon.com/ses/latest/DeveloperGuide/postfix.html#send-email-postfix
sudo apt-get update
debconf-set-selections <<< "postfix postfix/mailname string ec2-15-237-100-161.eu-west-3.compute.amazonaws.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes postfix mailutils libsasl2-2 ca-certificates libsasl2-modules
sudo postconf -e "relayhost = [email-smtp.eu-central-1.amazonaws.com]:587" \
"smtp_sasl_auth_enable = yes" \
"smtp_sasl_security_options = noanonymous" \
"smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" \
"smtp_use_tls = yes" \
"smtp_tls_security_level = encrypt" \
"smtp_tls_note_starttls_offer = yes"
cat > /etc/postfix/sasl_passwd <<EOF
[email-smtp.eu-central-1.amazonaws.com]:587 AKIAYGCSX67ECPSBH7IX:BKujohhbxg8jXtZd56T5oTqzahvKehQVqqtwHI7xyYTW
EOF
sudo postmap hash:/etc/postfix/sasl_passwd
sudo chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
sudo chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
sudo postconf -e 'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt'
sudo postfix start; sudo postfix reload
#to reconfigure later on 
#sudo dpkg-reconfigure postfix
sendmail -f emea-saas-prod@juniper.net simon.j.green@icloud.com 
From: emea-saas-prod@juniper.net
Subject: Amazon SES Test                
This message was sent using Amazon SES.                
.
#might have worked., shows as mail sent in ses, but not received

sendmail -f emea-saas-prod@juniper.net mr.simon.john,green@gmail.com 
From: emea-saas-prod@juniper.net
Subject: Amazon SES Test
This message was sent using Amazon SES.
.
#fails, odd error (host email-smtp.eu-central-1.amazonaws.com[52.28.116.56] said: 554 Transaction failed: Address contains illegal characters in user name: '<"mr.simon.john@ec2-15-237-100-161.eu-west-3.compute.amazonaws.comroot"@ip-100-72-103-13>'. (in reply to end of DATA command))


echo "Test mail thingy" | mail -s "Test Postfix Subject" mr.simon.john.green@gmail.com 
#fails as root@[public domain] is not known



############################################################3

# Postfix
SERVER_FQDN=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
SERVER_EMAIL="emea-saas-prod@juniper.net"
cat > /var/cache/debconf/postfix.preseed <<EOF
postfix postfix/chattr  boolean false
postfix postfix/destinations    string  $SERVER_FQDN
postfix postfix/mailbox_limit   string  0
postfix postfix/mailname    string  $SERVER_FQDN
postfix postfix/main_mailer_type    select  Internet Site
postfix postfix/mynetworks  string  127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
postfix postfix/protocols   select  all
postfix postfix/recipient_delim string  +
postfix postfix/root_address    string  $SERVER_EMAIL
EOF
if [ ! -d /etc/postfix ]
then
    mkdir -p /etc/postfix
fi
cat > /etc/postfix/main.cf <<EOF
# See /usr/share/postfix/main.cf.dist for a commented, more complete version
# Debian specific:  Specifying a file name will cause the first
# line of that file to be used as the name.  The Debian default
# is /etc/mailname.
#myorigin = /etc/mailname
smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
biff = no
# appending .domain is the MUA's job.
append_dot_mydomain = no
# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h
readme_directory = no
# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
# See /usr/share/doc/postfix/TLS_README.gz in the postfix-doc package for
# information on enabling SSL in the smtp client.
myhostname = $SERVER_FQDN
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = $SERVER_FQDN, localhost
relayhost =
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = loopback-only
inet_protocols = all
EOF
debconf-set-selections /var/cache/debconf/postfix.preseed
apt-get -q -y -o DPkg::Options::=--force-confold install postfix
apt-get -q -y install mailutils


########try ssmpt which is a send only email tool#######
sudo apt-get install ssmpt
systemctl stop sendmail
systemctl stop postfix
systemctl disable sendmail
systemctl disable postfix
alternatives --config mta
#select /usr/bin/sendmail.ssmtp
cat > /etc/ssmtp/ssmtp.conf <<EOF
root=
mailhub=smtp.gmail.com:587
AuthUser=mr.simon.john.green@gmail.com
AuthPass=
UseSTARTTLS=Yes
TLS_CA_File=/etc/pki/tls/certs/ca-bundle.crt 
RewriteDomain=localhost
Hostname=localhost
FromLineOverride=Yes
EOF
echo "Testing" | mail -s "Test Email" mr.simon.john.green@gmail.com 
tail -f /var/log/maillog 


####### msmtp on gmail (works)################
#for gmail to work now a days you have to enable an app password
#https://support.google.com/accounts/answer/185833?p=InvalidSecondFactor&visit_id=637525499216786581-3978521167&rd=1
#->security->app password->
#                        mail
#                        other 
#                                wrait in aws
#                        copy the password and use it as the password for your account
#                                ylhllawtqexcsfwr

sudo apt-get -y install msmtp msmtp-mta ca-certificates
sudo mkdir -p /etc/msmtp
sudo mkdir -p /var/log/msmtp
cat > /etc/msmtp/wraith0 <<EOF
# Define here some setting that can be useful for every account
defaults
        logfile /var/log/msmtp/general.log
# Settings for wraith0 account
account wraith0
        protocol smtp
        host smtp.gmail.com
        tls on
        tls_trust_file /etc/ssl/certs/ca-certificates.crt
        port 587
        auth login
        user mr.simon.john.green@gmail.com
        password ylhllawtqexcsfwr 
        from mr.simon.john.green@gmail.com
        logfile /var/log/msmtp/wraith0.log
# If you don't use any "-a" parameter in your command line,
# the default account "wraith0" will be used.
account default: wraith0
EOF

#if you need to debug a new mail service, this command is very usefull
echo -e "Subject: Test Mail\r\n\r\nThis is a test mail" | msmtp --debug --from=default -t mr.simon.john.green@gmail.com --file=/etc/msmtp/wraith0

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install mutt
cat > /root/muttrc <<EOF
set sendmail="/usr/bin/msmtp --file=/etc/msmtp/wraith0" 
set use_from=yes 
set realname="mr.simon.john.green@gmail.com" 
set from="mr.simon.john.green@gmail.com" 
set envelope_from=yes
EOF
cat > /root/emailmessage.txt <<EOF
From: mr.simon.john.green@gmail.com 
Subject: gmail attachment Test 
This message was sent using gmail 
EOF

mutt -F /root/muttrc -a /root/reports-pdf/nmap-scan-tcp-03-28-21-19:08:43.pdf -s "Logwatch Report" -- mr.simon.john.green@gmail.com < emailmessage.txt
mutt -F /root/muttrc -a /root/reports-pdf/nmap-scan-tcp-03-28-21-19:08:43.pdf -s "Logwatch Report" -- simon.j.green@icloud.com < emailmessage.txt


####### msmtp on AWS SES ################
#for SES to work now a days you have to 
#
#

sudo apt-get -y install msmtp msmtp-mta ca-certificates
sudo mkdir -p /etc/msmtp
sudo mkdir -p /var/log/msmtp
cat > /etc/msmtp/wraith0 <<EOF
# Define here some setting that can be useful for every account
defaults
        logfile /var/log/msmtp/general.log
# Settings for wraith0 account
account wraith0
        protocol smtp
        host email-smtp.eu-central-1.amazonaws.com 
        tls on
        tls_trust_file /etc/ssl/certs/ca-certificates.crt
        port 587
        auth login
        user AKIAYGCSX67EA3UVZU7K 
        password BKujohhbxg8jXtZd56T5oTqzahvKehQVqqtwHI7xyYTW 
        from emea-saas-prod@juniper.net 
        logfile /var/log/msmtp/wraith0.log
# If you don't use any "-a" parameter in your command line,
# the default account "wraith0" will be used.
account default: wraith0
EOF

#if you need to debug a new mail service, this command is very usefull
echo -e "Subject: Test Mail\r\n\r\nThis is a test mail" | msmtp --debug --from=emea-saas-prod@juniper.net -t mr.simon.john.green@gmail.com --file=/etc/msmtp/wraith0
#above says ok but there was no email
echo -e "Subject: Test Mail\r\n\r\nThis is a test mail" | msmtp --debug --from=emea-saas-prod@juniper.net -t simon.j.green@icloud.com --file=/etc/msmtp/wraith0
#above says ok but there was no email
#####try the above two to the juniper email tomorrow, as I recall SES to icloud not working in the past, they probably mark it as junk###

echo -e "Subject: Test Mail\r\n\r\nThis is a test mail" | msmtp --debug --from=root@email-smtp.eu-central-1.amazonaws.com -t mr.simon.john.green@gmail.com --file=/etc/msmtp/wraith0
#above is rejected, email not verified
echo -e "Subject: Test Mail\r\n\r\nThis is a test mail" | msmtp --debug --from=root@email-smtp.eu-central-1.amazonaws.com -t simon.j.green@icloud.com --file=/etc/msmtp/wraith0
#above is rejected, email not verified

# icloud and gmail as destinations may need DKIM, to add this I need to have access to the From domain dns, so it will have to be my domain in route53 
# https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-authentication-dkim-easy-setup-email.html


sudo DEBIAN_FRONTEND=noninteractive apt-get -y install mutt
cat > /root/muttrc <<EOF
set sendmail="/usr/bin/msmtp --file=/etc/msmtp/wraith0" 
set use_from=yes 
set realname="emea-saas-prod@juniper.net" 
set from="emea-saas-prod@juniper.net" 
set envelope_from=yes
EOF
cat > /root/emailmessage.txt <<EOF
From: emea-saas-prod@juniper.net 
Subject: gmail attachment Test 
This message was sent using gmail 
EOF

mutt -F /root/muttrc -a /root/reports-pdf/nmap-scan-tcp-03-28-21-19:08:43.pdf -s "Logwatch Report" -- mr.simon.john.green@gmail.com < emailmessage.txt
mutt -F /root/muttrc -a /root/reports-pdf/nmap-scan-tcp-03-28-21-19:08:43.pdf -s "Logwatch Report" -- simon.j.green@icloud.com < emailmessage.txt



####### msmtp on icloud (worked)################
#for icloud to work now a days you have to enable an app password
#https://support.apple.com/en-gb/HT204397
#in https://appleid.apple.com/account/managei
#      In the Security section, click Generate Password below App-Specific Passwords.
#      use the app specific password as the password for the account

sudo apt-get -y install msmtp msmtp-mta ca-certificates
sudo mkdir -p /etc/msmtp
sudo mkdir -p /var/log/msmtp
cat > /etc/msmtp/wraith0 <<EOF
# Define here some setting that can be useful for every account
defaults
        logfile /var/log/msmtp/general.log
# Settings for wraith0 account
account wraith0
        protocol smtp
        host smtp.mail.me.com 
        tls on
        tls_trust_file /etc/ssl/certs/ca-certificates.crt
        port 587
        auth login
        user simon.j.green@icloud.com 
        password jkfk-dnna-imnj-gbsc 
        from simon.j.green@icloud.com 
        logfile /var/log/msmtp/wraith0.log
# If you don't use any "-a" parameter in your command line,
# the default account "wraith0" will be used.
account default: wraith0
EOF

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install mutt
cat > /root/muttrc <<EOF
set sendmail="/usr/bin/msmtp --file=/etc/msmtp/wraith0" 
set use_from=yes 
set realname="simon.j.green@icloud.com" 
set from="simon.j.green@icloud.com" 
set envelope_from=yes
EOF
cat > /root/emailmessage.txt <<EOF
From: simon.j.green@icloud.com 
Subject: icloud attachment Test 
This message was sent using icloud 
EOF

sudo chown root:root /etc/msmtp/wraith0 
sudo chmod 0600 /root/muttrc 

mutt -F /root/muttrc -a /root/reports-pdf/nmap-scan-tcp-03-28-21-19:08:43.pdf -s "Logwatch Report" -- simon.j.green@icloud.com < emailmessage.txt
mutt -F /root/muttrc -a /root/reports-pdf/nmap-scan-tcp-03-28-21-19:08:43.pdf -s "Logwatch Report" -- mr.simon.john.green@gmail.com < emailmessage.txt



