#!/bin/bash
GPHOME=/home/gpadmin/greenplum-db/.

# Replace with symlink path if it is present and correct
if [ -h ${GPHOME}/../greenplum-db ]; then
    GPHOME_BY_SYMLINK=`(cd ${GPHOME}/../greenplum-db/ && pwd -P)`
    if [ x"${GPHOME_BY_SYMLINK}" = x"${GPHOME}" ]; then
        GPHOME=`(cd ${GPHOME}/../greenplum-db/ && pwd -L)`/.
    fi
    unset GPHOME_BY_SYMLINK
fi
#setup PYTHONHOME
if [ -x $GPHOME/ext/python/bin/python ]; then
    PYTHONHOME="$GPHOME/ext/python"
fi
PYTHONPATH=$GPHOME/lib/python
PATH=$GPHOME/bin:$PYTHONHOME/bin:$PATH
LD_LIBRARY_PATH=$GPHOME/lib:$PYTHONHOME/lib:$LD_LIBRARY_PATH

source ~/.bashrc

#发送钉钉的方法
function toDD(){
    DingHook=https://oapi.dingtalk.com/robot/send?access_token=d973555150d57e3be5ca6af8885fa14aad1733c68608d6ea4c3ec7ffd6d9cbd1
    #json='{"hool_url": "'${DingHook}'","content":"'$1'","isatall": false}'
    curl -H "Content-Type:application/json" -X POST -d '{"hool_url": "'${DingHook}'","content":"'$1'","isatall": false}'    172.16.15.201:8080/api/notice/dingding/send
}


#进入当前工作目录
basepath=$(cd `dirname $0`; pwd)
cd $basepath

export GPHOME
export PATH
export LD_LIBRARY_PATH
export PYTHONPATH
export PYTHONHOME
export OPENSSL_CONF

export MASTER_DATA_DIRECTORY=/greenplum/gpdata/master/gpseg-1

echo "当前工作目录|$basepath"
#备份目录|需要在每一个节点上配置
backupdir="/greenplum/gpbak"
logdir=$backupdir
#备份文件备份主机名或ID 需要配置免密登陆
target_server_name="bi-etlserver"
#备份文件备份主机的目录|这里最后边带上/防止下边因为这个把跟目录删除了|重要呀
target_server_path="/data/srcdata/gpdb/"
#GP库主机列表文件名字
gp_segment_list_file="gp_bak.host"

$(toDD "提示:GP集群开始备份")

echo "!!基础参数!!"
echo "数据库备份目录|$backupdir"
echo "备份文件备份主机|$target_server_name"
echo "备份文件备份主机目录|$target_server_path"
echo "备份命令"

echo "删除历史备份|gpssh -f $gp_segment_list_file rm -rf /greenplum/gpbak/db_dumps/*"
#清空备份目录内容|注意这里一定不要删除错了|生命危险
gpssh -f $gp_segment_list_file rm -rf /greenplum/gpbak/db_dumps/*

if [ $? -ne 0 ];then
 $(toDD "错误:删除GP集群备份目录失败|gpssh -f $gp_segment_list_file rm -rf /greenplum/gpbak/db_dumps/*")
 exit 1
fi

$(toDD "提示:删除GP集群备份目录成功--开始执行备份命令")

export DATE=$(date +"%Y%m%d%H%M""00")

#还原命令
#gpdbrestore -d /greenplum/gpdata/master/gpseg-1 --table-file table.lilst --truncate --restore-stats include -t 20200912200000 -u /greenplum/bakup 

# 备份命令
gpcrondump -x sjck_fb \
-a \
-s int_zx \
-s ods \
-s wb \
-B 2 \
-C \
-g \
-G \
-h \
-r \
--dump-stats \
--rsyncable \
-u $backupdir \
-l $backupdir \
-K $DATE

#如果备份失败，直接抛出异常
if [ $? -ne 0 ];then
$(toDD "错误:执行备份命令失败")
exit 1
fi

$(toDD "提示:执行备份命令成功--开始备份")

#数据库备份完成后，将备份文件备份到ETL服务器
for line in $(cat $gp_segment_list_file)
do
  #需要配置免密登陆|在目标服务器上创建GP节点的对应目录
  echo "创建目标目录|ssh $target_server_name mkdir -p $target_server_path$line"
  ssh $target_server_name mkdir -p $target_server_path$line
  
  if [ $? -ne 0 ];then
  $(toDD "错误:创建备份文件目录失败|ssh $target_server_name mkdir -p $target_server_path$line")
   exit 1
  fi
  
  echo "上传备份文件|gpssh -h $line rsync -avz $backupdir/db_dumps $target_server_name:$target_server_path$line"
  #备份节点数据到备份服务器
  gpssh -h $line rsync -avz $backupdir/db_dumps $target_server_name:$target_server_path$line
  
  if [ $? -ne 0 ];then
  $(toDD "错误:备份文件失败|gpssh -h $line rsync -avz $backupdir/db_dumps $target_server_name:$target_server_path$line")
   exit 1
  fi
done

$(toDD "提示:整个备份成功!!!!")

