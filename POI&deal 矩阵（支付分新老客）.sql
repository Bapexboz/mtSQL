--POI&deal 矩阵（支付分新老客）

select 
      ll.datekey,
      concat
          (
             ll.deal_nums,'~',ll.poi_nums
           ) as deal_poi_nums,
if(pay.user_type in (1,2),'新客','老客') as user_type,
      count(distinct ll.uuid) as `意向用户数`,
      count(distinct pay.uuid) as `支付用户数`
from 
  (
    select 
      ll.datekey,
      ll.uuid,
      sum(ll.deal_nums) as deal_nums,
      sum(ll.poi_nums) as poi_nums
      from 
        (
                  select
                      a.datekey,
                      a.uuid,
                      0 as deal_nums,
                      count(distinct a.poi_id) as poi_nums
                  from ba_travel.topic_traffic_mt as a
                  where a.client_type in ('iphone','android')
                      and a.datekey>='$begindatekey'
                      and a.datekey<='$enddatekey'
                      and a.page_type='poidetail'
                  group by 
                      a.datekey,
                      a.uuid
                 
                  union all
   
                  select
                      a.datekey,
                      a.uuid,
                      count(distinct a.deal_id) as deal_nums,
                      0 as poi_nums
                  from ba_travel.topic_traffic_mt as a
                     left join ba_travel.dim_deal as b
                        on a.deal_id = b.deal_id
                where a.client_type in ('iphone','android')
                    and a.datekey>='$begindatekey'
                        and a.datekey<='$enddatekey'
                    and a.page_type in ('dealdetail','createorder')
                    and b.bu_code in  ('11020','11021','11022')
                group by 
                      a.datekey,
                      a.uuid
          ) ll
    group by 
        ll.datekey,
        ll.uuid
     ) ll
     left outer join 
     (
            select
                 t.datekey,
                 t.mt_uuid as uuid,
 xy.user_type
            from ba_travel.topic_order t
left join (select distinct datekey, user_id, user_type
          from ba_travel.fact_mt_sale_platform_new_pay_user
  where datekey between '$begindatekey' and '$enddatekey')xy on xy.datekey = t.datekey and xy.user_id = t.pay_mt_user_id
            where t.datekey>='$begindatekey'
                  and t.datekey<='$enddatekey'
                  and t.sale_platform='mt'
                  and t.pay_amt>0
            group by 
                  t.datekey,
                 t.mt_uuid,
 xy.user_type
     )pay on(ll.datekey=pay.datekey and ll.uuid=pay.uuid)
group by 
      ll.datekey,
      concat
           (
             ll.deal_nums,'~',ll.poi_nums
           ),
if(pay.user_type in (1,2),'新客','老客')