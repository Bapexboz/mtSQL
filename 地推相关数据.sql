--地推相关数据
select
     b.datekey,
     e.activity_id,
     d.scene_id,
     d.bd_mis,
 y.rank_strategy,
 m.type_name,
     g.poi_id,
 g.poi_name,
     c.promoter_name,
 case when i.user_type = 1 then '纯新'
      when i.user_type = 2 then '转新'
  else '老客' end as user_type,
     count(distinct b.pay_order_id) as `支付订单数`,
     sum(b.pay_quantity) as `支付券量`,
 sum(b.pay_amt)as `支付GMV`,
     count(distinct b.pay_user_id) as `支付用户数`,
     sum(x.hbg_reduce_value) as `补贴金额`,
 sum(b.consume_amt) as `消费GMV`,
 sum(b.consume_quantity) as `消费券量`,
 sum(b.consume_profit) as `消费毛利`   
from ba_travel.bas_groundpromo_order a
join ba_travel.topic_order_trade b on a.order_id=b.order_id and b.datekey between '$begindatekey' and '$enddatekey' and b.bu_code = 11020
left outer join ba_travel.fact_mt_sale_platform_domestic_new_pay_user i on b.order_id=i.order_id
left outer join ba_travel.bas_groundpromo_rela_scene_promoter c on a.scene_promoter_rela_id=c.rela_id
left outer join ba_travel.bas_groundpromo_scene d on c.scene_id=d.scene_id
left outer join ba_travel.bas_groundpromo_activity e on d.activity_id=e.activity_id
left outer join ba_hotel.hbg_fact_op_reduce_participate x on x.order_key = b.pay_order_id 


left outer join
             (select datekey,
                     deal_id,
                     max(main_poi_id) poi_id
              from ba_travel.rela_deal_poi_history
              where datekey between '$begindatekey' and '$enddatekey'  
              group by datekey,deal_id) f on b.datekey=f.datekey and b.product_id=concat('1001',f.deal_id)

left outer join ba_hotel.travel_dim_poi_history g on g.date_key between '$begindatekey' and '$enddatekey' and f.datekey=g.date_key and f.poi_id=g.poi_id
left outer join ba_travel.travel_dim_city h on g.city_id=h.city_id
left outer join ba_travel.dim_poi_strategy_rank_ginkgo y on y.main_poi_id = g.poi_id
left outer join ba_hotel.travel_dim_poi m on g.main_poi_id=m.poi_id
group by
     b.datekey,
     e.activity_id,
     d.scene_id,
     d.bd_mis,
 y.rank_strategy,
 m.type_name,
     g.poi_id,
 g.poi_name,
     c.promoter_name,
 case when i.user_type = 1 then '纯新'
      when i.user_type = 2 then '转新'
  else '老客' end