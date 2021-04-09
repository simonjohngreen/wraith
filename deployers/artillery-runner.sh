#!/bin/bash -x
#redirect stdout/stderr to a file
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/wraith.log 2>&1
cd /root
#generate the artillery reports
mkdir -p reports-xml
mkdir -p reports-pdf
DATEANDTIME="$(date +"%m-%d-%y-%T")"
HOSTNAME_PREFIX=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname | cut -d"." -f1)
for k in $(jq '.wraith.artillery.report | keys | .[]' wraith-config.json); do
	ARTILLERYOPTION=$(jq -r ".wraith.artillery.report[$k] .command" wraith-config.json);
	if [[ $ARTILLERYOPTION =~ "-6" ]]; then
   		echo "This test option includes IPV6 -6 so lets setup for that"
		XMLREPORTFILENAME=artillery-scan-ipv6-$HOSTNAME_PREFIX-$(jq -r ".wraith.artillery.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.xml;
		PDFREPORTFILENAME=artillery-scan-ipv6-$HOSTNAME_PREFIX-$(jq -r ".wraith.artillery.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.pdf;
		ENDPOINTFILE=wraith-endpoints-ipv6
	else	
   		echo "This test option does include IPV6 option -6 so run it as ipv4"
		XMLREPORTFILENAME=artillery-scan-ipv4-$HOSTNAME_PREFIX-$(jq -r ".wraith.artillery.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.xml;
		PDFREPORTFILENAME=artillery-scan-ipv4-$HOSTNAME_PREFIX-$(jq -r ".wraith.artillery.report[$k] .prefix" wraith-config.json)-$DATEANDTIME.pdf;
		ENDPOINTFILE=wraith-endpoints-ipv4
	fi
   		echo "This test includes IPV6 option -6 so lets setup for that"
	echo "Debug: k = $k";
	echo "Debug: XMLREPORTFILENAME $XMLREPORTFILENAME";
	echo "Debug: PDFREPORTFILENAME $PDFREPORTFILENAME";
	echo "Debug: ARTILLERYOPTION $ARTILLERYOPTION";
	#work in progress
    #artillery run /root/artillery-testscript1.yml  
	sed -i '/DOCTYPE/d' ./reports-xml/$XMLREPORTFILENAME;
	fop -xml ./reports-xml/$XMLREPORTFILENAME -xsl artillery-fo.xsl -pdf ./reports-pdf/$PDFREPORTFILENAME;
done
#work in progress
#artillery run /root/artillery-testscript1.yml  
sudo chown root:root /etc/msmtp/wraith0 
sudo chmod 0600 /root/muttrc 
#get todays list of reports and email them
TODAYS_REPORTS=$(find reports-pdf/* -daystart -ctime 0 -print | tr '\n' ' ')
mutt -F /root/muttrc -a $TODAYS_REPORTS -s "Wraith ARTILLERY Report" -- [EmailToAddress] < emailmessage.txt
aws s3 cp /root/reports-xml/ s3://[S3BucketID]/reports-xml/ --recursive
aws s3 cp /root/reports-pdf/ s3://[S3BucketID]/reports-pdf/ --recursive
rm /root/reports-xml/*
rm /root/reports-pdf/*
echo "All Done"
