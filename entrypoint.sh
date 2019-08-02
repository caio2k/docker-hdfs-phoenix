#!/bin/bash -x

#debian
#/etc/init.d/ssh start

#alpine
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys 
if [ ! -d "/var/run/sshd" ]; then
  mkdir -p /var/run/sshd
fi
/usr/sbin/sshd

hdfs namenode -format # Format the filesystem

cd $HADOOP_HOME
sbin/start-dfs.sh     # Start NameNode daemon and DataNode daemon
sbin/start-yarn.sh
sbin/httpfs.sh start  # Start HttpFS

cd $HBASE_HOME
bin/start-hbase.sh
bin/hbase-daemon.sh start rest

cd $PHOENIX_HOME
bin/queryserver.py start &
sleep 2

cd /

if [[ $# -eq 0 ]]; then
    jps
    find $HADOOP_HOME/logs/ $HBASE_HOME/logs/ /tmp/phoenix/ -iname *.log -type f -exec tail -f {} \+
else
    /bin/bash "$@"
fi
