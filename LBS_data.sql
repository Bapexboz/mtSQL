select 
    partition_date,
    triggerid,
    bu_type,
    populationstrategy,
    copyid,
    send_num,
    act_send_num,
    intent_uv,
    order_uv,
    order_gmv
from mart_semantic.aggr_realtime_delivery_daily
where partition_date ='2017-08-21' and '2017-08-27'
and range='current'