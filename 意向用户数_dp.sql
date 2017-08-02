select 
      ll.datekey,
      concat
          (
             ll.deal_nums,'~',ll.poi_nums
           ) as deal_poi_nums,
      count(distinct ll.dp_id) as `意向用户数`,
      count(distinct pay.dp_id) as `支付用户数`
from 
  (
    select 
      ll.datekey,
      ll.dp_id,
      sum(ll.deal_nums) as deal_nums,
      sum(ll.poi_nums) as poi_nums
      from 
        (
                  select
                      a.datekey,
                      a.dp_id,
                      0 as deal_nums,
                      count(distinct a.shop_id) as poi_nums
                  from ba_travel.topic_traffic_dp as a
                  where a.client_type in ('iphone','android')
                      and a.datekey>='20170724'
                      and a.datekey<='20170730'
                      and a.page_type='poidetail'
                  group by 
                      a.datekey,
                      a.dp_id
                 
                  union all
   
                  select
                      a.datekey,
                      a.dp_id,
                      count(distinct a.deal_id) as deal_nums,
                      0 as poi_nums
                  from ba_travel.topic_traffic_dp as a
                     left join ba_travel.dim_deal as b
                        on a.deal_id = b.deal_id
                where a.client_type in ('iphone','android')
                    and a.datekey>='20170724'
                        and a.datekey<='20170730'
                    and a.page_type in ('dealdetail','createorder')
                    and b.bu_code in  ('11020','11021','11022')
                group by 
                      a.datekey,
                      a.dp_id
          ) ll
    group by 
        ll.datekey,
        ll.dp_id
     ) ll
     left outer join 
     (
            select
                 datekey,
                 dp_id
            from ba_travel.topic_order a
            where datekey>='20170724'
                  and datekey<='20170730'
                  and sale_platform='dp'
                  and pay_amt>0
            group by 
                  datekey,
                  dp_id
     )pay on(ll.datekey=pay.datekey and ll.dp_id=pay.dp_id)
group by 
      ll.datekey,
      concat
           (
             ll.deal_nums,'~',ll.poi_nums
           )