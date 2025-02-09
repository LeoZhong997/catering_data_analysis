-- 装载指定日期的数据
SET @target_date = date_add('2025-02-08', -1);

-- ods_to_dwd_and_dim.sql
-- 通过 WHERE 条件筛选出指定日期范围内的数据（例如前一天的数据）
select
    order_info.order_id,
    member_info.member_id,
    dish_info.dish_id,
    order_info.shop_name,
    order_info.shop_location,
    order_info.order_time,
    order_info.payment_time,
    order_info.is_paid,
    order_info.consumption_amount,
    order_detail.price,
    order_detail.quantity
from (
    select
        if(substr(order_id, 9, 1) = '0',
           concat(substring(order_id, 1, 8), substring(order_id, 10)),
           order_id) order_id,
        member_name,
        shop_name,
        shop_location,
        order_time,
        consumption_amount,
        is_paid,
        payment_time
    from private_station.ods_order_info
    -- 索取当日时间
    where date(payment_time) = @target_date
) order_info
inner join(
    select
        order_id,
        dish_name,
        price,
        quantity
    from private_station.ods_order_detail
) order_detail
on order_info.order_id = order_detail.order_id
inner join(
    select
        member_id,
        member_name
    from private_station.ods_member_info
) member_info
on order_info.member_name = member_info.member_name
inner join(
    select
        dish_id,
        dish_name
    from private_station.ods_dish_info
) dish_info
on order_detail.dish_name = dish_info.dish_name;


-- dwd_to_dws.sql
select
    order_detail.member_id,
    member_info.member_name,
    dish_info.dish_category,
    date(payment_time) pay_date,
    bitmap_count(bitmap_union(to_bitmap(order_id))) order_count,
    sum(order_detail.quantity) slaves_volume,
    sum(order_detail.quantity * order_detail.price) total_sales
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
    where is_paid = '1' and date(payment_time) = @target_date
) order_detail
left join (
    select
        member_id,
        member_name
    from dim_member_info
) member_info
on order_detail.member_id = member_info.member_id
left join (
    select
        dish_id,
        dish_category
    from dim_dish_info
) dish_info
on order_detail.dish_id = dish_info.dish_id
group by
    order_detail.member_id,
    member_info.member_name,
    dish_info.dish_category,
    date(payment_time);


select
    shop_location,
    shop_name,
    date(payment_time),
    bitmap_count(bitmap_union(to_bitmap(order_id))) order_count,
    sum(quantity),
    sum(quantity * price)
from dwd_order_detail
where is_paid = '1' and date(payment_time) = date_add('2016-09-01', -1)
group by
    shop_location,
    shop_name,
    date(payment_time);


select
    order_detail.dish_id,
    dish_info.dish_name,
    dish_info.flavor,
    dish_info.dish_category,
    date(order_detail.payment_time),
    bitmap_count(bitmap_union(to_bitmap(order_detail.order_id))),
    sum(order_detail.quantity),
    sum(order_detail.quantity*order_detail.price)
from (
    select
        order_id,
        payment_time,
        dish_id,
        quantity,
        price
    from dwd_order_detail
    -- 获取当日增量数据
    where is_paid = '1' and date(payment_time) = date_add('2016-09-01', -1)
) order_detail
inner join (
    select
        dish_id,
        dish_category,
        flavor,
        dish_name
    from dim_dish_info
) dish_info
on order_detail.dish_id = dish_info.dish_id
group by
    order_detail.dish_id,
    dish_info.dish_name,
    dish_info.flavor,
    dish_info.dish_category,
    date(order_detail.payment_time);


-- dws_to_ads.sql
-- insert into ads_dish_category_1day
select
    pay_date,
    dish_category,
    order_count,
    slaves_volume,
    total_sales
from dws_member_dish_stat
where pay_date = @target_date;

-- insert into ads_dish_categroy
select
    dish_category,
    order_count,
    slaves_volume,
    total_sales
from ads_dish_category_1day
where pay_date = @target_date;

-- insert into ads_city_1day
select
    pay_date,
    shop_location,
    order_count,
    slaves_volume,
    total_sales
from dws_shop_city_stat
where pay_date = @target_date;

-- insert into ads_city
select
    shop_location,
    order_count,
    slaves_volume,
    total_sales
from ads_city_1day
where pay_date = @target_date;

-- insert into ads_shop_1day
select
    pay_date,
    shop_name,
    order_count,
    slaves_volume,
    total_sales
from dws_shop_city_stat
where pay_date = @target_date;

-- 历史累积店铺的统计指标
-- insert into ads_shop
select
    shop_name,
    order_count,
    slaves_volume,
    total_sales
from ads_shop_1day
where pay_date = @target_date;

-- 月季各城市盈利额与各城市盈利总额平均值对比
-- insert into ads_city_month
select
    date_format(pay_date, '%Y-%m'),
    shop_location,
    order_count,
    slaves_volume,
    total_sales,
    order_count * 0.3 + slaves_volume * 0.2 + total_sales * 0.5 score,
    58000
from ads_city_1day
where pay_date = @target_date;

-- 月季度各店铺盈利额与各店铺盈利总额平均值对比
-- insert into ads_shop_month
select
    date_format(pay_date, '%Y-%m') date_month,
    shop_name,
    order_count,
    slaves_volume,
    total_sales,
    order_count * 0.3 + slaves_volume * 0.2 + total_sales * 0.5 score,
    25798
from dws_shop_city_stat
where pay_date = @target_date;

-- 历史各会员消费的统计指标
-- insert into ads_member
select
    member_id,
    member_name,
    order_count,
    slaves_volume,
    total_sales
from dws_member_dish_stat
where pay_date = @target_date;

-- 历史至今各会员对品类消费情况
-- insert into ads_member_dish_category
select
    member_id,
    member_name,
    dish_category,
    order_count,
    slaves_volume,
    total_sales
from dws_member_dish_stat
where pay_date = @target_date;

-- 每日各菜品销售情况的统计指标
-- insert into ads_member_dish_category_1day
select
    pay_date,
    dish_id,
    dish_name,
    order_count,
    slaves_volume,
    total_sales
from dws_dish_stat
where pay_date = @target_date;

-- 每月各菜品销售情况的统计指标
-- insert into ads_dish_name_month
select
    date_format(pay_date, '%Y-%m') month_date,
    dish_id,
    dish_name,
    order_count,
    slaves_volume,
    total_sales
from ads_dish_name_1day
where pay_date = @target_date;

-- 历史各菜品销售情况的统计指标
-- insert into ads_dish_name
select
    dish_id,
    dish_name,
    order_count,
    slaves_volume,
    total_sales
from ads_dish_name_1day
where pay_date = date_add('2016-01-09', -1);

select
    pay_date,
    flavor,
    order_count,
    slaves_volume,
    total_sales
from dws_dish_stat
where pay_date = @target_date

select
    date_format(pay_date, '%Y-%m') month_date,
    flavor,
    order_count,
    slaves_volume,
    total_sales
from ads_flavor_1day
where pay_date = @target_date;

select
    flavor,
    order_count,
    slaves_volume,
    total_sales
from ads_flavor_1day
where pay_date = @target_date;

select
    date_month,
    dish_category,
    dish_name,
    total_sales,
    total_sales_sum,
    round((total_sales/total_sales_sum) * 100, 2)
from (
    select
        date_month,
        dish_category,
        dish_name,
        total_sales,
        sum(total_sales) over(partition by dish_category) total_sales_sum
    from (
        select
            date_month,
            dish_category,
            dish_name,
            sum(total_sales) total_sales
        from (
            -- 当月的数据
            select
                date_month,
                dish_category,
                dish_name,
                total_sales
            from ads_dish_category_name_month
            -- where date_month = date_format('2016-08-30', '%Y-%m')
            where date_month = date_format('2016-08-30', '%Y-%m')
            union
            -- 当日新增数据
            select
                date_format(pay_date, '%Y-%m') date_month,
                dish_category,
                dish_name,
                sum(total_sales) total_sales
            from dws_dish_stat
            where pay_date = @target_date
            group by date_format(pay_date, '%Y-%m'), dish_category, dish_name
        ) tb1
        group by date_month, dish_category, dish_name
    ) tb2
) tb3;


