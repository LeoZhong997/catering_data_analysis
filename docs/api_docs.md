 # API 文档

## 1. 数据展示模块

### 1.1 获取销售额和订单量数据
- **URL**: `/api/sales`
- **Method**: `GET`
- **请求参数**:
  - `start_date` (string, required): 起始日期，格式为 `YYYY-MM-DD`。
  - `end_date` (string, required): 结束日期，格式为 `YYYY-MM-DD`。
  - `group_by` (string, optional): 按时间分组（如 `day`, `week`, `month`），默认为 `day`。
- **响应格式**:
  ```json
  {
    "sales": [
      {"date": "2023-10-01", "total_sales": 5000, "order_count": 100},
      {"date": "2023-10-02", "total_sales": 6000, "order_count": 120}
    ]
  }
  ```

### 1.2 获取各菜品分类的销量Top 10
- **URL**: `/api/categories/sales-top10`
- **Method**: `GET`
- **请求参数**:
  - `category_id` (string, optional): 菜品分类ID，若为空则返回所有分类的Top 10。
- **响应格式**:
  ```json
  {
    "top_sales": [
      {"dish_name": "红烧肉", "sales_volume": 200},
      {"dish_name": "宫保鸡丁", "sales_volume": 180}
    ]
  }
  ```

### 1.3 获取各菜品分类的销售额Top 10
- **URL**: `/api/categories/revenue-top10`
- **Method**: `GET`
- **请求参数**:
  - `category_id` (string, optional): 菜品分类ID，若为空则返回所有分类的Top 10。
- **响应格式**:
  ```json
  {
    "top_revenue": [
      {"dish_name": "红烧肉", "revenue": 5000},
      {"dish_name": "宫保鸡丁", "revenue": 4800}
    ]
  }
  ```

## 2. 数据分析模块

### 2.1 获取会员聚类分析结果
- **URL**: `/api/members/clustering`
- **Method**: `GET`
- **请求参数**:
  - `cluster_type` (string, required): 聚类类型（如 `taste`, `category`）。
- **响应格式**:
  ```json
  {
    "clusters": [
      {"cluster_id": 1, "members": ["user1", "user2"], "features": {"preference": "辣"}},
      {"cluster_id": 2, "members": ["user3", "user4"], "features": {"preference": "甜"}}
    ]
  }
  ```

### 2.2 获取菜品关联规则
- **URL**: `/api/dishes/association-rules`
- **Method**: `GET`
- **请求参数**:
  - `min_support` (float, optional): 最小支持度，默认为 `0.1`。
  - `min_confidence` (float, optional): 最小置信度，默认为 `0.5`。
- **响应格式**:
  ```json
  {
    "rules": [
      {"antecedents": ["啤酒"], "consequents": ["炸鸡"], "support": 0.15, "confidence": 0.75},
      {"antecedents": ["米饭"], "consequents": ["红烧肉"], "support": 0.12, "confidence": 0.65}
    ]
  }
  ```

## 3. 运营策略模块

### 3.1 获取个性化推荐策略
- **URL**: `/api/recommendations`
- **Method**: `GET`
- **请求参数**:
  - `member_id` (string, required): 会员ID。
- **响应格式**:
  ```json
  {
    "recommendations": [
      {"dish_name": "红烧肉", "reason": "高价值会员偏好"},
      {"dish_name": "宫保鸡丁", "reason": "高频消费菜品"}
    ]
  }
  ```

### 3.2 获取促销建议
- **URL**: `/api/promotions`
- **Method**: `GET`
- **请求参数**:
  - `store_id` (string, required): 店铺ID。
- **响应格式**:
  ```json
  {
    "promotions": [
      {"bundle": ["啤酒", "炸鸡"], "discount": "9折", "reason": "高频组合"},
      {"bundle": ["米饭", "红烧肉"], "discount": "8.5折", "reason": "热销组合"}
    ]
  }
  ```