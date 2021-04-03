#!/bin/bash -x
#redirect stdout/stderr to a file
exec &> /var/log/wraith.log
cd /root
#generate the IPV4 nmap reports
mkdir -p reports-xml
mkdir -p reports-pdf
DATEANDTIME="$(date +"%m-%d-%y-%T")"
HOSTNAME_PREFIX=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname | cut -d"." -f1)
for k in $(jq '.wraith.nmap.report | keys | .[]' wraith-config.json); do
	XMLREPORTFILENAME=nmap-scan-ipv4-$HOSTNAME_PREFIX-$(jq -r ".wraith.nmap.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.xml;
	PDFREPORTFILENAME=nmap-scan-ipv4-$HOSTNAME_PREFIX-$(jq -r ".wraith.nmap.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.pdf;
	NMAPOPTION=$(jq -r ".wraith.nmap.report[$k] .command" wraith-config.json);
	#echo "k = $k";
	#echo "XMLREPORTFILENAME $XMLREPORTFILENAME";
	#echo "PDFREPORTFILENAME $PDFREPORTFILENAME";
	#echo "NMAPOPTION $NMAPOPTION";
	nmap $NMAPOPTION -oX ./reports-xml/$XMLREPORTFILENAME -iL ./wraith-endpoints-ipv4;
	sed -i '/DOCTYPE/d' ./reports-xml/$XMLREPORTFILENAME;
	fop -xml ./reports-xml/$XMLREPORTFILENAME -xsl nmap-fo.xsl -pdf ./reports-pdf/$PDFREPORTFILENAME;
done 
echo " add TCP IPV6 Scan"
sudo chown root:root /etc/msmtp/wraith0 
sudo chmod 0600 /root/muttrc 
#get todays list of reports and email them
TODAYS_REPORTS=$(find reports-pdf/* -daystart -ctime 0 -print | tr '\n' ' ')
mutt -F /root/muttrc -a $TODAYS_REPORTS -s "Wraith NMAP Report" -- [EmailToAddress] < emailmessage.txt
aws s3 cp /root/reports-xml/ s3://[S3BucketID]/reports-xml/ --recursive
aws s3 cp /root/reports-pdf/ s3://[S3BucketID]/reports-pdf/ --recursive
rm /root/reports-xml/*
rm /root/reports-pdf/*
echo "All Done"
