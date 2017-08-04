--地推相关数据
select a.datekey,
      d.province_name,--省份
  d.city_name,--城市
      c.poi_id,--poiid
  c.poi_name,--poi名称
  c.type_name,--品类
  case when newp.user_type = 1 then 'purenew'
       when newp.user_type = 2 then 'turnnew'
else 'old' end as user_type,
  count(distinct a.pay_user_id) as `支付用户数`,
  sum(a.pay_quantity)as `支付券数`,
  count(distinct a.pay_order_id) as `支付订单数`,
  sum(e.hbg_reduce_value) as `补贴金额`,
  sum(a.pay_amt) as `支付GMV`,
  sum(a.consume_amt) as `消费GMV`,
  sum(a.consume_quantity) as `消费券量`,
  sum(a.consume_profit) as `消费毛利`
from ba_travel.bas_groundpromo_order dt
join ba_travel.topic_order_trade a on dt.order_id = a.pay_order_id
join ba_travel.rela_deal_poi_history b on a.datekey=b.datekey and substr(a.product_id,5)=b.deal_id
join ba_hotel.travel_dim_poi c on b.main_poi_id=c.poi_id
join ba_travel.travel_dim_city d on c.city_id=d.city_id
join ba_hotel.hbg_fact_op_reduce_participate e on e.order_key = a.pay_order_id and e.datekey = a.datekey

left join
       (
select distinct datekey, user_id, order_id, user_type
from ba_travel.fact_mt_sale_platform_domestic_new_pay_user
where datekey between '$begindatekey' and '$enddatekey'

union all 

select distinct datekey, user_id, order_id, user_type
from ba_travel.fact_dp_sale_platform_domestic_new_pay_user  
where datekey between '$begindatekey' and '$enddatekey')newp
      	on newp.order_id = dt.order_id --纯新转新用户

where a.datekey between '$begindatekey' and '$enddatekey'
and c.category_id<>371 and c.category_id<>796 and c.type_id not in (795,796)
and e.bu_code in (11020,11021,11022)
and e.plantform_source='travel'
and e.hbg_reduce_value>0
and c.merge_id = 0 
and d.is_enabled = 1 

group by a.datekey,
      d.province_name,--省份
  d.city_name,--城市
      c.poi_id,--poiid
  c.poi_name,--poi名称
  c.type_name,--品类
  case when newp.user_type = 1 then 'purenew'
       when newp.user_type = 2 then 'turnnew'
else 'old' end