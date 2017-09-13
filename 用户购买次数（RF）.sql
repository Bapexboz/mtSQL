--用户购买次数的SQL
select aa.monthorder1,
     aa.monthorder2,
     aa.type,
     bb.pay_usernum as firstpay_usernum,
     aa.pay_usernum as repay_usernum
from (
      select a.type,---新老客
a.monthorder monthorder1, ----新用户初次购买月份顺序
b.monthorder monthorder2, ----复购t+N月
count(distinct b.user_id) pay_usernum----t+N月复购用户数

        from (
              select DISTINCT substr(date2datekey(btf.partition_pay_date),1,4) as first_pay_year,---支付年
substr(date2datekey(btf.partition_pay_date),5,2) as first_pay_month, ---支付月
if(bm.type='new','new','old') as type, ---新老客
btf.user_id user_id,
                     dense_rank() over(order by substr(date2datekey(btf.partition_pay_date),1,4),substr(date2datekey(btf.partition_pay_date),5,2)) as monthorder
                from (
                      select DISTINCT datekey,
                             order_key
                        from ba_hotel.hbg_fact_op_reduce_participate
                       where bu_code in (11020,11021,11022)
                         and plantform_source='travel'
                         and sale_platform='mt'
                         and hbg_reduce_value_mt>0
                         and datekey between '$begindatekey' and '$enddatekey'
                     ) bh
                join (
                      select DISTINCT bt.partition_pay_date,---支付日期
bt.order_id, ----订单id
bt.mt_user_id user_id
                        from ba_travel.fact_order_trade bt
                       where date2datekey(bt.partition_pay_date) between '$begindatekey' and '$enddatekey'
                         and bt.bu_code in (11020,11021,11022)
                         and bt.partition_is_paid = 1
                         and bt.sale_platform='mt'
                     ) btf
                  on bh.order_key=btf.order_id
                left join (
                      select distinct 'new' as type,
                             user_type,
                             order_id,
                             datekey
                        from ba_travel.fact_mt_sale_platform_domestic_new_pay_user
                       where datekey between '$begindatekey' and '$enddatekey'
                     ) bm
                  on bh.order_key=bm.order_id
             ) a
        left join (
              select substr(date2datekey(bt.partition_pay_date),1,4) as years,---支付月
substr(date2datekey(bt.partition_pay_date),5,2) as months, ---支付月
bt.mt_user_id user_id,
                     dense_rank() over(order by substr(date2datekey(bt.partition_pay_date),1,4),substr(date2datekey(bt.partition_pay_date),5,2)) as monthorder
                from ba_travel.fact_order_trade bt
               where date2datekey(bt.partition_pay_date) between '$begindatekey' and '$enddatekey'
                 and bt.bu_code in (11020,11021,11022)
                 and bt.partition_is_paid = 1
                 and bt.sale_platform='mt'
               group by substr(date2datekey(bt.partition_pay_date),1,4),
                        substr(date2datekey(bt.partition_pay_date),5,2),
                        bt.mt_user_id
             ) b
          on a.user_id = b.user_id
       where b.monthorder>=a.monthorder
       group by a.type,
                a.monthorder,
                b.monthorder
     ) aa
join (
      select a.monthorder monthorder, ----新用户初次购买月份顺序
a.type,---新老客
count(distinct a.user_id) pay_usernum----当月支付用户数

        from (
              select DISTINCT substr(date2datekey(btf.partition_pay_date),1,4) as first_pay_year,---支付年
substr(date2datekey(btf.partition_pay_date),5,2) as first_pay_month, ---支付月
if(bm.type='new','new','old') as type, ---新老客
btf.user_id user_id,
                     dense_rank() over(order by substr(date2datekey(btf.partition_pay_date),1,4),substr(date2datekey(btf.partition_pay_date),5,2)) as monthorder
                from (
                      select DISTINCT datekey,
                             order_key
                        from ba_hotel.hbg_fact_op_reduce_participate
                       where bu_code in (11020,11021,11022)
                         and plantform_source='travel'
                         and sale_platform='mt'
                         and hbg_reduce_value_mt>0
                         and datekey between '$begindatekey' and '$enddatekey'
                     ) bh
                join (
                      select DISTINCT bt.partition_pay_date,---支付日期
bt.order_id, ----订单id
bt.mt_user_id user_id
                        from ba_travel.fact_order_trade bt
                       where date2datekey(bt.partition_pay_date) between '$begindatekey' and '$enddatekey'
                         and bt.bu_code in (11020,11021,11022)
                         and bt.partition_is_paid = 1
                         and bt.sale_platform='mt'
                     ) btf
                  on bh.order_key=btf.order_id
                left join (
                      select distinct 'new' as type,
                             user_type,
                             order_id,
                             datekey
                        from ba_travel.fact_mt_sale_platform_domestic_new_pay_user
                       where datekey between '$begindatekey' and '$enddatekey'
                     ) bm
                  on bh.order_key=bm.order_id
             ) a
       group by a.monthorder,
                a.type
     ) bb
  on aa.monthorder1=bb.monthorder
 and aa.type=bb.type