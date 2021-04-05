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
	NMAPOPTION=$(jq -r ".wraith.nmap.report[$k] .command" wraith-config.json);
	if [[ $NMAPOPTION =~ "-6" ]]; then
   		echo "This test option includes IPV6 -6 so lets setup for that"
		XMLREPORTFILENAME=nmap-scan-ipv6-$HOSTNAME_PREFIX-$(jq -r ".wraith.nmap.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.xml;
		PDFREPORTFILENAME=nmap-scan-ipv6-$HOSTNAME_PREFIX-$(jq -r ".wraith.nmap.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.pdf;
		ENDPOINTFILE=wraith-endpoints-ipv6
	else	
   		echo "This test option does include IPV6 option -6 so run it as ipv4"
		XMLREPORTFILENAME=nmap-scan-ipv4-$HOSTNAME_PREFIX-$(jq -r ".wraith.nmap.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.xml;
		PDFREPORTFILENAME=nmap-scan-ipv4-$HOSTNAME_PREFIX-$(jq -r ".wraith.nmap.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.pdf;
		ENDPOINTFILE=wraith-endpoints-ipv4
	fi
   		echo "This test includes IPV6 option -6 so lets setup for that"
	echo "Debug: k = $k";
	echo "Debug: XMLREPORTFILENAME $XMLREPORTFILENAME";
	echo "Debug: PDFREPORTFILENAME $PDFREPORTFILENAME";
	echo "Debug: NMAPOPTION $NMAPOPTION";
	nmap $NMAPOPTION -oX ./reports-xml/$XMLREPORTFILENAME -iL ./wraith-endpoints-ipv4;
	sed -i '/DOCTYPE/d' ./reports-xml/$XMLREPORTFILENAME;
	fop -xml ./reports-xml/$XMLREPORTFILENAME -xsl nmap-fo.xsl -pdf ./reports-pdf/$PDFREPORTFILENAME;
done 
echo " add TCP IPV6 Scan"
sudo chown root:root /etc/msmtp/wraith0 
sudo chmod 0600 /root/muttrc 
#get todays list of reports and email them
TODAYS_REPORTS=$(find reports-pdf/* -daystart -ctime 0 -print | tr '\n' ' ')
mutt -F /root/muttrc -a $TODAYS_REPORTS -s "Wraith NMAP Report" -- simon.j.green@icloud.com < emailmessage.txt
aws s3 cp /root/reports-xml/ s3://wraith-s3stack-aauqqa1a42ll-s3reportbucket-265ua72ud3l2/reports-xml/ --recursive
aws s3 cp /root/reports-pdf/ s3://wraith-s3stack-aauqqa1a42ll-s3reportbucket-265ua72ud3l2/reports-pdf/ --recursive
rm /root/reports-xml/*
rm /root/reports-pdf/*
echo "All Done"
