#!/bin/bash

####################################################################
# User parameters
# Notes:
# - gsed in this file used for MacOS, change to sed if appropriate for your OS
# - Need to export TF_VAR_AWS_ACCESS_KEY and TF_VAR_AWS_SECRET_KEY as environment variables
####################################################################

# Number of Spark worker nodes
NSPARK=3

# Path to public and private keys
PUBLICKEY='/Users/kksante/Documents/GitHub/Earths_Emotion_Tracker/terraform/mykeypair.pub'
PRIVATEKEY='/Users/kksante/Documents/GitHub/Earths_Emotion_Tracker/terraform/mykeypair'

# Region
REGION='us-west-2'

# Packer image version
PACKERV='2.0'

# Directories
PACKERHOME='/Users/kksante/Documents/GitHub/Earths_Emotion_Tracker/packer'
TERRAFORMHOME='/Users/kksante/Documents/GitHub/Earths_Emotion_Tracker/terraform'

####################################################################

echo 'Building packer AMI...'

# Update Packer AMI version
gsed -i "/image_version/c\ \ \ \ \"image_version\" : \"${PACKERV}\"" ${PACKERHOME}/packer-spark.json
gsed -i "/image_version/c\ \ \ \ \"image_version\" : \"${PACKERV}\"" ${PACKERHOME}/packer-cassandraql.json
gsed -i "/image_version/c\ \ \ \ \"image_version\" : \"${PACKERV}\"" ${PACKERHOME}/packer-flask.json
gsed -i "/ami_name/c\ \ \ \ \"ami_name\" : \"insight-packer-spark-${PACKERV}\"" ${PACKERHOME}/packer-spark.json
gsed -i "/ami_name/c\ \ \ \ \"ami_name\" : \"insight-packer-cassandraql-${PACKERV}\"" ${PACKERHOME}/packer-cassandraql.json
gsed -i "/ami_name/c\ \ \ \ \"ami_name\" : \"insight-packer-flask-${PACKERV}\"" ${PACKERHOME}/packer-flask.json
gsed -i "/scripts/c\ \ \ \ \"scripts\": \[ \"${PACKERHOME}/scripts/download-and-install-spark.sh\" \]" ${PACKERHOME}/packer-spark.json
gsed -i "/scripts/c\ \ \ \ \"scripts\": \[ \"${PACKERHOME}/scripts/download-and-install-cassandraql.sh\" \]" ${PACKERHOME}/packer-cassandraql.json
gsed -i "/scripts/c\ \ \ \ \"scripts\": \[ \"${PACKERHOME}/scripts/download-and-install-flask.sh\" \]" ${PACKERHOME}/packer-flask.json

# Create AMIs for Spark, cassandraql and Flask
#packer build -machine-readable ${PACKERHOME}/packer-spark.json | tee ${PACKERHOME}/packer-spark.log
#packer build -machine-readable ${PACKERHOME}/packer-cassandraql.json | tee ${PACKERHOME}/packer-cassandraql.log
#packer build -machine-readable ${PACKERHOME}/packer-flask.json | tee ${PACKERHOME}/packer-flask.log
#mv ${PACKERHOME}/*.log ${PACKERHOME}/logs

echo 'Updating Terraform options...'

# # Gather AMI IDs
grep 'amazon-ebs: AMI: ami-' ${PACKERHOME}/logs/packer-spark.log > spark_ami_tmp.txt
grep 'amazon-ebs: AMI: ami-' ${PACKERHOME}/logs/packer-cassandraql.log > cassandraql_ami_tmp.txt
grep 'amazon-ebs: AMI: ami-' ${PACKERHOME}/logs/packer-flask.log > flask_ami_tmp.txt
SPARK_AMI_ID=`egrep -oe 'ami-.*' spark_ami_tmp.txt | tail -n1`
cassandraQL_AMI_ID=`egrep -oe 'ami-.*' cassandraql_ami_tmp.txt | tail -n1`
FLASK_AMI_ID=`egrep -oe 'ami-.*' flask_ami_tmp.txt | tail -n1`
rm *tmp.txt

# Set region
gsed -i "/aws_region/c\variable \"aws_region\" { default = \"${REGION}\" }" ${TERRAFORMHOME}/vars.tf

# Set AMI IDs
gsed -i "/spark/c\ \ \ \ spark = \"${SPARK_AMI_ID}\"" ${TERRAFORMHOME}/vars.tf
gsed -i "/cassandra/c \ \ \ \ cassandra = \"${cassandraQL_AMI_ID}\"" ${TERRAFORMHOME}/vars.tf
gsed -i "/flask/c \ \ \ \ flask = \"${FLASK_AMI_ID}\"" ${TERRAFORMHOME}/vars.tf

# Set number of Spark worker nodes
gsed -i "/NUM_WORKERS/c\variable \"NUM_WORKERS\" { default = ${NSPARK} }" ${TERRAFORMHOME}/vars.tf

# Set public and private keys
gsed -i "/PATH_TO_PUBLIC_KEY/c\variable \"PATH_TO_PUBLIC_KEY\" { default = \"${PUBLICKEY}\" }" ${TERRAFORMHOME}/vars.tf
gsed -i "/PATH_TO_PRIVATE_KEY/c\variable \"PATH_TO_PRIVATE_KEY\" { default = \"${PRIVATEKEY}\" }" ${TERRAFORMHOME}/vars.tf

echo 'Starting Terraform...'

# Run Terraform
cd ${TERRAFORMHOME}
terraform init
terraform apply
