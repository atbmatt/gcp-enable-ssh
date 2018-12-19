#!/bin/bash

# gcloud_ssh_enable.sh
#
# Original Author
# Mark Patterson
# mark@3labs.io
# 11-02-2018
#
# Updated By
# Matt Sembinelli
# msembinelli@atb.com
# 19-12-2018
#
# Script to empower GCP gcloud shell users to be secure via a whitelist and still have the ability to use ssh
# Dynamically creates and updates firewall rules to allow ssh to work from the gcloud shell 
# Also adds in the google ip ranges so the web console based ssh sessions will work as well
# The default firewall rule for ssh allows the entire world to connect
# Removing that default firewall rule breaks ssh sessions through the google cloud console, hence the reason for this script
# 
# Enjoy :)


#Modify the network and other settings as needed to match your use case
#This script assumes that you are running it in the gcloud console from the target project
#
#Define FW Network/VPC name (Don't use default network)
fw_net=$1

#Firewall Rules to allow
fw_rules="tcp:22"

#Start building firewall rule name
#Set FW Rule Prefix
fw_rule_name_prefix="gcbrowser-ssh"

#Build rough Firewall Rule Name
fw_rule_name_rough=${fw_rule_name_prefix}"-"${fw_net}

#Build Firewall rule name and filter out characters not allowed in a FW rule name
fw_rule_name=${fw_rule_name_rough//[^-a-z0-9]/}

#Define Source ips, Google SPF IP Range + gcloud Shell External IP

src_ip=`nslookup -q=TXT _spf.google.com| tr ' ' '\n'|grep include|cut -d : -f2|xargs -i nslookup -q=TXT {}|tr ' ' '\n'|grep ip4|cut -d: -f2|tr '\n'

#Aloha
echo "Welcome to gcloud_ssh_enable v1.2  ...working for you..."

if [[ $(gcloud compute firewall-rules list --format=list --filter name=${fw_rule_name}|wc -c) -ne 0 ]]; then
    echo "Updating FW Rule $fw_rule_name"
    echo "Adding IP's $src_ip"
    #Update Dynamic Google Cloud Shell FW Rule 
    gcloud compute firewall-rules update $fw_rule_name --source-ranges=$src_ip

else
    echo "Creating FW Rule $fw_rule_name"
    echo "Adding IP's $src_ip"
    #Create Dynamic Google Cloud Shell FW - Rule Run Once
    gcloud compute firewall-rules create $fw_rule_name --description=Dyn-SSH-FW \
    --direction=INGRESS --priority=1000 --network=$fw_net --action=ALLOW --rules=$fw_rules --source-ranges=$src_ip

fi
