#! /bin/bash -v

sudo apt-get update -y
sudo apt-get -y install httpd24 awscli
sudo apt-get install -y nginx > /tmp/nginx.log

echo Setting directory permissions
chgrp -R ubuntu /etc/nginx
chown -R ubuntu /etc/nginx

echo Copying installation files
aws s3 cp --region us-east-1 s3://testla-2020/ /tmp/install/ --recursive

echo Running install.sh
su - ubuntu /tmp/install/install.sh

echo Cleaning up
rm -r /tmp/install


EOM