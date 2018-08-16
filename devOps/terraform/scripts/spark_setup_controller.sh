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

#Download spark_cassandra_connector and put in ~/Earths_Emotion_Tracker/Emotions/src
#datastaxConnector_URL=http://dl.bintray.com/spark-packages/maven/datastax/spark-cassandra-connector/2.3.1-s_2.11/spark-cassandra-connector-2.3.1-s_2.11.jar
#sudo wget ${"datastaxConnector_URL"}
#sudo mv ~/spark-cassandra-connector-*.jar ~/Earths_Emotion_Tracker/Emotions



# Configure setup.cfg with cassandra and Spark master private DNS
#sed -i "/dns-cassandra/c\dns = ${cassandra}" ${APPHOME}/setup.cfg
#sed -i "/dns-spark/c\dns = ${sparkmaster}:7077" ${APPHOME}/setup.cfg
