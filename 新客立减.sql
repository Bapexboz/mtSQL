--新客立减SQL，日期格式：YYYYMMDD

select g.deal_id,
   g.poi_id,
   g.title,
   h.region_name, -- 区域名称
   h.city_name,  -- 城市
   g.type_name,  -- 品类名称
   g.ticket_cate_name, -- 票种名称
   g.is_third_party,
   g.mtp_mp_price, -- 售价
   g.profit, -- 毛利（售价减进价）
   g.mt_pay_user_num, -- 支付用户数
   g.mt_pay_amount,  -- GMV
   g.mt_consume_quantity, -- 消费券数
   g.mt_consume_profit, -- 消费毛利（消费毛收入）
   g.mt_refund_rate
from
(select case when (f.min_third_party=1 and f.is_third_party=0 )
  or (f.min_third_party=1 and f.is_third_party=1 and f.rank=1) then f.deal_id else null end as deal_id,
  f.poi_id,
  f.title,
  f.type_name,  -- 品类名称
  f.ticket_cate_name, -- 票种名称
  f.is_third_party,
  f.mtp_mp_price, -- 售价
  f.profit, -- 毛利（售价减进价）
  f.mt_pay_user_num, -- 支付用户数
  f.mt_pay_amount,  -- GMV
  f.mt_consume_quantity, -- 消费券数
  f.mt_consume_profit, -- 消费毛利（消费毛收入）
  f.mt_refund_rate
from
(select c.deal_id,
  c.poi_id,
  c.title,
  c.type_name,  -- 品类名称
  e.ticket_cate_name, -- 票种名称
  c.is_third_party,
  c.mtp_mp_price,-- 售价
  c.profit, -- 毛利（售价减进价）
  d.mt_pay_user_num, -- 支付用户数
  d.mt_pay_amount,  -- GMV
  d.mt_consume_quantity, -- 消费券数
  d.mt_consume_profit, -- 消费毛利（消费毛收入）
  d.mt_refund_rate, -- 退款率
  c.min_third_party,
  row_number() over (partition by c.poi_id,e.ticket_cate_name order by mt_consume_profit desc) as rank
from
(select a.deal_id,
  b.poi_id,
  a.title,
  a.type_name,
  a.is_third_party,
  rank() over (partition by b.poi_id order by a.is_third_party) as min_third_party,
  a.mtp_mp_price,
  round(a.mtp_mp_price-a.mtp_mp_settlement_price,2) as profit
from ba_travel.dim_deal a join ba_travel.rela_ticket_poi_deal b on a.deal_id=b.deal_id
where a.is_online_flag=1
 and a.end_time>='$endday' -- YYYY-MM-DD
 and a.bu_code=11020)c
left join
(select substr(product_id,5) as deal_id,
count(distinct pay_user_id) as mt_pay_user_num,
sum(pay_amt) as mt_pay_amount,
sum(consume_quantity) as mt_consume_quantity,
sum(consume_profit) as mt_consume_profit,
sum(refund_amt)/sum(pay_amt) as mt_refund_rate
from ba_travel.topic_mt_sale_platform_order_trade
where datekey2date(datekey) BETWEEN '$beginday' AND '$endday' -- YYYY-MM-DD
and bu_code=11020 -- 11020:门票,11021:跟团游,11030:境外度假,11022:酒景
and pay_amt>0
group by substr(product_id,5))d on c.deal_id=d.deal_id
join ba_travel.fact_poi_ticket_cate e on c.deal_id=e.deal_id and c.poi_id=e.poi_id
where datekey2date(e.datekey)='$endday'
 and c.profit>=2.5
 and d.mt_refund_rate<=0.25)f )g
join ba_travel.dim_ticket_poi h on g.poi_id=h.poi_id
where g.deal_id is not null