select substr(a.datekey,1,6)as `月份`,
      d.area_name_mp,--区域
  d.province_name,--省份
  d.city_name,--城市
      c.poi_id,--poiid
  c.poi_name,--poi名称
  c.type_name,--品类
  b.deal_id,
  count(distinct a.pay_user_id) as `支付用户数`,
  sum(a.pay_quantity)as `支付券数`,
  count(distinct a.pay_order_id) as `支付订单数`,
  sum(a.pay_amt) as `支付GMV`,
  sum(a.consume_amt) as `消费GMV`,
  sum(a.consume_profit) as `消费毛利`
from ba_travel.topic_order_trade a 
join ba_travel.rela_deal_poi_history b on a.datekey=b.datekey and substr(a.product_id,5)=b.deal_id
join ba_hotel.travel_dim_poi c on b.main_poi_id=c.poi_id
join ba_travel.travel_dim_city d on c.city_id=d.city_id
where a.datekey between '$begindatekey' and '$enddatekey' 
and a.bu_code in (11020,11021,11022)
and c.merge_id=0 
and d.is_enabled=1 
group by substr(a.datekey,1,6),
        d.area_name_mp,
    d.province_name,
    d.city_name,
        c.poi_id,
    c.poi_name,
    c.type_name,
b.deal_id