#!/bin/bash

# Update package manager and get tree package
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt-get update
sudo apt-get install -y tree

# Setup a download and installation directory
HOME_DIR='/home/ubuntu'
INSTALLATION_DIR='/usr/local'
sudo mkdir ${HOME_DIR}/Downloads

# Install Java Development Kit
sudo apt-get --yes --force-yes install ssh rsync openjdk-8-jdk scala python-dev python-pip python-numpy python-scipy python-pandas gfortran git supervisor ruby bc

# Install sbt for Scala
wget https://dl.bintray.com/sbt/debian/sbt-0.13.7.deb -P ~/Downloads
sudo dpkg -i ~/Downloads/sbt-*

# Install maven3
sudo apt-get purge maven maven2 maven3
sudo apt-add-repository -y ppa:andrei-pozolotin/maven3
sudo apt-get update
sudo apt-get --yes --force-yes install maven3

# Set java
sudo update-java-alternatives -s java-1.8.0-openjdk-amd64

# Install Python and boto
sudo apt-get install -y python-pip python-dev build-essential
sudo pip install boto
sudo pip install boto3

# Set JAVA_HOME
if ! grep "export JAVA_HOME" ~/.profile; then
  echo -e "\nexport JAVA_HOME=/usr" | cat >> ~/.profile
  echo -e "export PATH=\$PATH:\$JAVA_HOME/bin" | cat >> ~/.profile
fi

# Path to S3 bucket for downloading Hadoop and Spark
S3_BUCKET=https://s3-us-west-2.amazonaws.com/insight-tech

# Download Hadoop
HADOOP_VER=2.7.6
HADOOP_TAR=hadoop-${HADOOP_VER}.tar.gz
HADOOP_SOURCE_FOLDER=hadoop-${HADOOP_VER}
sudo wget https://s3-us-west-2.amazonaws.com/sparklab-repository/hadoop/${HADOOP_SOURCE_FOLDER}/hadoop-2.7.6.tar.gz -P ${HOME_DIR}/Downloads/
sudo tar zxvf ${HOME_DIR}/Downloads/${HADOOP_TAR} -C ${INSTALLATION_DIR}
sudo mv ${INSTALLATION_DIR}/${HADOOP_SOURCE_FOLDER} ${INSTALLATION_DIR}/hadoop
echo "export HADOOP_HOME=/usr/local/hadoop" | cat >> ~/.profile
echo -e "export PATH=\$PATH:\$HADOOP_HOME/bin\n" | cat >> ~/.profile
sudo chown -R ubuntu ${INSTALLATION_DIR}/hadoop
eval "echo \$HADOOP_VER" >> /usr/local/hadoop/tech_ver.txt

# Download Spark
SPARK_SOURCE_FOLDER=spark-2.3.1-bin-hadoop2.7
SPARK_VER=2.3.1
SPARK_HADOOP_VER=2.7
SPARK_TAR=spark-2.3.1-bin-hadoop2.7.tgz
SPARK_URL=https://s3-us-west-2.amazonaws.com/sparklab-repository/spark/spark-2.3.1/spark-2.3.1-bin-hadoop2.7.tgz
sudo wget ${SPARK_URL} -P ${HOME_DIR}/Downloads/
sudo tar zxvf ${HOME_DIR}/Downloads/${SPARK_TAR} -C ${INSTALLATION_DIR}
sudo mv ${INSTALLATION_DIR}/${SPARK_SOURCE_FOLDER} ${INSTALLATION_DIR}/spark
echo "export SPARK_HOME=/usr/local/spark" | cat >> ~/.profile
echo -e "export PATH=\$PATH:\$SPARK_HOME/bin\n" | cat >> ~/.profile
sudo chown -R ubuntu ${INSTALLATION_DIR}/spark
eval "echo \$SPARK_VER" >> /usr/local/spark/tech_ver.txt
