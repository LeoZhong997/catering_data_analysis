-- 在 Doris 数据库 中将数据从 DWD 层（明细层） 转换并加载到 DWS 层（汇总层）
-- 目的是通过对订单数据进行聚合和汇总，生成更高层次的统计表，以便支持后续的分析和报表生成。
-- 构建数据仓库的 DWS 层
--  1. 创建多个聚合表（如 dws_member_dish_stat 和 dws_shop_city_stat）。
--  2. 从 DWD 层加载数据到 DWS 层。
--  3. 提供首日装载和每日增量装载的 SQL 语句。
--  4. 支持后续的统计分析需求。

-- 创建 DWS 层聚合表
-- 1日各会员各类别的stat
-- 按天统计每个会员在每个菜品类别上的订单量、销量和销售额
drop table if exists dws_member_dish_stat;
create table if not exists dws_member_dish_stat(
    member_id bigint comment '用户id',
    member_name varchar(10) comment '用户名',
    dish_category varchar(32) comment '类品名称',
    pay_date date comment '支付日期',
    order_count int sum default '0' comment '订单量',
    slaves_volume int sum default '0' comment '销量',
    total_sales decimal(16, 2)  sum default '0' comment '销售额'
)
-- 使用 aggregate key 定义主键字段，确保数据在插入时自动聚合
aggregate key(`member_id`, `member_name`, `dish_category`, `pay_date`)
distributed by hash(`member_id`) buckets 1
properties(
    "replication_num" = "1"
);

-- 为 dws_member_dish_stat 的 dish_id,dish_category创建bitmap索引，以加速查询性能
create index if not exists dish_name_idx on dws_member_dish_stat (dish_category) using bitmap comment '类品名称列bitmap索引';

-- 从 DWD 层加载数据到 DWS 层
-- 首日装载
-- 将 DWD 层的订单明细数据（dwd_order_detail）与维度表（dim_member_info 和 dim_dish_info）关联后，
-- 按会员、菜品类别和支付日期进行汇总，并加载到 dws_member_dish_stat 表中。
--  过滤出已结算的订单（is_paid = '1'）
--  使用 bitmap_union 和 bitmap_count 计算订单量
--  使用 sum 函数计算销量和销售额
--  按 member_id、member_name、dish_category 和payment_time分组
insert into private_station.dws_member_dish_stat
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
    where is_paid = '1'
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

-- 每日装载，每日增量加载新的订单数据
--  通过 WHERE 条件筛选出指定日期范围内的数据（例如前一天的数据）
# insert into private_station.dws_member_dish_stat
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
    -- 获取当日增量数据
    where is_paid = '1' and date(payment_time) = date_add('2016-09-01', -1)
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


-- 1日各城市各店铺的stat
-- 按天统计每个城市的每个店铺的订单量、销量和销售额。
drop table if exists dws_shop_city_stat;
create table if not exists dws_shop_city_stat(
    `shop_location` varchar(10) comment '店铺所在地',
    `shop_name` varchar(32) comment '店铺名',
    `pay_date` date comment '支付日期',
    `order_count` int sum default '0' comment '订单量',
    `slaves_volume` int sum default '0' comment '销量',
    `total_sales` decimal(16, 2) sum default '0' comment '销售额'
)
-- 使用 aggregate key 定义主键字段，确保数据在插入时自动聚合
aggregate key(`shop_location`, `shop_name`, `pay_date`)
distributed by hash(`shop_location`) buckets 1
properties(
    "replication_num" = "1"
);

-- 为shop_location，shop_name创建bitmap索引
create index if not exists shop_location_idx on dws_shop_city_stat (shop_location) using bitmap comment 'shop_location列bitmap索引';

create index if not exists shop_name_idx on dws_shop_city_stat (shop_name) using bitmap comment 'shop_name列bitmap索引';


-- 数据装载
-- 首日装载
insert into dws_shop_city_stat
select
    shop_location,
    shop_name,
    date(payment_time),
    bitmap_count(bitmap_union(to_bitmap(order_id))) order_count,
    sum(quantity),
    sum(quantity * price)
from dwd_order_detail
where is_paid = '1'
group by
    shop_location,
    shop_name,
    date(payment_time);

-- 每日装载
# insert into dws_shop_city_stat
select
    shop_location,
    shop_name,
    date(payment_time),
    bitmap_count(bitmap_union(to_bitmap(order_id))) order_count,
    sum(quantity),
    sum(quantity * price)
from dwd_order_detail
-- 获取当日增量数据
where is_paid = '1' and date(payment_time) = date_add('2016-09-01', -1)
group by
    shop_location,
    shop_name,
    date(payment_time);


-- 1日各品类各口味各菜品的stat
drop table if exists dws_dish_stat;
create table if not exists dws_dish_stat(
    `dish_id` bigint comment '菜品id',
    `dish_name` varchar(64) comment '菜品名称',
    `flavor` varchar(10) comment '菜品口味',
    `dish_category` varchar(32) comment '菜品类别',
    `pay_date` date comment '支付日期',
    `order_count` int sum default '0' comment '订单量',
    `slaves_volume` int sum default '0' comment '销量',
    `total_sales` decimal(16, 2) sum default  '0' comment '销售额'
)
aggregate key(`dish_id`, `dish_name`, `flavor`, `dish_category`, `pay_date`)
distributed by hash(`dish_id`) buckets 1
properties(
    "replication_num" = "1",
    "bloom_filter_columns" = "dish_id, dish_name, pay_date"
);


create index if not exists flavor_idx on dws_dish_stat (flavor) using bitmap comment 'flavor列bitmap索引';
create index if not exists dish_category_idx on dws_dish_stat (dish_category) using bitmap comment 'dish_categoru列索引';


-- 首日装载
insert into dws_dish_stat
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
    where is_paid = '1'
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


-- 每日装载
# insert into dws_dish_stat
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