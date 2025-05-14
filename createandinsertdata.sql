CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name TEXT,
  email TEXT UNIQUE,
  phone TEXT
);

CREATE TABLE IF NOT EXISTS addresses (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  province TEXT,
  district TEXT,
  commune TEXT,
  address_detail TEXT,
  house_type TEXT
);

CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  name TEXT
);

CREATE TABLE IF NOT EXISTS stores (
  id SERIAL PRIMARY KEY,
  name TEXT,
  location TEXT
);

CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name TEXT,
  category_id INTEGER REFERENCES categories(id),
  price INT
);

CREATE TABLE IF NOT EXISTS product_variants (
  id SERIAL PRIMARY KEY,
  product_id INTEGER REFERENCES products(id),
  size INT,
  color TEXT,
  quantity_in_stock INT,
  store_id INTEGER REFERENCES stores(id)
);

CREATE TABLE IF NOT EXISTS orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  address_id INTEGER REFERENCES addresses(id),
  order_date TIMESTAMP DEFAULT NOW(),
  total_amount INT,
  status TEXT DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS order_items (
  id SERIAL PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id),
  product_variant_id INTEGER REFERENCES product_variants(id),
  quantity INT,
  price_at_time_of_order INT
);

CREATE TABLE IF NOT EXISTS vouchers (
  id SERIAL PRIMARY KEY,
  code TEXT,
  discount_percent INT,
  valid_until DATE
);

CREATE TABLE IF NOT EXISTS user_vouchers (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  voucher_id INTEGER REFERENCES vouchers(id),
  used BOOLEAN DEFAULT FALSE
);

-- Chèn thông tin người dùng 
INSERT INTO users (name, email, phone)
VALUES ('assessment', 'truong.caonguyenvan@hcmut.edu.vn', '328355333')
ON CONFLICT (email) DO NOTHING;

-- Chèn địa chỉ người dùng
INSERT INTO addresses (user_id, province, district, commune, address_detail, house_type)
VALUES (
  (SELECT id FROM users WHERE email = 'truong.caonguyenvan@hcmut.edu.vn'), 
  'Bắc Kạn', 'Ba Bể', 'Phúc Lộc', '73 tân hoà 2',
  'nhà riêng'
);

--Chèn thông tin cửa hàng 
INSERT INTO stores (name, location)
VALUES ('Store 1', 'Hà Nội');
-- Chèn thông tin danh mục sản phẩm
-- Giả sử category_id là 1
INSERT INTO categories (name)
VALUES ('Sneakers');

-- Chèn thông tin sản phẩm 
INSERT INTO products (name, price, category_id)
VALUES ('KAPPA Women''s Sneakers', 980000, 1);  -- category_id phải phù hợp với giá trị trong bảng categories

-- Chèn thông tin biến thể sản phẩm 
INSERT INTO product_variants (product_id, size, color, quantity_in_stock, store_id)
VALUES (
  (SELECT id FROM products WHERE name = 'KAPPA Women''s Sneakers'),
  36, 'yellow', 5, 1  -- store_id giả sử là 1, có thể thay đổi theo cửa hàng cụ thể
);
-- Chèn đơn hàng
INSERT INTO orders (user_id, address_id, total_amount, status)
VALUES (
  (SELECT id FROM users WHERE email = 'truong.caonguyenvan@hcmut.edu.vn'), 
  (SELECT id FROM addresses WHERE user_id = (SELECT id FROM users WHERE email = 'truong.caonguyenvan@hcmut.edu.vn')),
  980000, 'pending'
)
RETURNING id;

-- Chèn các mục đơn hàng
INSERT INTO order_items (order_id, product_variant_id, quantity, price_at_time_of_order)
VALUES (
  (SELECT id FROM orders WHERE user_id = (
	  SELECT id 
	  FROM users 
	  WHERE email = 'truong.caonguyenvan@hcmut.edu.vn') 
	  ORDER BY order_date DESC LIMIT 1),
  (SELECT id FROM product_variants WHERE product_id = (
	  SELECT id 
	  FROM products
	  WHERE name = 'KAPPA Women''s Sneakers') AND size = 36 AND color = 'yellow'),
  1, 980000
);

SELECT * FROM users;
SELECT * FROM addresses ;
SELECT * FROM orders;
SELECT * FROM products;
SELECT * FROM categories;
UPDATE users
SET email = 'truong.caonguyenvan@hcmut.edu.vn'
WHERE id = 1;

SELECT 
  p.name AS product_name,
  p.price,
  pv.size,
  pv.quantity_in_stock AS quantity,
  pv.color
FROM 
  products p
JOIN 
  product_variants pv ON p.id = pv.product_id
WHERE 
  p.name = 'KAPPA Women''s Sneakers' ;
-----
SELECT 
  u.name, u.email, u.phone, a.province, a.district, a.commune, a.address_detail,a.house_type
FROM 
  users u
JOIN 
  addresses a ON u.id = a.user_id
WHERE 
  u.email = 'truong.caonguyenvan@hcmut.edu.vn';
-------
SELECT 
    EXTRACT(MONTH FROM o.order_date) AS month,
    AVG(oi.quantity * oi.price_at_time_of_order) AS average_order_value
FROM 
    orders o
JOIN 
    order_items oi ON o.id = oi.order_id
WHERE 
    EXTRACT(YEAR FROM o.order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 
    EXTRACT(MONTH FROM o.order_date)
ORDER BY 
    month;
-------
WITH recent_purchases AS (
    -- Lấy khách hàng đã thực hiện mua hàng trong 12 tháng qua
    SELECT DISTINCT o.user_id
    FROM orders o
    WHERE o.order_date > CURRENT_DATE - INTERVAL '12 months'
),
last_6_months AS (
    -- Lấy khách hàng đã thực hiện mua hàng trong 6 tháng qua
    SELECT DISTINCT o.user_id
    FROM orders o
    WHERE o.order_date > CURRENT_DATE - INTERVAL '6 months'
),
previous_6_months AS (
    -- Lấy khách hàng đã thực hiện mua hàng trong 6 đến 12 tháng trước
    SELECT DISTINCT o.user_id
    FROM orders o
    WHERE o.order_date BETWEEN CURRENT_DATE - INTERVAL '12 months' AND CURRENT_DATE - INTERVAL '6 months'
)
-- Tính toán tỷ lệ khách hàng rời bỏ
SELECT
  CASE 
        WHEN COUNT(DISTINCT rp.user_id) = 0 THEN 0
        ELSE ROUND(COUNT(DISTINCT psm.user_id) * 100.0 / COUNT(DISTINCT rp.user_id), 2)
    END AS churn_rate_percentage
FROM previous_6_months psm
JOIN recent_purchases rp ON psm.user_id = rp.user_id
LEFT JOIN last_6_months lsm ON psm.user_id = lsm.user_id
WHERE lsm.user_id IS NULL;


