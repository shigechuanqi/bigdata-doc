# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Set Hive and Hadoop environment variables here. These variables can be used
# to control the execution of Hive. It should be used by admins to configure
# the Hive installation (so that users do not have to set environment variables
# or set command line parameters to get correct behavior).
#
# The hive service being invoked (CLI etc.) is available via the environment
# variable SERVICE


# Hive Client memory usage can be an issue if a large number of clients
# are running at the same time. The flags below have been useful in 
# reducing memory usage:
#
#if [ "$SERVICE" = "cli" ]; then
#  if [ -z "$DEBUG" ]; then
#    export HADOOP_OPTS="$HADOOP_OPTS -XX:NewRatio=12 -Xms10m -XX:MaxHeapFreeRatio=40 -XX:MinHeapFreeRatio=15 -XX:+UseParNewGC -XX:-UseGCOverheadLimit"
#  else
#    export HADOOP_OPTS="$HADOOP_OPTS -XX:NewRatio=12 -Xms10m -XX:MaxHeapFreeRatio=40 -XX:MinHeapFreeRatio=15 -XX:-UseGCOverheadLimit"
#  fi
#fi

#export CLIENT_JVMFLAGS="$CLIENT_JVMFLAGS -Dzookeeper.sasl.client=false -Djava.security.auth.login.config=/opt/hive/conf/client-jaas.conf"
# REQUIRED SASL RELATED CONFIGS:
# ==== java.security.auth.login.config:
# Defining your client side JAAS config file path:
#CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Djava.security.auth.login.config=/opt/hive/conf/client-jaas.conf"

# OPTIONAL SASL RELATED CONFIGS:


export JVMFLAGS="$JVMFLAGS -Djava.security.auth.login.config=/opt/hive/conf/client-jaas.conf"


# The heap size of the jvm stared by hive shell script can be controlled via:
#
# export HADOOP_HEAPSIZE=1024
#
# Larger heap size may be required when running queries over large number of files or partitions. 
# By default hive shell scripts use a heap size of 256 (MB).  Larger heap size would also be 
# appropriate for hive server.


# Set HADOOP_HOME to point to a specific hadoop install directory
HADOOP_HOME=/opt/hadoop-3.1.3

# Hive Configuration Directory can be controlled by:
export HIVE_CONF_DIR=/opt/hive/conf

# Folder containing extra libraries required for hive compilation/execution can be controlled by:
# export HIVE_AUX_JARS_PATH=



# ==== zookeeper.sasl.client:
# You can disable SASL authentication on the client side (it is true by default):
#CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.sasl.client=false"

# ==== zookeeper.server.principal:
# Setting the server principal of the ZooKeeper service. If this configuration is provided, then
# the ZooKeeper client will NOT USE any of the following parameters to determine the server principal:
# zookeeper.sasl.client.username, zookeeper.sasl.client.canonicalize.hostname, zookeeper.server.realm
# Note: this config parameter is working only for ZooKeeper 3.5.7+, 3.6.0+
#CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.server.principal=hive"

# ==== zookeeper.sasl.client.username:
# Setting the 'user' part of the server principal of the ZooKeeper service, assuming the
# zookeeper.server.principal parameter is not provided. When you have zookeeper/myhost@EXAMPLE.COM
# defined in your server side SASL config, then use:
#CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.sasl.client.username=hive"

# ==== zookeeper.sasl.client.canonicalize.hostname:
# Assuming the zookeeper.server.principal parameter is not provided, the ZooKeeper client will try to
# determine the 'instance' (host) part of the ZooKeeper server principal. First it takes the hostname provided
# as the ZooKeeper server connection string. Then it tries to 'canonicalize' the address by getting
# the fully qualified domain name belonging to the address. You can disable this 'canonicalization'
# using the following config:
#CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.sasl.client.canonicalize.hostname=false"

# ==== zookeeper.server.realm:
# Setting the 'realm' part of the server principal of the ZooKeeper service, assuming the
# zookeeper.server.principal parameter is not provided. By default, in this case the ZooKeeper Client
# will use its own realm. You can override this, e.g. when you have zookeeper/myhost@EXAMPLE.COM
# defined in your server side SASL config, then use:
#CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.server.realm=HADOOP.COM"

# ==== zookeeper.sasl.clientconfig:
# you can have multiple contexts defined in a JAAS.conf file. ZooKeeper client is using the section
# named as 'Client' by default. You can override it if you wish, by using:
#CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.sasl.clientconfig=Client"

