#!/bin/bash

echo "DB_HOST=${DB_HOST}" >> /opt/webapp/.env
echo "DB_USER=${DB_USER}" >> /opt/webapp/.env
echo "DB_PASSWORD=${DB_PASSWORD}" >> /opt/webapp/.env
echo "DB_DATABASE=${DB_DATABASE}" >> /opt/webapp/.env
echo "DB_PORT=${DB_PORT}" >> /opt/webapp/.env
echo "S3_BUCKET_NAME=${S3_BUCKET_NAME}" >> /opt/webapp/.env
echo "AWS_REGION=${AWS_REGION}" >> /opt/webapp/.env
echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}" >> /opt/webapp/.env
echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}" >> /opt/webapp/.env
echo "AWS_OUTPUT_FORMAT=json" >> /opt/webapp/.env
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/webapp/cloud-watch-config.json -s
sudo chmod 644 /opt/webapp/cloud-watch-config.json
sudo chown root:root /opt/webapp/cloud-watch-config.json
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl status amazon-cloudwatch-agent
sudo systemctl enable mywebapp.service
sudo systemctl start mywebapp.service
sudo systemctl status mywebapp.service
sudo systemctl daemon-reload