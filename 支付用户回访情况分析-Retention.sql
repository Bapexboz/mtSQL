select distinct aa.datekey1,aa.datekey2,bb.pay_user_num,aa.revisit_num
from
(select y.datekey as datekey1,x.datekey as datekey2,count(distinct x.user_id) revisit_num
from 
(select distinct datekey datekey, user_id
from ba_travel.fact_mt_sale_platform_domestic_new_pay_user
where datekey between '$begindatekey' and '$enddatekey')y

left join 


(select distinct a.datekey datekey, c.user_id
from ba_travel.log_domestic_intention_mt_new_uuid a
join ba_travel.topic_order_date c on a.uuid=c.uuid and c.datekey between '$begindatekey' and '$enddatekey'
and a.datekey between '$begindatekey' and '$enddatekey' )x  on x.user_id = y.user_id 
where x.datekey>=y.datekey
group by  x.datekey,y.datekey  ) aa   

join 
(select datekey,count(distinct user_id) pay_user_num
from ba_travel.fact_mt_sale_platform_domestic_new_pay_user
where datekey between '$begindatekey' and '$enddatekey'
group by datekey)bb 

on aa.datekey1=bb.datekey