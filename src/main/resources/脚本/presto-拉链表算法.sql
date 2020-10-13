/* 重置当前数据到跑批时点快照状态 */
drop table if exists hive.tmpdb.cbs_bbt003
;
create table hive.tmpdb.cbs_bbt003
with (partitioned_by = ARRAY['tmp_tab_type'])
as
select
   st_dt  --date              COMMENT  '开始日期'
   ,ins_dt

,bbhkid  --varchar(100) 还款计划ID
,basqbh  --varchar(100) 融资申请编号
,bbfqxh  --decimal(20,0) 每期序号
,bbcjrq  --timestamp(3) 创建日期
,bbskrq  --timestamp(3) 收款日期
   ,date'2999-12-31' as end_dt --date              COMMENT  '结束日期'
   ,cast('' as varchar(16)) as data_ods_type
   ,cast('yesday_full' as varchar(32)) as tmp_tab_type
from   hive.ods.cbs_bbt003
where  st_dt < date'2020-10-12'
and    end_dt >= date'2020-10-12'
;
/* 与当天数据进行比较 */
insert into hive.tmpdb.cbs_bbt003
with tmp_t1 as --今天的最新数据
(
select *
from  hive.sdata.cbs_bbt003
where etl_dt = date'2020-10-12'
)
,tmp_t2 as --昨天的全量数据
(
select *
from  hive.tmpdb.cbs_bbt003
where tmp_tab_type = 'yesday_full'
and   end_dt = date'2999-12-31'
)
select
if(CAST(t2.bbhkid AS VARCHAR) is not null ,t2.st_dt,date'2020-10-12') as st_dt
,localtimestamp as ins_dt

,if(t1.bbhkid is null,t2.bbhkid,t1.bbhkid) as bbhkid  --varchar(100) 还款计划ID
,t1.basqbh  --varchar(100) 融资申请编号
,t1.bbfqxh  --decimal(20,0) 每期序号
,t1.bbcjrq  --timestamp(3) 创建日期
,t1.bbskrq  --timestamp(3) 收款日期
,if(CAST(t2.bbhkid AS VARCHAR) is not null ,t2.end_dt,date'2999-12-31') as end_dt
,case when CAST(t1.bbhkid AS VARCHAR) is not null and CAST(t2.bbhkid AS VARCHAR) is null
then 'new'
when CAST(t1.bbhkid AS VARCHAR) is null and CAST(t2.bbhkid AS VARCHAR) is not null
then 'del'

when if(t1.bbhkid is null,'',t1.bbhkid) <> if(t2.bbhkid is null,'',t2.bbhkid) then 'chg' --varchar(100)
when if(t1.basqbh is null,'',t1.basqbh) <> if(t2.basqbh is null,'',t2.basqbh) then 'chg' --varchar(100)
when if(t1.bbfqxh is null,999999,t1.bbfqxh) <> if(t2.bbfqxh is null,999999,t2.bbfqxh) then 'chg' --decimal(20,0)
when if(t1.bbcjrq is null,date'1990-01-02',t1.bbcjrq) <> if(t2.bbcjrq is null,date'1990-01-02',t2.bbcjrq) then 'chg' --timestamp(3)
when if(t1.bbskrq is null,date'1990-01-02',t1.bbskrq) <> if(t2.bbskrq is null,date'1990-01-02',t2.bbskrq) then 'chg' --timestamp(3)
else ''
end as data_ods_type
,'today_full' as tmp_tab_type
from      tmp_t1 t1
full join tmp_t2 t2
on        t1.bbhkid = t2.bbhkid
;

/* 设置覆盖目标表分区,分区有两个 date'2020-10-12' + date'2999-12-31' */
set session hive.insert_existing_partitions_behavior = 'OVERWRITE'
;
insert into hive.ods.cbs_bbt003
(
st_dt
,ins_dt

,bbhkid  --varchar(100) 还款计划ID
,basqbh  --varchar(100) 融资申请编号
,bbfqxh  --decimal(20,0) 每期序号
,bbcjrq  --timestamp(3) 创建日期
,bbskrq  --timestamp(3) 收款日期
,end_dt
)
with coled as
(
select    t1.st_dt
,localtimestamp as ins_dt

,if(t1.bbhkid is null,t2.bbhkid,t1.bbhkid) as bbhkid  --varchar(100) 还款计划ID
,t1.basqbh  --varchar(100) 融资申请编号
,t1.bbfqxh  --decimal(20,0) 每期序号
,t1.bbcjrq  --timestamp(3) 创建日期
,t1.bbskrq  --timestamp(3) 收款日期
          ,case when CAST(t2.bbhkid AS VARCHAR) is not null then date'2020-10-12' else t1.end_dt end as end_dt --存在变更+删除的主键封链
from      hive.tmpdb.cbs_bbt003 t1
left join hive.tmpdb.cbs_bbt003 t2
on        t1.bbhkid = t2.bbhkid
and       t2.tmp_tab_type = 'today_full'
and       t2.data_ods_type in ('chg','del')
where     t1.tmp_tab_type = 'yesday_full'
and       t1.end_dt = date'2999-12-31'
)
,today as
(
select    date'2020-10-12' as st_dt
          ,localtimestamp as ins_dt

,bbhkid  --varchar(100) 还款计划ID
,basqbh  --varchar(100) 融资申请编号
,bbfqxh  --decimal(20,0) 每期序号
,bbcjrq  --timestamp(3) 创建日期
,bbskrq  --timestamp(3) 收款日期
          ,date'2999-12-31' as end_dt
from      hive.tmpdb.cbs_bbt003 t2
where     t2.tmp_tab_type = 'today_full'
and       t2.data_ods_type in ('chg','new')
)
select  * from coled
union all
select  * from today
;
/* 操作完成清理目标表无效数据 */
DELETE FROM hive.ods.cbs_bbt003 where end_dt > date'2020-10-12' and end_dt < date'2999-12-31'
;