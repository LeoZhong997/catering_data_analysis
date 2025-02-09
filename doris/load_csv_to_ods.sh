#!/bin/bash

# 定义Doris的API地址和认证信息
DORIS_HOST="http://127.0.0.1:8040"
USER="root"
PASSWORD=""

# 数据加载函数
load_data() {
    local table_name=$1
    local csv_file=$2
    local columns=$3

    echo "正在加载数据到表: $table_name"
    curl --location-trusted -u $USER:$PASSWORD \
        -v \
        -H "Expect:100-continue" \
        -H "column_separator:," \
        -H "columns:$columns" \
        -T $csv_file \
        -XPUT "$DORIS_HOST/api/private_station/$table_name/_stream_load"
    
    echo "数据加载完成: $table_name"
    echo "----------------------------------------"
}

# csv中不需要包含表头，否则会报错
# 加载订单信息表
load_data "ods_order_info" "../data/订单信息表.csv" "order_id, member_name, shop_name, shop_location, order_time, consumption_amount, is_paid, payment_time"

# 加载订单明细表
load_data "ods_order_detail" "../data/订单详情表.csv" "order_id, dish_name, price, quantity, detail_date, detail_time"

# 加载菜品信息表
load_data "ods_dish_info" "../data/菜品信息表.csv" "dish_id, dish_name, flavor, price, cost, recommendation_level, dish_category"

# 加载会员信息表
load_data "ods_member_info" "../data/会员信息表.csv" "member_id, member_name, gender, age, member_join_date, phone_number, membership_level"