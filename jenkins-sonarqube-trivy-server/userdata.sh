#!/bin/bash

# install git
sudo yum update -y
sudo yum install git -y

# install jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
sudo dnf install java-17-amazon-corretto -y
sudo yum install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins

# install docker
sudo yum install docker -y
sudo usermod -a -G docker ec2-user
sudo usermod -a -G docker jenkins
sudo chmod 777 /var/run/docker.sock
sudo systemctl enable docker
sudo systemctl start docker

# install trivy
sudo yum update -y
sudo amazon-linux-extras install epel -y
sudo yum install -y wget
wget https://github.com/aquasecurity/trivy/releases/download/v0.18.3/trivy_0.18.3_Linux-64bit.rpm
sudo yum install -y trivy_0.18.3_Linux-64bit.rpm

# Run sonarqube image
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community



