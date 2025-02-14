import csv
import random
from datetime import datetime, timedelta

DISH_FLAVOR = [
    '酸', '柠檬味', '甜', '香甜', '酸甜', '果味', '微辣', '香辣', '麻辣', 
    '油腻', '酸辣', '辣', '中辣', '咸鲜', '酱香', '香草味', '奶香', '葱香', 
    '蒜蓉', '蒜香', '清香', '香酥', '清淡', '爽口', '原味', 
]   # 25
DISH_CATEGORY = [
    '猪肉类', '羊肉类', '其他肉类', '牛肉类', '家禽类', '鱼类', '蟹类', '虾类', 
    '其他水产', '贝壳类', '饮料类', '红酒类', '啤酒类', '白酒类', '叶菜类', '茎菜类', 
    '花菜类', '海藻类', '果菜类', '根菜类', '粥类', '甜点类', '糕点类', '肠粉类', 
    '面包类', '米饭类', '面食类', 
]   # 27

# 生成随机数据的辅助函数
def random_date(start, end):
    return start + timedelta(seconds=random.randint(0, int((end - start).total_seconds())))

def generate_test_data(num_records=100):
    # 生成菜品信息表数据
    # 每个菜品有唯一的dish_id，随机的dish_name、flavor、price、cost、recommendation_level和dish_category。
    dishes = []
    for dish_id in range(1, 101):
        dish_name = f"Dish{dish_id}"
        flavor = random.choice(DISH_FLAVOR)
        price = round(random.uniform(10, 100), 2)
        cost = round(price * 0.6, 2)
        recommendation_level = round(random.uniform(1, 5), 1)
        dish_category = random.choice(DISH_CATEGORY)
        dishes.append({
            "dish_id": dish_id,
            "dish_name": dish_name,
            "flavor": flavor,
            "price": price,
            "cost": cost,
            "recommendation_level": recommendation_level,
            "dish_category": dish_category
        })
    
    # 生成会员信息表数据
    # 每个会员有唯一的member_id，随机的member_name、gender、age、member_join_date、phone_number和membership_level。
    members = []
    for member_id in range(1, 201):
        member_name = f"Member{member_id}"
        gender = random.choice(["男", "女"])
        age = random.randint(18, 60)
        member_join_date = random_date(datetime(2020, 1, 1), datetime.now())
        phone_number = random.randint(10000000000, 99999999999)
        membership_level = random.choice(["Bronze", "Silver", "Gold", "Platinum"])
        members.append({
            "member_id": member_id,
            "member_name": member_name,
            "gender": gender,
            "age": age,
            "member_join_date": member_join_date.strftime("%Y-%m-%d %H:%M:%S"),
            "phone_number": phone_number,
            "membership_level": membership_level
        })
    
    # 生成订单信息表数据
    # 每个订单关联一个随机的会员，随机的shop_name和shop_location，随机的order_time、consumption_amount、is_paid和payment_time。
    orders = []
    order_time = random_date(datetime(2024, 1, 1), datetime(2024, 6, 1))
    # 同时生成订单明细表数据
    # 每个订单包含1到5个菜品，每个菜品是随机选择的，有随机的quantity，detail_date和detail_time与订单的时间一致。
    order_details = []
    for order_id in range(1, num_records + 1):
        member = random.choice(members)
        shop_name = f"Shop{random.randint(1, 10)}"
        shop_location = f"Location{random.randint(1, 5)}"
        # order_time = random_date(datetime(2023, 1, 1), datetime.now())
        # 确保订单时间是递增的
        order_time += timedelta(minutes=random.randint(10, 60), hours=random.randint(1, 12), 
                                days=random.randint(1, 3))
        order_time_str = order_time.strftime("%Y-%m-%d %H:%M:%S")

        # consumption_amount = round(random.uniform(50, 500), 2)
        # 订单明细
        consumption_amount = 0
        num_dishes = random.randint(1, 5)
        for _ in range(num_dishes):
            dish = random.choice(dishes)
            quantity = random.randint(1, 3)
            detail_date = order_time_str.split(" ")[0]
            detail_time = order_time_str.split(" ")[1]
            order_details.append({
                "order_id": order_id,
                "dish_name": dish["dish_name"],
                "price": dish["price"],
                "quantity": quantity,
                "detail_date": detail_date,
                "detail_time": detail_time
            })
            consumption_amount += quantity * dish["price"]
        consumption_amount = round(consumption_amount, 2)

        is_paid = random.choice([0, 1])
        payment_time = order_time + timedelta(hours=random.randint(0, 24)) if is_paid else None
        orders.append({
            "order_id": order_id,
            "member_name": member["member_name"],
            "shop_name": shop_name,
            "shop_location": shop_location,
            "order_time": order_time_str,
            "consumption_amount": consumption_amount,
            "is_paid": is_paid,
            "payment_time": payment_time.strftime("%Y-%m-%d %H:%M:%S") if payment_time else None
        })
    
    # 保存为CSV文件
    output_table = ["菜品信息表", "会员信息表", "订单信息表", "订单详情表"]
    # output_table = ["会员信息表"]
    save_dir = '../data'
    if "菜品信息表" in output_table:
        with open(f'{save_dir}/菜品信息表.csv', 'w', newline='') as f:
            fieldnames = ["dish_id", "dish_name", "flavor", "price", "cost", "recommendation_level", "dish_category"]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            # writer.writeheader()
            for dish in dishes:
                writer.writerow(dish)
    
    if "会员信息表" in output_table:
        with open(f'{save_dir}/会员信息表.csv', 'w', newline='') as f:
            fieldnames = ["member_id", "member_name", "gender", "age", "member_join_date", "phone_number", "membership_level"]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            # writer.writeheader()
            for member in members:
                writer.writerow(member)
    
    
    if "订单信息表" in output_table:
        with open(f'{save_dir}/订单信息表.csv', 'w', newline='') as f:
            fieldnames = ["order_id", "member_name", "shop_name", "shop_location", "order_time", "consumption_amount", "is_paid", "payment_time"]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            # writer.writeheader()
            for order in orders:
                writer.writerow(order)
    
    if "订单详情表" in output_table:
        with open(f'{save_dir}/订单详情表.csv', 'w', newline='') as f:
            fieldnames = ["order_id", "dish_name", "price", "quantity", "detail_date", "detail_time"]
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            # writer.writeheader()
            for detail in order_details:
                writer.writerow(detail)

if __name__ == "__main__":
    generate_test_data(1000)
