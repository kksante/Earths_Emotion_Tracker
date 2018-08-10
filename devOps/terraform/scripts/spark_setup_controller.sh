#!/bin/bash

cassandra=$1
sparkmaster=$2
#nyears=$3

#APPHOME='/home/ubuntu/Earths_Emotion_Tracker/Emotions/'

# Install dependencies
sudo pip install configparser
sudo pip --no-cache-dir install pyspark

# Install Git and clone repo
sudo apt-get install git-core
git clone https://github.com/kksante/Earths_Emotion_Tracker.git

# Configure setup.cfg with cassandra and Spark master private DNS
#sed -i "/dns-cassandra/c\dns = ${cassandra}" ${APPHOME}/setup.cfg
#sed -i "/dns-spark/c\dns = ${sparkmaster}:7077" ${APPHOME}/setup.cfg
