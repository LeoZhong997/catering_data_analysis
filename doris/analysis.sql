-- ods_to_dwd_and_dim.sql
-- 统计指标需求分析
-- 通过连接事实表（dwd_order_detail）和维度表（dim_dish_info、dim_member_info），
-- 生成包含订单、菜品和会员信息的综合视图，用于统计分析。
-- 查询语句，没有创建表
select
    order_id,
    order_detail.member_id,
    order_detail.dish_id,
    shop_name,
    shop_location,
    order_time,
    payment_time,
    is_paid,
    consumption_amount,
    order_detail.price,
    quantity,
    dish_name,
    flavor,
    cost,
    recommendation_level,
    dish_category,
    member_name,
    gender,
    age,
    membership_join_date,
    phone_number,
    membership_level
from (
    select
        order_id,
        member_id,
        dish_id,
        shop_name,
        shop_location,
        order_time,
        payment_time,
        is_paid,
        consumption_amount,
        price,
        quantity
    from dwd_order_detail
) order_detail
left join (
    select
        dish_id,
        dish_name,
        flavor,
        price,
        cost,
        recommendation_level,
        dish_category
    from dim_dish_info
) dish_info
on order_detail.dish_id = dish_info.dish_id
left join (
    select
        member_id,
        member_name,
        gender,
        age,
        membership_join_date,
        phone_number,
        membership_level
    from dim_member_info
) member_info
on order_detail.member_id = member_info.member_id;