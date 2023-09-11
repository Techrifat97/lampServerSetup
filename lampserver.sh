#!/bin/bash

# Configuration
REGION="us-east-1"          # Change this to your desired AWS region
INSTANCE_TYPE="t2.micro"    # Free Tier eligible instance type
KEY_PAIR="your-key-pair"    # Change this to your key pair name
UBUNTU_AMI="ami-xxxxxxxxxxxx" # Replace with the desired Ubuntu AMI ID

# Create a new Ubuntu VM within Free Tier limits
aws ec2 run-instances \
  --region $REGION \
  --image-id $UBUNTU_AMI \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_PAIR \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyUbuntuVM}]'

# Wait for the instance to be running
aws ec2 wait instance-running --region $REGION

# Get the public IP address of the instance
PUBLIC_IP=$(aws ec2 describe-instances --region $REGION --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo "Ubuntu VM created with Public IP: $PUBLIC_IP"

# SSH into the VM and setup LAMP
SSH_KEY="your-private-key.pem" # Replace with the path to your private key file
VM_USER="ubuntu"               # The default user for Ubuntu AMIs

# Wait for SSH to become available
until ssh -i "$SSH_KEY" $VM_USER@$PUBLIC_IP "echo 'SSH is ready'"; do
    sleep 5
done

# Install LAMP components
ssh -i "$SSH_KEY" $VM_USER@$PUBLIC_IP 'sudo apt update && sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql'

# Start Apache and MySQL services
ssh -i "$SSH_KEY" $VM_USER@$PUBLIC_IP 'sudo systemctl start apache2'
ssh -i "$SSH_KEY" $VM_USER@$PUBLIC_IP 'sudo systemctl start mysql'

# Enable Apache and MySQL to start on boot
ssh -i "$SSH_KEY" $VM_USER@$PUBLIC_IP 'sudo systemctl enable apache2'
ssh -i "$SSH_KEY" $VM_USER@$PUBLIC_IP 'sudo systemctl enable mysql'

echo "LAMP server is set up on the Ubuntu VM at $PUBLIC_IP"
