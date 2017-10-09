select distinct aa.datekey,
      aa.dealid,
  aa.intention_UV,
  bb.pay_userNum,
  bb.reduce_value
from 
(select
  a.datekey,
  b.dealid,
  count(distinct a.uuid) as intention_UV
  from ba_travel.topic_traffic_mt as a
  join upload_table.list b on a.deal_id = b.dealid
  where a.client_type in ('iphone','android')
  and a.datekey between '$begindatekey' and '$enddatekey' --YYYYMMDD
  and a.page_type in ('dealdetail','createorder')
group by a.datekey,
  b.dealid)aa--意向UV
  
left join

        (select a.datekey,
               b.dealid,
count(distinct a.pay_order_id) as pay_ordernum,
               count(distinct a.pay_user_id) as pay_userNum,
sum(c.mt_value) as reduce_value	
        from ba_travel.topic_mt_sale_platform_order_trade a
        join upload_table.list b on substr(a.product_id,5)=b.dealid
left join ba_hotel.hbg_fact_activity_pda_participate c on a.pay_order_id = c.order_key
        where a.datekey between '$begindatekey' and '$enddatekey' --YYYYMMDD
       group by a.datekey,
                b.dealid)bb on aa.datekey = bb.datekey and aa.dealid = bb.dealid