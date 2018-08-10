#!/bin/bash

cassandra=$1
sparkmaster=$2

#APPHOME='/home/ubuntu/Earths_Emotion_Tracker/Emotions'

# Configure setup.cfg with cassandra and Spark master private DNS
#sed -i "/dns-cassandra/c\dns = ${cassandra}" ${APPHOME}/setup.cfg
#sed -i "/dns-spark/c\dns = ${sparkmaster}:7077" ${APPHOME}/setup.cfg

# Install gunicorn
sudo pip install gunicorn

# Deploy app
#cd ${APPHOME}/flask
gunicorn app:app --bind=0.0.0.0:8000 --daemon
