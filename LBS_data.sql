select 
    partition_date,
    triggerid,
    bu_type,
    if(channel='1','push','message') as channel,
    populationstrategy,
    copyid,
    send_num,
    act_send_num,
    intent_uv,
    order_uv,
    order_gmv
from mart_semantic.aggr_realtime_delivery_daily
<<<<<<< HEAD
where partition_date between '$begindatekey' and '$enddatekey'
=======
where partition_date  between '$begindatekey' and '$enddatekey'
>>>>>>> 5c65ce2f0a5dcddf256e525b61063cd4e4c496cb
and range='current'