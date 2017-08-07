--意向UV（大搜）
select 
      ll.datekey,
      concat
          (
             ll.deal_nums,'~',ll.poi_nums
           ) as deal_poi_nums,
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
  and a.homepage_track like '%homepage_search%'
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
and a.homepage_track like '%homepage_search%'
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
                 datekey,
                 mt_uuid as uuid
            from ba_travel.topic_order a
            where datekey>='$begindatekey'
                  and datekey<='$enddatekey'
                  and sale_platform='mt'
                  and pay_amt>0
            group by 
                  datekey,
                  mt_uuid
     )pay on(ll.datekey=pay.datekey and ll.uuid=pay.uuid)
group by 
      ll.datekey,
      concat
           (
             ll.deal_nums,'~',ll.poi_nums
           )