#!/bin/bash


echo 'I AM HERE!!!!!!'

# Set JAVA_HOME
if ! grep "export JAVA_HOME" ~/.profile; then
  sudo echo -e "\nexport JAVA_HOME=/usr" | cat >> ~/.profile
  sudo echo -e "export PATH=\$PATH:\$JAVA_HOME/bin" | cat >> ~/.profile
fi

# Path to S3 bucket for downloading Hadoop and Spark
S3_BUCKET=https://s3-us-west-2.amazonaws.com/insight-tech

# Set code versions
HADOOP_VER=2.7.6
SPARK_VER=2.3.1
SPARK_HADOOP_VER=2.7

# Set file paths
HOME_DIR=/usr/local
HADOOP_URL=${S3_BUCKET}/hadoop/hadoop-$HADOOP_VER.tar.gz
SPARK_URL=${S3_BUCKET}/spark/spark-$SPARK_VER-bin-hadoop$SPARK_HADOOP_VER.tgz

# Download and install Hadoop
curl -sL $HADOOP_URL | gunzip | sudo tar xv -C /usr/local >> ~/peg_log.txt
sudo mv /usr/local/*hadoop* /usr/local/hadoop
echo "export HADOOP_HOME=/usr/local/hadoop" | cat >> ~/.profile
echo -e "export PATH=\$PATH:\$HADOOP_HOME/bin\n" | cat >> ~/.profile
sudo chown -R ubuntu /usr/local/hadoop
eval "echo \$HADOOP_VER" >> /usr/local/hadoop/tech_ver.txt

# Download and install Spark
curl -sL $SPARK_URL | gunzip | sudo tar xv -C /usr/local >> ~/peg_log.txt
sudo mv /usr/local/*spark* /usr/local/spark
echo "export SPARK_HOME=/usr/local/spark" | cat >> ~/.profile
echo -e "export PATH=\$PATH:\$SPARK_HOME/bin\n" | cat >> ~/.profile
sudo chown -R ubuntu /usr/local/spark
eval "echo \$SPARK_VER" >> /usr/local/spark/tech_ver.txt
