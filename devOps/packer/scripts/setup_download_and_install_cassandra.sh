#!/bin/bash

# Update package manager and get tree package
sudo apt-get install -y tree
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt-get update

# Install basic environment
sudo apt-get --yes --force-yes install ssh rsync openjdk-8-jdk scala python-dev python-pip python-numpy python-scipy python-pandas gfortran git supervisor ruby bc

# Setup a download and installation directory
HOME_DIR='/home/ubuntu'
INSTALLATION_DIR='/usr/local'
sudo mkdir ${HOME_DIR}/Downloads

# Set Java
sudo update-java-alternatives -s java-1.8.0-openjdk-amd64

# Path to S3 bucket for downloading Hadoop and Spark
S3_BUCKET=https://s3-us-west-2.amazonaws.com/insight-tech

# Install Python and needed packages
sudo apt-get install -y python-pip python-dev build-essential
sudo pip install configparser
sudo pip install psycopg2
sudo pip install numpy

# Install Boto
sudo pip install boto
sudo pip install boto3

# Install Cassandra



sudo apt-get install -y cassandra

# Log into Cassandra as Cassandra
sudo -u cassandra cqlsh << EOF
create KEYSPACE emotion with replication={'clase':'SimpleStrategy', 'replication_factor':3};
create TABLE emotion.state
create USER kksante with password 'insight';
grant all on emotion to kksante;
EOF

# Install Git and clone repository
sudo apt-get install git-core
git clone git@github.com:kksante/Earths_Emotion_Tracker.git

# Run DE cassandra application
cd Earths_Emotion_Tracker/Emotions/app/src 
python views.py

# Allow cassandra to listen to all incoming traffic then restart
sudo sed -i "51i listen_addresses = '*'" /etc/cassandra/9.5/main/cassandra.conf
sudo sed -i '96i host    all             all             0.0.0.0/0               md5' /etc/cassandra/9.5/main/pg_hba.conf
sudo /etc/init.d/cassandra restart
