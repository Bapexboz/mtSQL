select x.query,x.intent_uv,y.num from
(select
  query,
  count(distinct uuid) as intent_uv
from
(select
bu_name,
get_json_object(get_json_object(get_json_object(tag,'$.search'),'$.E'),'$.keyword') as query,
  uuid
from
mart_semantic.detail_platform_pageflow_daily
where
  partition_date between '$begindatekey' and '$enddatekey' --YYYY-MM-DD
  and is_intent_page = 1
  and bu_name like '%境内%'
  )t
where
   length(query) > 0
group by
  query) x
  left outer join
  (select get_json_object(get_json_object(get_json_object(tag_first,'$.search'),'$.E'),'$.keyword') as query,
     COUNT(DISTINCT uuid) as num
from mart_platsensitive.topic_platform_order_xmd_daily
where partition_date between '$begindatekey' and '$enddatekey' --YYYY-MM-DD
 and app_name = 'group'
 and partition_c = 'mt'
 and partition_is_paid = 1
 and length(get_json_object(tag_first,'$.search')) > 0
 and partition_prod_line like '%travel%'
 group by get_json_object(get_json_object(get_json_object(tag_first,'$.search'),'$.E'),'$.keyword')) y
 on x.query=y.query
 order by x.intent_uv desc
 limit 100