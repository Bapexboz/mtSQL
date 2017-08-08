--by POI的分新老客&意向UV的数据
select   DISTINCT
     aa.datekey,
     aa.poi_id,
     aa.poi_name,
     ff.intention_uvNum,
 case when ee.user_type = 1 then '纯新'
  when ee.user_type = 2 then '转新'
  else '老客' end as user_type,
     ee.pay_userNum,
 ee.pay_order_num,
 ee.pay_amt,
 ee.pay_quantity,
 ee.consume_amt,
 ee.consume_profit     
from (
      select  t5.datekey,
           bp.poi_id,
           bp.poi_name
        from ba_travel.rela_deal_poi_history t2
       inner join ba_hotel.travel_dim_poi bp
          on bp.poi_id=t2.main_poi_id
       inner join ba_travel.dim_deal_history t5 on(t2.deal_id=t5.deal_id)
       where t5.datekey  between '$begindatekey' and '$enddatekey'
         and t2.datekey  between  '$begindatekey' and '$enddatekey'
         and t5.is_online_flag=1
         and bp.category_id<>371 and bp.category_id<>796 and bp.type_id not in (795,796)
     ) aa
inner join (
      select  bt.datekey,
           br.poi_id,
xy.user_type,
           count(distinct bt.pay_order_id) as pay_order_num,
           count(distinct bt.pay_user_id) as pay_userNum,
       sum(bt.pay_quantity)as pay_quantity,
       sum(bt.pay_amt) as pay_amt,
       sum(bt.consume_amt) as consume_amt,
       sum(bt.consume_profit) as consume_profit
           from ba_travel.topic_mt_sale_platform_order_trade bt

           join (select btr.deal_id deal_id, btr.main_poi_id poi_id
                 from  ba_travel.rela_deal_poi_history btr       
                 where btr.datekey  between  '$begindatekey' and '$enddatekey'
                  ) br on  substr(bt.product_id,5)=br.deal_id
  
left join (select distinct datekey, user_id, user_type
          from ba_travel.fact_mt_sale_platform_new_pay_user
  where datekey between '$begindatekey' and '$enddatekey')xy on xy.datekey = bt.datekey and xy.user_id = bt.pay_user_id
  
       where bt.datekey between  '$begindatekey' and '$enddatekey'
       group by bt.datekey,
             br.poi_id,
 xy.user_type
     )ee
  on aa.poi_id = ee.poi_id
 and ee.datekey = aa.datekey
inner join (
      select
  t.datekey,
  t.poi_id,
  count(distinct t.dayuuid) as intention_uvNum  -- 意向uv
from
  (
      select
          a.datekey,
          b.main_poi_id poi_id,
          concat(a.datekey,a.uuid) as dayuuid     
      from ba_travel.topic_traffic_mt as a
      join ba_travel.rela_deal_poi_history  b
      on a.deal_id=b.deal_id 
      left join ba_travel.dim_deal c
      on a.deal_id=c.deal_id
      where a.client_type in ('iphone','android')
          and a.datekey between  '$begindatekey' and '$enddatekey'
          and b.datekey between  '$begindatekey' and '$enddatekey'
          and a.page_type in ('dealdetail','createorder')
          and c.bu_code in ('11020','11021','11022')

      union all

      select
          a.datekey,
          a.poi_id poi_id,
          concat(a.datekey,a.uuid) as dayuuid
      from ba_travel.topic_traffic_mt as a
      where a.client_type in ('iphone','android')
          and a.datekey between  '$begindatekey' and '$enddatekey'
          and a.page_type='poidetail'
  ) t
group by
  t.datekey,
  t.poi_id
     )ff
  on  aa.poi_id=ff.poi_id
 and aa.datekey = ff.datekey