SELECT

user_id
FROM ba_hotel.hbg_fact_activity_card_assign_mt
WHERE card_status=0

and source_type=2001
and datekey =20171001

group by
user_id