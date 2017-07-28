select  
       '减类' as `补贴类型`,
       aa.datekey,  ---日期
       aa.sale_platform, ---平台
       aa.poi_id,   ----POIID
       aa.poi_name,  ----POINAME
       aa.deal_id,   ----dealID
       aa.deal_name,  ---dealNAME
       aa.type,         ---用户类型
       aa.activity_id,  ---活动ID
       aa.activity_name,  ---活动名称
       aa.creator_name,   ----创建者
       aa.pay_order_num,  ----支付订单数
       aa.pay_amount,    ----支付GMV
       aa.pay_quantity,  ----支付券量
       aa.zfbt,        ----支付补贴
       aa.pay_user_num,  ----支付用户数
       cc.tkbt,    ----退款补贴
       aa.zfbt-cc.tkbt  as xfbt,   ----消费补贴
       bb.consume_order_num,  ---消费订单数
       bb.consume_amount,  ---消费GMV
       bb.consume_quantity,  ---消费券数
       bb.consume_profit,   ----消费毛收入
       bb.consume_user_num  ---消费用户数

from


(
select 
      b.datekey,
      b.sale_platform,
      b.poi_id,
      b.poi_name,
      b.deal_id,
      b.deal_name,
      if(c.type='new','new','old') as type,
      substr(a.activity_key,5) as activity_id,
      d.active_title as activity_name,
      d.creator_name,
      count(distinct b.pay_order_id) as pay_order_num,--支付订单数
      sum(b.pay_amt) as pay_amount,---支付GMV
      sum(b.pay_quantity) as pay_quantity,---支付券量
      sum(a.zfbt) as zfbt,---支付补贴
      count(distinct b.pay_user_id) as pay_user_num ---支付用户数
from 
(select 
    datekey,
      sale_platform,
    activity_key,
      order_key,
      sum(hbg_reduce_value) as zfbt
from ba_hotel.hbg_fact_op_reduce_participate
where  datekey between  '$begindatekey' and '$enddatekey'
     and  bu_code in (11020,11021,11022)
     and plantform_source='travel'
     and system_type='promotion'
     and hbg_reduce_value>0
group by 
        datekey,
        sale_platform,
        activity_key,
        order_key) a
join
(select 
      distinct
      bt.partition_pay_date datekey,
      bt.sale_platform,
       bp.poi_id,
       bp.poi_name,
       br.deal_id,
       bd.title  deal_name,
      bt.order_id pay_order_id,
      bt.order_amt pay_amt,
      bt.quantity pay_quantity,
      case when bt.sale_platform='mt' then bt.mt_user_id
           when bt.sale_platform='dp' then bt.dp_user_id
      end as pay_user_id
from ba_travel.fact_order_trade  bt
join ba_travel.rela_deal_poi_history br on  substr(bt.product_id,5)=br.deal_id and br.datekey=date2datekey(bt.partition_pay_date)
join  ba_travel.dim_deal bd on br.deal_id=bd.deal_id
join ba_hotel.travel_dim_poi bp on br.main_poi_id=bp.poi_id
where br.datekey between  '$begindatekey' and '$enddatekey'  
     and date2datekey(bt.partition_pay_date)  between '$begindatekey' and '$enddatekey' 
     and bt.bu_code in (11020,11021,11022)) b 
on a.order_key=b.pay_order_id  and  a.sale_platform=b.sale_platform  
left join 
(select
   distinct
      'new' as type,
     order_id,
     datekey
 from

(select 
      distinct
      'new' as type,
     order_id,
     datekey
from ba_travel.fact_mt_sale_platform_domestic_new_pay_user

union all
   select 
      distinct
      'new' as type,
     order_id,
     datekey
from ba_travel.fact_dp_sale_platform_domestic_new_pay_user   

)dn
where dn.datekey  between '$begindatekey' and '$enddatekey')c  
on a.order_key=c.order_id  and a.datekey=c.datekey
left join 
(select activity_key,
     active_title,
     creator_name
from ba_hotel.hbg_dim_activity_info) d on a.activity_key=d.activity_key
group by b.datekey,
      b.sale_platform,
      b.poi_id,
      b.poi_name,
      b.deal_id,
      b.deal_name,
      if(c.type='new','new','old'),
      substr(a.activity_key,5) ,
      d.active_title ,
      d.creator_name 

) aa

left join 
(
 
  select 
      b.datekey,
      b.sale_platform,
      b.poi_id,
      b.poi_name,
      b.deal_id,
      b.deal_name,
      if(c.type='new','new','old') as type,
      substr(a.activity_key,5) as activity_id,
      d.active_title as activity_name,
      d.creator_name,
      count(distinct b.consume_order_id) as consume_order_num,---消费订单数
      sum(b.consume_amt) as consume_amount, ---消费GMV
      sum(b.consume_quantity) as consume_quantity, ---消费券数
      sum(b.consume_profit) as consume_profit,  ---消费毛利
      count(distinct b.consume_user_id) as consume_user_num  ---消费用户数
from 
(select 
    datekey,
      sale_platform,
    activity_key,
      order_key
from ba_hotel.hbg_fact_op_reduce_participate
where bu_code in (11020,11021,11022)
     and plantform_source='travel'
     and system_type='promotion'
     and hbg_reduce_value>0
) a
join
(select 
      bt.datekey,
      bt.sale_platform,
       bp.poi_id,
       bp.poi_name,
       br.deal_id,
       bd.title  deal_name,
      bt.order_id consume_order_id,
      bt.order_price as consume_amt,
      bt.quantity as consume_quantity,
      bt.order_price-bt.buy_price  as consume_profit,
      case when bt.sale_platform='mt' then bt.mt_user_id
          when bt.sale_platform='dp' then bt.dp_user_id
      end as consume_user_id
from ba_travel.fact_consume_trade  bt
join ba_travel.rela_deal_poi_history br on  substr(bt.product_id,5)=br.deal_id and bt.datekey = br.datekey
join  ba_travel.dim_deal bd on br.deal_id=bd.deal_id
join ba_hotel.travel_dim_poi bp on br.main_poi_id=bp.poi_id
where bt.datekey between  '$begindatekey' and '$enddatekey'  
     and bt.bu_code in (11020,11021,11022)) b 
on a.order_key=b.consume_order_id  and  a.sale_platform=b.sale_platform  
left join 
(select
   distinct
      'new' as type,
     order_id,
     datekey
 from

(select 
      distinct
      'new' as type,
     order_id,
     datekey
from ba_travel.fact_mt_sale_platform_domestic_new_pay_user

union all
   select 
      distinct
      'new' as type,
     order_id,
     datekey
from ba_travel.fact_dp_sale_platform_domestic_new_pay_user   

)dn
where dn.datekey  between '$begindatekey' and '$enddatekey')c 
on a.order_key=c.order_id  
left join 
(select activity_key,
     active_title,
     creator_name
from ba_hotel.hbg_dim_activity_info) d on a.activity_key=d.activity_key
group by b.datekey,
      b.sale_platform,
      b.poi_id,
      b.poi_name,
      b.deal_id,
      b.deal_name,
      if(c.type='new','new','old'),
      substr(a.activity_key,5) ,
      d.active_title ,
      d.creator_name 


) bb

on    aa.sale_platform = bb.sale_platform  and aa.poi_id = bb.poi_id  
and aa.deal_id = bb.deal_id and aa.type= bb.type  and aa.activity_id=bb.activity_id

left join
(

select 
      b.datekey,
      b.sale_platform,
      b.poi_id,
      b.poi_name,
      b.deal_id,
      b.deal_name,
      if(c.type='new','new','old') as type,
      substr(a.activity_key,5) as activity_id,
      d.active_title as activity_name,
      d.creator_name,
      sum(a.tkbt) tkbt ---退款补贴
from 
(select 
    datekey,
      sale_platform,
    activity_key,
      order_key,
      sum(hbg_refund_reduce_value) tkbt
from ba_hotel.hbg_fact_op_reduce_refund
where 
     datekey between  '$begindatekey' and '$enddatekey'
     and bu_code in (11020,11021,11022)
     and plantform_source='travel'
     and system_type='promotion'
     and hbg_refund_reduce_value>0
group by 
        datekey,
        sale_platform,
        activity_key,
        order_key) a
join
(select 
      bt.datekey,
      bt.sale_platform,
       bp.poi_id,
       bp.poi_name,
       br.deal_id,
       bd.title  as deal_name,
       bt.order_id  as refund_order_id
from ba_travel.fact_refund_trade  bt
join ba_travel.rela_deal_poi_history br on  substr(bt.product_id,5)=br.deal_id and bt.datekey = br.datekey
join  ba_travel.dim_deal bd on br.deal_id=bd.deal_id
join ba_hotel.travel_dim_poi bp on br.main_poi_id=bp.poi_id
where bt.datekey between  '$begindatekey' and '$enddatekey'  
     and bt.bu_code in (11020,11021,11022)) b 
on a.order_key=b.refund_order_id  and  a.sale_platform=b.sale_platform  
left join 
(select
   distinct
      'new' as type,
     order_id,
     datekey
 from

(select 
      distinct
      'new' as type,
     order_id,
     datekey
from ba_travel.fact_mt_sale_platform_domestic_new_pay_user

union all
   select 
      distinct
      'new' as type,
     order_id,
     datekey
from ba_travel.fact_dp_sale_platform_domestic_new_pay_user   

)dn
where dn.datekey  between '$begindatekey' and '$enddatekey')c 
on a.order_key=c.order_id  
left join 
(select activity_key,
     active_title,
     creator_name
from ba_hotel.hbg_dim_activity_info) d on a.activity_key=d.activity_key
group by b.datekey,
      b.sale_platform,
      b.poi_id,
      b.poi_name,
      b.deal_id,
      b.deal_name,
      if(c.type='new','new','old'),
      substr(a.activity_key,5) ,
      d.active_title ,
      d.creator_name 
) cc
on  aa.sale_platform = cc.sale_platform  and aa.poi_id =cc.poi_id  
and aa.deal_id = cc.deal_id and aa.type= cc.type  and aa.activity_id=cc.activity_id