#!/bin/bash

# Read in input variables
CLUSTER=$1
SEED_PRIVATE_IP=$2
NODE_PRIVATE_IP=$3

sudo apt-get install gunzip

S3_BUCKET=http://apache.claz.org/cassandra

CASSANDRA_VER=3.0.17

CASSANDRA_URL=${S3_BUCKET}/${CASSANDRA_VER}/apache-cassandra-${CASSANDRA_VER}-bin.tar.gz


curl -sL $CASSANDRA_URL | gunzip | sudo tar xv -C /usr/local >> ~/peg_log.txt
sudo mv /usr/local/*cassandra* /usr/local/cassandra
echo "export CASSANDRA=/usr/local/cassandra" | cat >> ~/.profile
echo -e "export PATH=\$PATH:\$cassandra/bin\n" | cat >> ~/.profile
sudo chown -R ubuntu /usr/local/cassandra
eval "echo \$$(echo cassandra | tr [a-z] [A-Z])_VER" >> /usr/local/cassandra/tech_ver.txt

. ~/.profile

CASSANDRA_HOME="/usr/local/cassandra"

sed -i "s@cluster_name: 'Test Cluster'@cluster_name: '"$CLUSTER"'@g" $CASSANDRA_HOME/conf/cassandra.yaml
sed -i 's@- seeds: "127.0.0.1"@- seeds: "'"${SEED_PRIVATE_IP%%.*}"'"@g' $CASSANDRA_HOME/conf/cassandra.yaml
sed -i 's@listen_address: localhost@listen_address: '"${NODE_PRIVATE_IP%%.*}"'@g' $CASSANDRA_HOME/conf/cassandra.yaml
sed -i 's@rpc_address: localhost@rpc_address: 0.0.0.0@g' $CASSANDRA_HOME/conf/cassandra.yaml
sed -i 's@\# broadcast_rpc_address: 1.2.3.4@broadcast_rpc_address: '"${NODE_PRIVATE_IP%%.*}"'@g' $CASSANDRA_HOME/conf/cassandra.yaml
sed -i 's@endpoint_snitch: SimpleSnitch@endpoint_snitch: Ec2Snitch@g' $CASSANDRA_HOME/conf/cassandra.yaml
