
--用户补贴报表（分纯新转新）
select 
     m.datekey,
     m.sale_platform,
     if(m.new_user_type=1,'纯新','转新') as new_user_type,
     '立减' as reduce_type,
     m.promotion_activity_id `活动id`,
     m.promotion_activity_name `活动名称`,
     m.promotion_creator_name `活动创建人`,
     count(distinct if(m.is_paid=1,m.order_key,null)) `支付订单数`,
     sum(m.pay_amt) `支付GMV`,
     count(distinct m.pay_user_key) `支付用户数`,
     sum(m.pay_hbg_reduce_amt) `支付补贴`,
     count(distinct if(m.is_consumed=1,m.order_key,null)) `消费订单数`,
     sum(m.consume_amt) `消费GMV`,
     sum(m.consume_profit) `消费毛利`,
     count(distinct m.consume_user_key) `消费用户数`,
     sum(m.pay_hbg_reduce_amt) - sum(m.refund_hbg_reduce_amt) `消费补贴`
  from
       (
           SELECT  
              result.order_key,
              result.week_begin_datekey,
              result.month_begin_datekey,
              result.user_key,
              result.mt_user_id,
              result.dp_user_id,
              result.bu_code,
              result.sale_platform,

              result.reduce_type,
              result.new_user_type,
              result.promotion_activity_id,
              result.promotion_activity_name,
              result.promotion_creator_name,
              result.card_activity_id,
              result.card_activity_name,
              result.card_creator_name,
              result.card_marketing_id,
              result.card_marketing_name,
              result.card_marketing_creator_name,
              result.apply_key,
              result.apply_id, 
              
              result.is_paid,
              IF(result.is_paid=1, result.pay_hbg_reduce_amt, 0.0) AS pay_hbg_reduce_amt,
              IF(result.is_paid=1, result.pay_hbg_promotion_reduce_amt, 0.0) AS pay_hbg_promotion_reduce_amt,
              IF(result.is_paid=1, result.pay_hbg_card_reduce_amt, 0.0) AS pay_hbg_card_reduce_amt,
              result.pay_user_key,
              result.pay_amt,
              result.pay_quantity,
              result.pay_order_cnt,
              result.pay_profit,
              
              result.is_consumed,
              result.consume_user_key,
              result.consume_amt,
              result.consume_quantity,
              result.consume_profit,
              
              result.is_refund,
              result.refund_hbg_reduce_amt,
              result.refund_hbg_promotion_reduce_amt,
              result.refund_hbg_card_reduce_amt,
              result.datekey
        from 
           (select
               sale_order.datekey,    
               dt.week_begin_date_id AS week_begin_datekey,
               dt.month_begin_date_id AS month_begin_datekey,
               sale_order.order_key,
               sale_order.user_key,
               sale_order.mt_user_id,
               sale_order.dp_user_id,
               sale_order.bu_code,
               sale_order.sale_platform,
               pay_reduce.system_type AS reduce_type, -- 2减类 OR 1券类
               IF(sale_order.order_key = new_user_type.order_key, new_user_type.user_type, 0) AS new_user_type,  -- 0:老客 1:纯新 2:转新 补贴口径的新老客(关联订单) 
               pay_reduce.promotion_activity_id,       -- 减类活动信息
               pay_reduce.promotion_activity_name,
               pay_reduce.promotion_creator_name,
               pay_reduce.card_activity_id,        -- 券类活动信息
               pay_reduce.card_activity_name,
               pay_reduce.card_creator_name,
               pay_reduce.marketing_id AS card_marketing_id,   -- 券信息
               pay_reduce.marketing_name AS card_marketing_name,
               pay_reduce.marketing_creator_name AS card_marketing_creator_name,
               pay_reduce.apply_key,
               pay_reduce.apply_id,
               sale_order.pay_user_key,
               sale_order.pay_amt,
               sale_order.pay_quantity,
               sale_order.pay_order_cnt,
               sale_order.pay_profit,
               sale_order.is_paid,          -- 是否支付行为
               (coalesce(pay_reduce.pay_hbg_promotion_reduce_amt,0.0) + coalesce(pay_reduce.pay_hbg_card_reduce_amt,0.0)) AS pay_hbg_reduce_amt,
               coalesce(pay_reduce.pay_hbg_promotion_reduce_amt,0.0) AS pay_hbg_promotion_reduce_amt,
               coalesce(pay_reduce.pay_hbg_card_reduce_amt,0.0) AS pay_hbg_card_reduce_amt,
               sale_order.consume_user_key,
               sale_order.consume_amt,
               sale_order.consume_quantity,
               sale_order.consume_order_key,
               sale_order.consume_profit,
               sale_order.is_consumed,      -- 是否消费行为
               -- 消费补贴=支付补贴-退款补贴 
               (coalesce(refund_reduce.refund_hbg_promotion_reduce_amt,0.0) + coalesce(refund_reduce.refund_hbg_card_reduce_amt,0.0)) AS refund_hbg_reduce_amt,
               coalesce(refund_reduce.refund_hbg_promotion_reduce_amt,0.0) AS refund_hbg_promotion_reduce_amt,
               coalesce(refund_reduce.refund_hbg_card_reduce_amt,0.0) AS refund_hbg_card_reduce_amt,
               sale_order.is_refund
           FROM 
               (SELECT
                   datekey,
                   order_id AS order_key,
                   CONCAT(sale_platform, '_', REGEXP_EXTRACT(COALESCE(pay_user_id, consume_user_id),'\\d{4}(.*)')) AS user_key,
                   IF(sale_platform = 'mt', REGEXP_EXTRACT(COALESCE(pay_user_id, consume_user_id),'\\d{4}(.*)'), null) AS mt_user_id,
                   IF(sale_platform = 'dp', REGEXP_EXTRACT(COALESCE(pay_user_id, consume_user_id),'\\d{4}(.*)'), null) AS dp_user_id,
                   bu_code,
                   sale_platform,
                   CONCAT(sale_platform, '_', REGEXP_EXTRACT(pay_user_id, '\\d{4}(.*)')) AS pay_user_key,
                   pay_amt,
                   pay_quantity,
                   IF(pay_order_id IS NOT NULL, 1, 0) AS pay_order_cnt,
                   pay_profit,
                   CONCAT(sale_platform, '_', REGEXP_EXTRACT(consume_user_id, '\\d{4}(.*)'))  consume_user_key,
                   consume_amt,
                   consume_quantity,
                   consume_order_id AS consume_order_key,
                   consume_profit,
                   IF(consume_order_id IS NOT NULL, 1, 0) AS is_consumed,   -- 是否消费行为
                   IF(pay_order_id IS NOT NULL, 1, 0) AS is_paid,        -- 是否支付行为
                   IF(refund_order_id IS NOT NULL,1,0)  is_refund,  -- 是否退款行为
                    refund_order_id AS refund_order_key
              FROM
                   ba_travel.topic_order_trade
              WHERE 
                   bu_code  in  ('11020','11021','11022')   -- 限制境内度假三条业务线
                   AND
                   datekey between $begindatekey and $enddatekey
               ) sale_order
           INNER JOIN 
               dw.dim_date dt 
               ON 
                   sale_order.datekey = dt.date_id
           INNER JOIN 
               -- 补全所有的补贴的订单的信息
               (-- 支付 减类
               SELECT 
                   a.order_key,
                   a.system_type,
                   a.pay_hbg_promotion_reduce_amt,
                   a.pay_hbg_card_reduce_amt,
                   a.activity_id AS promotion_activity_id,
                   b.active_title AS promotion_activity_name,
                   b.creator_name AS promotion_creator_name,
                   NULL AS card_activity_id,
                   NULL AS card_activity_name,
                   NULL AS card_creator_name,
                   NULL AS marketing_id,
                   NULL AS marketing_name,
                   NULL AS marketing_creator_name,
                   NULL AS apply_id,
                   NULL AS apply_key
               FROM
                   (SELECT
                       order_key,
                       2 AS system_type, -- 代金券:card:1  促销:promotion:2
                       activity_id,
                       activity_key,
                       source_type,
                       SUM(hbg_value) AS pay_hbg_promotion_reduce_amt,
                       0.0 AS pay_hbg_card_reduce_amt
                   FROM 
                       ba_hotel.hbg_fact_activity_participate
                   WHERE  
                       plantform_source = 'travel' 

                       AND
                       hbg_value > 0 -- 补贴类型必须为美团补贴
                       AND
                       activity_value > 0
                   GROUP BY 
                       order_key,
                       activity_id,
                       activity_key,
                       source_type
                   ) a
               LEFT OUTER JOIN
                   ba_hotel.hbg_dim_activity_info b     -- activity_id,active_title,creator_name
                   ON 
                       a.activity_id = b.activity_id
                       AND
                       a.source_type = b.source_type
                   
               UNION ALL
               
               -- 支付 券类
               SELECT 
                   a.order_key,
                   a.system_type,
                   a.pay_hbg_promotion_reduce_amt,
                   a.pay_hbg_card_reduce_amt,
                   NULL AS promotion_activity_id,
                   NULL AS promotion_activity_name,
                   NULL AS promotion_creator_name,
                   if(b.activity_id is null,c.apply_id,b.activity_id) AS card_activity_id,
                   if(b.activity_id is null,c.apply_name,b.activity_name) AS card_activity_name,
                   if(b.activity_id is null,c.apply_add_user_name,b.creator_name) AS card_creator_name,
                   c.marketing_id,
                   c.marketing_name,
                   d.user_login AS marketing_creator_name,
                   a.apply_id,
                   a.apply_key
               FROM
                   (SELECT
                       order_key,
                       1 AS system_type, -- 代金券:card:1  促销:promotion:2
                       apply_id,
                       apply_key,
                       card_code,
                       0.0 AS pay_hbg_promotion_reduce_amt,
                       SUM(reduce_value) AS pay_hbg_card_reduce_amt
                   FROM 
                       ba_hotel.hbg_fact_activity_card_use
                   WHERE  
                       plantform_source = 'travel' 

                       AND
                       reduce_value > 0 -- 补贴类型必须为美团补贴
                   GROUP BY 
                       order_key,
                       apply_id,
                       apply_key,
                       card_code
                   ) a
               LEFT OUTER JOIN
                   (-- 触发券类活动信息
                   SELECT 
                       b1.card_code,
                       b1.activity_id AS activity_id,
                       b2.activity_name AS activity_name,
                       b2.creator AS creator_name
                   FROM
                       (SELECT
                           activity_id,
                           card_code
                       FROM
                           ba_hotel.fact_trigger_activity_action_code
                       WHERE
                           datekey between $begindatekey and $enddatekey
                           AND
                           card_code != '' 
                           AND 
                           card_code != '0'
                       ) b1
                   LEFT OUTER JOIN
                       ba_hotel.dim_activity_trigger_info b2
                       ON 
                           b1.activity_id = b2.activity_id
                           
                   UNION ALL
                   
                   -- 潘多拉券类活动信息
                   SELECT
                       card_code,
                       activity_id,
                       activity_name,
                       creator_name
                   FROM 
                       ba_hotel.fact_pda_send_code_record 
                   WHERE

                       card_code != ''
                       AND 
                       card_code != '0'
                   ) b
                   ON 
                       CAST(a.card_code AS STRING) = CAST(b.card_code AS STRING)
               LEFT OUTER JOIN
                   -- 券类基本信息
                   (select
                          apply_key,
                          apply_id,
                          apply_name,
                          apply_add_user_name,
                          marketing_id,
                          marketing_name
                          from  ba_hotel.hbg_dim_activity_card_info_mt 
                    union all 
                    select
                          apply_key,
                          apply_id,
                          null apply_name,
                          null apply_add_user_name,
                          marketing_id,
                          marketing_name
                          from ba_hotel.hbg_dim_activity_card_info 
                          where source_type = 2011      
                          )c
                   ON 
                       a.apply_key = c.apply_key
               LEFT OUTER JOIN 
                   -- marketing信息
                   ba_hotel.hbg_dim_activity_marketing_info d
                   ON 
                       c.marketing_id = d.marketing_id
               ) pay_reduce 
               ON  
                   sale_order.order_key = pay_reduce.order_key
           -- 退款运营减免
           LEFT OUTER JOIN 
               (SELECT
                   order_key,
                   datekey,
                   SUM(IF(system_type='promotion', hbg_refund_reduce_value, 0.0)) AS refund_hbg_promotion_reduce_amt,
                   SUM(IF(system_type='card', hbg_refund_reduce_value, 0.0)) AS refund_hbg_card_reduce_amt
               FROM
                   ba_hotel.hbg_fact_op_reduce_refund
               WHERE
                   plantform_source = 'travel' 
                   AND
                   datekey between $begindatekey and $enddatekey
                   AND
                   hbg_refund_reduce_value > 0 -- 补贴类型必须为美团补贴
               GROUP BY
                   order_key,
                   datekey
               ) refund_reduce
               ON   
                   sale_order.refund_order_key = refund_reduce.order_key
                   AND 
                   sale_order.datekey = refund_reduce.datekey 
           -- 旅游 境内 新老客 类型
           LEFT OUTER JOIN 
               (SELECT
                   user_type.user_type,
                   user_type.user_id,
                   user_type.user_key,
                   user_type.datekey,
                   dt.week_begin_date_id  week_begin_datekey,
                   dt.month_begin_date_id month_begin_datekey,
                   user_type.order_key  order_key,
                   user_type.sale_platform
               FROM 
                   (SELECT
                       user_type,
                       user_id,
                       concat('dp_', user_id) AS user_key,
                       datekey,
                       order_id  order_key,
                       'dp' AS sale_platform
                   FROM  
                       ba_travel.fact_dp_sale_platform_domestic_new_pay_user
                   
                   UNION ALL 
                   
                   SELECT
                       user_type,
                       user_id,
                       concat('mt_', user_id) AS user_key,
                       datekey,
                       order_id AS order_key,
                       'mt' AS sale_platform
                   FROM  
                       ba_travel.fact_mt_sale_platform_domestic_new_pay_user     
                   ) user_type
               INNER JOIN 
                   dw.dim_date dt 
                   ON 
                       user_type.datekey = dt.date_id
               ) new_user_type
               ON  
                   sale_order.user_key = new_user_type.user_key
                   AND 
                   sale_order.sale_platform = new_user_type.sale_platform
           ) result   
           where result.reduce_type=2
                 and  
                 result.new_user_type in (1,2)
                 ) m
group by 
         m.datekey,
         m.sale_platform,
         if(m.new_user_type=1,'纯新','转新'),
         m.promotion_activity_id,
         m.promotion_activity_name,
         m.promotion_creator_name 

UNION ALL

select 
     m.datekey,
     m.sale_platform,
     if(m.new_user_type=1,'纯新','转新') as new_user_type,
     '抵用券' as reduce_type,
     m.card_activity_id `活动id`,
     m.card_activity_name `活动名称`,
     m.card_creator_name `活动创建人`,
     count(distinct if(m.is_paid=1,m.order_key,null)) `支付订单数`,
     sum(m.pay_amt) `支付GMV`,
     count(distinct m.pay_user_key) `支付用户数`,
     sum(m.pay_hbg_reduce_amt) `支付补贴`,
     count(distinct if(m.is_consumed=1,m.order_key,null)) `消费订单数`,
     sum(m.consume_amt) `消费GMV`,
     sum(m.consume_profit) `消费毛利`,
     count(distinct m.consume_user_key) `消费用户数`,
     sum(m.pay_hbg_reduce_amt) - sum(m.refund_hbg_reduce_amt) `消费补贴`
  from
       (
           SELECT  
              result.order_key,
              result.week_begin_datekey,
              result.month_begin_datekey,
              result.user_key,
              result.mt_user_id,
              result.dp_user_id,
              result.bu_code,
              result.sale_platform,

              result.reduce_type,
              result.new_user_type,
              result.promotion_activity_id,
              result.promotion_activity_name,
              result.promotion_creator_name,
              result.card_activity_id,
              result.card_activity_name,
              result.card_creator_name,
              result.card_marketing_id,
              result.card_marketing_name,
              result.card_marketing_creator_name,
              result.apply_key,
              result.apply_id, 
              
              result.is_paid,
              IF(result.is_paid=1, result.pay_hbg_reduce_amt, 0.0) AS pay_hbg_reduce_amt,
              IF(result.is_paid=1, result.pay_hbg_promotion_reduce_amt, 0.0) AS pay_hbg_promotion_reduce_amt,
              IF(result.is_paid=1, result.pay_hbg_card_reduce_amt, 0.0) AS pay_hbg_card_reduce_amt,
              result.pay_user_key,
              result.pay_amt,
              result.pay_quantity,
              result.pay_order_cnt,
              result.pay_profit,
              
              result.is_consumed,
              result.consume_user_key,
              result.consume_amt,
              result.consume_quantity,
              result.consume_profit,
              
              result.is_refund,
              result.refund_hbg_reduce_amt,
              result.refund_hbg_promotion_reduce_amt,
              result.refund_hbg_card_reduce_amt,
              result.datekey
        from 
           (select
               sale_order.datekey,    
               dt.week_begin_date_id AS week_begin_datekey,
               dt.month_begin_date_id AS month_begin_datekey,
               sale_order.order_key,
               sale_order.user_key,
               sale_order.mt_user_id,
               sale_order.dp_user_id,
               sale_order.bu_code,
               sale_order.sale_platform,
               pay_reduce.system_type AS reduce_type, -- 2减类 OR 1券类
               IF(sale_order.order_key = new_user_type.order_key, new_user_type.user_type, 0) AS new_user_type,  -- 0:老客 1:纯新 2:转新 补贴口径的新老客(关联订单) 
               pay_reduce.promotion_activity_id,       -- 减类活动信息
               pay_reduce.promotion_activity_name,
               pay_reduce.promotion_creator_name,
               pay_reduce.card_activity_id,        -- 券类活动信息
               pay_reduce.card_activity_name,
               pay_reduce.card_creator_name,
               pay_reduce.marketing_id AS card_marketing_id,   -- 券信息
               pay_reduce.marketing_name AS card_marketing_name,
               pay_reduce.marketing_creator_name AS card_marketing_creator_name,
               pay_reduce.apply_key,
               pay_reduce.apply_id,
               sale_order.pay_user_key,
               sale_order.pay_amt,
               sale_order.pay_quantity,
               sale_order.pay_order_cnt,
               sale_order.pay_profit,
               sale_order.is_paid,          -- 是否支付行为
               (coalesce(pay_reduce.pay_hbg_promotion_reduce_amt,0.0) + coalesce(pay_reduce.pay_hbg_card_reduce_amt,0.0)) AS pay_hbg_reduce_amt,
               coalesce(pay_reduce.pay_hbg_promotion_reduce_amt,0.0) AS pay_hbg_promotion_reduce_amt,
               coalesce(pay_reduce.pay_hbg_card_reduce_amt,0.0) AS pay_hbg_card_reduce_amt,
               sale_order.consume_user_key,
               sale_order.consume_amt,
               sale_order.consume_quantity,
               sale_order.consume_order_key,
               sale_order.consume_profit,
               sale_order.is_consumed,      -- 是否消费行为
               -- 消费补贴=支付补贴-退款补贴 
               (coalesce(refund_reduce.refund_hbg_promotion_reduce_amt,0.0) + coalesce(refund_reduce.refund_hbg_card_reduce_amt,0.0)) AS refund_hbg_reduce_amt,
               coalesce(refund_reduce.refund_hbg_promotion_reduce_amt,0.0) AS refund_hbg_promotion_reduce_amt,
               coalesce(refund_reduce.refund_hbg_card_reduce_amt,0.0) AS refund_hbg_card_reduce_amt,
               sale_order.is_refund
           FROM 
               (SELECT
                   datekey,
                   order_id AS order_key,
                   CONCAT(sale_platform, '_', REGEXP_EXTRACT(COALESCE(pay_user_id, consume_user_id),'\\d{4}(.*)')) AS user_key,
                   IF(sale_platform = 'mt', REGEXP_EXTRACT(COALESCE(pay_user_id, consume_user_id),'\\d{4}(.*)'), null) AS mt_user_id,
                   IF(sale_platform = 'dp', REGEXP_EXTRACT(COALESCE(pay_user_id, consume_user_id),'\\d{4}(.*)'), null) AS dp_user_id,
                   bu_code,
                   sale_platform,
                   CONCAT(sale_platform, '_', REGEXP_EXTRACT(pay_user_id, '\\d{4}(.*)')) AS pay_user_key,
                   pay_amt,
                   pay_quantity,
                   IF(pay_order_id IS NOT NULL, 1, 0) AS pay_order_cnt,
                   pay_profit,
                   CONCAT(sale_platform, '_', REGEXP_EXTRACT(consume_user_id, '\\d{4}(.*)'))  consume_user_key,
                   consume_amt,
                   consume_quantity,
                   consume_order_id AS consume_order_key,
                   consume_profit,
                   IF(consume_order_id IS NOT NULL, 1, 0) AS is_consumed,   -- 是否消费行为
                   IF(pay_order_id IS NOT NULL, 1, 0) AS is_paid,        -- 是否支付行为
                   IF(refund_order_id IS NOT NULL,1,0)  is_refund,  -- 是否退款行为
                    refund_order_id AS refund_order_key
              FROM
                   ba_travel.topic_order_trade
              WHERE 
                   bu_code  in  ('11020','11021','11022')   -- 限制境内度假三条业务线
                   AND
                   datekey between $begindatekey and $enddatekey
               ) sale_order
           INNER JOIN 
               dw.dim_date dt 
               ON 
                   sale_order.datekey = dt.date_id
           INNER JOIN 
               -- 补全所有的补贴的订单的信息
               (-- 支付 减类
               SELECT 
                   a.order_key,
                   a.system_type,
                   a.pay_hbg_promotion_reduce_amt,
                   a.pay_hbg_card_reduce_amt,
                   a.activity_id AS promotion_activity_id,
                   b.active_title AS promotion_activity_name,
                   b.creator_name AS promotion_creator_name,
                   NULL AS card_activity_id,
                   NULL AS card_activity_name,
                   NULL AS card_creator_name,
                   NULL AS marketing_id,
                   NULL AS marketing_name,
                   NULL AS marketing_creator_name,
                   NULL AS apply_id,
                   NULL AS apply_key
               FROM
                   (SELECT
                       order_key,
                       2 AS system_type, -- 代金券:card:1  促销:promotion:2
                       activity_id,
                       activity_key,
                       source_type,
                       SUM(hbg_value) AS pay_hbg_promotion_reduce_amt,
                       0.0 AS pay_hbg_card_reduce_amt
                   FROM 
                       ba_hotel.hbg_fact_activity_participate
                   WHERE  
                       plantform_source = 'travel' 

                       AND
                       hbg_value > 0 -- 补贴类型必须为美团补贴
                       AND
                       activity_value > 0
                   GROUP BY 
                       order_key,
                       activity_id,
                       activity_key,
                       source_type
                   ) a
               LEFT OUTER JOIN
                   ba_hotel.hbg_dim_activity_info b     -- activity_id,active_title,creator_name
                   ON 
                       a.activity_id = b.activity_id
                       AND
                       a.source_type = b.source_type
                   
               UNION ALL
               
               -- 支付 券类
               SELECT 
                   a.order_key,
                   a.system_type,
                   a.pay_hbg_promotion_reduce_amt,
                   a.pay_hbg_card_reduce_amt,
                   NULL AS promotion_activity_id,
                   NULL AS promotion_activity_name,
                   NULL AS promotion_creator_name,
                   if(b.activity_id is null,c.apply_id,b.activity_id) AS card_activity_id,
                   if(b.activity_id is null,c.apply_name,b.activity_name) AS card_activity_name,
                   if(b.activity_id is null,c.apply_add_user_name,b.creator_name) AS card_creator_name,
                   c.marketing_id,
                   c.marketing_name,
                   d.user_login AS marketing_creator_name,
                   a.apply_id,
                   a.apply_key
               FROM
                   (SELECT
                       order_key,
                       1 AS system_type, -- 代金券:card:1  促销:promotion:2
                       apply_id,
                       apply_key,
                       card_code,
                       0.0 AS pay_hbg_promotion_reduce_amt,
                       SUM(reduce_value) AS pay_hbg_card_reduce_amt
                   FROM 
                       ba_hotel.hbg_fact_activity_card_use
                   WHERE  
                       plantform_source = 'travel' 

                       AND
                       reduce_value > 0 -- 补贴类型必须为美团补贴
                   GROUP BY 
                       order_key,
                       apply_id,
                       apply_key,
                       card_code
                   ) a
               LEFT OUTER JOIN
                   (-- 触发券类活动信息
                   SELECT 
                       b1.card_code,
                       b1.activity_id AS activity_id,
                       b2.activity_name AS activity_name,
                       b2.creator AS creator_name
                   FROM
                       (SELECT
                           activity_id,
                           card_code
                       FROM
                           ba_hotel.fact_trigger_activity_action_code
                       WHERE
                           datekey between $begindatekey and $enddatekey
                           AND
                           card_code != '' 
                           AND 
                           card_code != '0'
                       ) b1
                   LEFT OUTER JOIN
                       ba_hotel.dim_activity_trigger_info b2
                       ON 
                           b1.activity_id = b2.activity_id
                           
                   UNION ALL
                   
                   -- 潘多拉券类活动信息
                   SELECT
                       card_code,
                       activity_id,
                       activity_name,
                       creator_name
                   FROM 
                       ba_hotel.fact_pda_send_code_record 
                   WHERE

                       card_code != ''
                       AND 
                       card_code != '0'
                   ) b
                   ON 
                       CAST(a.card_code AS STRING) = CAST(b.card_code AS STRING)
               LEFT OUTER JOIN
                   -- 券类基本信息
                   (select
                          apply_key,
                          apply_id,
                          apply_name,
                          apply_add_user_name,
                          marketing_id,
                          marketing_name
                          from  ba_hotel.hbg_dim_activity_card_info_mt 
                    union all 
                    select
                          apply_key,
                          apply_id,
                          null apply_name,
                          null apply_add_user_name,
                          marketing_id,
                          marketing_name
                          from ba_hotel.hbg_dim_activity_card_info 
                          where source_type = 2011      
                          )c
                   ON 
                       a.apply_key = c.apply_key
               LEFT OUTER JOIN 
                   -- marketing信息
                   ba_hotel.hbg_dim_activity_marketing_info d
                   ON 
                       c.marketing_id = d.marketing_id
               ) pay_reduce 
               ON  
                   sale_order.order_key = pay_reduce.order_key
           -- 退款运营减免
           LEFT OUTER JOIN 
               (SELECT
                   order_key,
                   datekey,
                   SUM(IF(system_type='promotion', hbg_refund_reduce_value, 0.0)) AS refund_hbg_promotion_reduce_amt,
                   SUM(IF(system_type='card', hbg_refund_reduce_value, 0.0)) AS refund_hbg_card_reduce_amt
               FROM
                   ba_hotel.hbg_fact_op_reduce_refund
               WHERE
                   plantform_source = 'travel' 
                   AND
                   datekey between $begindatekey and $enddatekey
                   AND
                   hbg_refund_reduce_value > 0 -- 补贴类型必须为美团补贴
               GROUP BY
                   order_key,
                   datekey
               ) refund_reduce
               ON   
                   sale_order.refund_order_key = refund_reduce.order_key
                   AND 
                   sale_order.datekey = refund_reduce.datekey 
           -- 旅游 境内 新老客 类型
           LEFT OUTER JOIN 
               (SELECT
                   user_type.user_type,
                   user_type.user_id,
                   user_type.user_key,
                   user_type.datekey,
                   dt.week_begin_date_id  week_begin_datekey,
                   dt.month_begin_date_id month_begin_datekey,
                   user_type.order_key  order_key,
                   user_type.sale_platform
               FROM 
                   (SELECT
                       user_type,
                       user_id,
                       concat('dp_', user_id) AS user_key,
                       datekey,
                       order_id  order_key,
                       'dp' AS sale_platform
                   FROM  
                       ba_travel.fact_dp_sale_platform_domestic_new_pay_user
                   
                   UNION ALL 
                   
                   SELECT
                       user_type,
                       user_id,
                       concat('mt_', user_id) AS user_key,
                       datekey,
                       order_id AS order_key,
                       'mt' AS sale_platform
                   FROM  
                       ba_travel.fact_mt_sale_platform_domestic_new_pay_user     
                   ) user_type
               INNER JOIN 
                   dw.dim_date dt 
                   ON 
                       user_type.datekey = dt.date_id
               ) new_user_type
               ON  
                   sale_order.user_key = new_user_type.user_key
                   AND 
                   sale_order.sale_platform = new_user_type.sale_platform
           ) result   
           where result.reduce_type=1
                 and  
                 result.new_user_type in (1,2)
                 ) m
group by 
         m.datekey,
         m.sale_platform,
         if(m.new_user_type=1,'纯新','转新'),
         m.card_activity_id,
         m.card_activity_name,
         m.card_creator_name