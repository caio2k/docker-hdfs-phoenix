FROM openjdk:8-alpine

RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/environment

# Debian package install and configure
RUN apk add --no-cache openssh openrc curl bash procps python

### Enable passwordless SSH
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    sh -c '/bin/echo -e "y\n" | ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key' && \
    sh -c '/bin/echo -e "y\n" | ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa' && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
    sed -i s/ask/no/ /etc/ssh/ssh_config && \
    sed -i '/^#.* StrictHostKeyChecking /s/^#//' /etc/ssh/ssh_config && \
    echo "    UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
RUN echo "root:root" | chpasswd

#HDP 3.1.0
#ARG HADOOP_VERSION=3.1.1
#ARG HBASE_MAJOR=2.0
#ARG PHOENIX_VERSION=5.0.0

#HDP 2.6.5
ARG HADOOP_VERSION=2.7.3
ARG HBASE_MAJOR=1.1
ARG PHOENIX_VERSION=4.7.0

ENV HBASE_VERSION=${HBASE_MAJOR}.2 PHOENIX_FULL_VERSION=${PHOENIX_VERSION}-HBase-${HBASE_MAJOR}
ENV PHOENIX_FILENAME=phoenix-${PHOENIX_VERSION}-HBase-${HBASE_MAJOR}

# Download Hadoop and HDFS
RUN curl -fsSL "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" | tar -zx && ln -s hadoop-$HADOOP_VERSION hadoop
RUN curl -fsSL "http://archive.apache.org/dist/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz" | tar -zx && ln -s hbase-$HBASE_VERSION hbase
RUN curl -fsSL "http://archive.apache.org/dist/phoenix/${PHOENIX_FILENAME}/bin/${PHOENIX_FILENAME}-bin.tar.gz" | tar -xz && ln -s ${PHOENIX_FILENAME}-bin phoenix

# Configure Hadoop env variables
ENV HADOOP_HOME="/hadoop" HADOOP_PREFIX="/hadoop" HBASE_HOME="/hbase" PHOENIX_HOME="/phoenix"
ENV HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop/" HADOOP_MAPRED_HOME="$HADOOP_HOME" HADOOP_COMMON_HOME="$HADOOP_HOME" HADOOP_HDFS_HOME="$HADOOP_HOME" YARN_HOME="$HADOOP_HOME" HADOOP_CONFDIR="${HADOOP_HOME}/etc/hadoop" HADOOP_COMMON_LIB_NATIVE_DIR="${HADOOP_PREFIX}/lib/native" HADOOP_OPTS="-Djava.library.path=${HADOOP_PREFIX}/lib/native" JAVA_LIBRARY_PATH="$HADOOP_HOME/lib/native:$JAVA_LIBRARY_PATH" PATH="$PATH:$HADOOP_HOME/bin:$HBASE_HOME/bin:$PHOENIX_HOME/bin"

RUN sed -i "s@export JAVA_HOME=.*@export JAVA_HOME=${JAVA_HOME}@g" $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && \
    sed -i "s@.* export JAVA_HOME=.*@export JAVA_HOME=${JAVA_HOME}@g" $HBASE_HOME/conf/hbase-env.sh

#Prepare Hadoop config files
ADD core-site.xml hdfs-site.xml mapred-site.xml $HADOOP_CONF_DIR/
ADD hbase-site.xml $HBASE_HOME/conf/

#Add phoenix libraries into HBase
RUN cp $PHOENIX_HOME/phoenix-core-$PHOENIX_FULL_VERSION.jar $HBASE_HOME/lib/phoenix.jar && \
    cp $PHOENIX_HOME/phoenix-server-$PHOENIX_FULL_VERSION.jar $HBASE_HOME/lib/phoenix-server.jar

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# phoenix query server port
EXPOSE 8765
# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
