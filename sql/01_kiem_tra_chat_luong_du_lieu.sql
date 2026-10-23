/*
PIZZA PLACE SALES — 01. KIỂM TRA CHẤT LƯỢNG DỮ LIỆU
Hệ quản trị: Microsoft SQL Server (T-SQL).
Bảng nguồn: dbo.orders, dbo.order_details, dbo.pizzas, dbo.pizza_types.
Mục đích: kiểm tra số dòng, khóa trùng, giá trị trống và tính toàn vẹn quan hệ.
Chỉ thực hiện SELECT, không thay đổi dữ liệu gốc.
Các truy vấn được thiết kế cho bộ dữ liệu Pizza Place Sales năm 2015.
*/
USE Pizza_Sales_DB;
GO
SET NOCOUNT ON;

-- [1] Đếm số dòng ở bốn bảng nguồn để thiết lập mốc đối chiếu sau khi JOIN.
SELECT 'orders' AS table_name, COUNT_BIG(*) AS row_count FROM dbo.orders
UNION ALL SELECT 'order_details', COUNT_BIG(*) FROM dbo.order_details
UNION ALL SELECT 'pizzas', COUNT_BIG(*) FROM dbo.pizzas
UNION ALL SELECT 'pizza_types', COUNT_BIG(*) FROM dbo.pizza_types;

-- [2] Tìm khóa định danh bị trùng. Kết quả lý tưởng: không trả về dòng nào.
SELECT order_id, COUNT(*) AS duplicate_count
FROM dbo.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT pizza_id, COUNT(*) AS duplicate_count
FROM dbo.pizzas
GROUP BY pizza_id
HAVING COUNT(*) > 1;

SELECT pizza_type_id, COUNT(*) AS duplicate_count
FROM dbo.pizza_types
GROUP BY pizza_type_id
HAVING COUNT(*) > 1;

-- [3] Kiểm tra mã đơn trống, ngày/giờ trống hoặc không chuyển đổi được.
--     Cần kiểm tra định dạng ngày (locale) khi nhập CSV vào SQL Server.
SELECT
    COUNT_BIG(*) AS total_orders,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN [date] IS NULL OR TRY_CONVERT(date, [date]) IS NULL THEN 1 ELSE 0 END) AS invalid_order_date,
    SUM(CASE WHEN [time] IS NULL OR TRY_CONVERT(time(0), [time]) IS NULL THEN 1 ELSE 0 END) AS invalid_order_time
FROM dbo.orders;

-- [4] Kiểm tra khóa liên kết, số lượng bán và đơn giá không hợp lệ.
--     Lưu ý: giá sai hệ số 10/100 có thể vẫn hợp lệ về mặt kiểu dữ liệu.
SELECT
    COUNT_BIG(*) AS total_lines,
    SUM(CASE WHEN order_id IS NULL OR pizza_id IS NULL THEN 1 ELSE 0 END) AS null_foreign_keys,
    SUM(CASE WHEN TRY_CONVERT(decimal(18,2), quantity) IS NULL
                  OR TRY_CONVERT(decimal(18,2), quantity) <= 0 THEN 1 ELSE 0 END) AS invalid_quantities
FROM dbo.order_details;

SELECT
    COUNT_BIG(*) AS total_skus,
    SUM(CASE WHEN pizza_id IS NULL OR pizza_type_id IS NULL THEN 1 ELSE 0 END) AS null_keys,
    SUM(CASE WHEN TRY_CONVERT(decimal(18,2), price) IS NULL
                  OR TRY_CONVERT(decimal(18,2), price) < 0 THEN 1 ELSE 0 END) AS invalid_prices
FROM dbo.pizzas;

-- [5] Tìm khóa liên kết thiếu giữa đơn hàng, chi tiết và danh mục.
--     Kỳ vọng mỗi chỉ số problem_rows bằng 0.
SELECT 'detail_without_order' AS issue, COUNT_BIG(*) AS problem_rows
FROM dbo.order_details od
LEFT JOIN dbo.orders o ON o.order_id = od.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'detail_without_pizza', COUNT_BIG(*)
FROM dbo.order_details od
LEFT JOIN dbo.pizzas p ON p.pizza_id = od.pizza_id
WHERE p.pizza_id IS NULL
UNION ALL
SELECT 'pizza_without_type', COUNT_BIG(*)
FROM dbo.pizzas p
LEFT JOIN dbo.pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
WHERE pt.pizza_type_id IS NULL
UNION ALL
SELECT 'order_without_details', COUNT_BIG(*)
FROM dbo.orders o
LEFT JOIN dbo.order_details od ON od.order_id = o.order_id
WHERE od.order_id IS NULL;

-- [6] Kiểm tra JOIN có làm tăng/giảm dòng so với order_details hay không.
--     Nếu các bảng khóa duy nhất và quan hệ đúng, hai số phải bằng nhau.
SELECT
    (SELECT COUNT_BIG(*) FROM dbo.order_details) AS source_detail_rows,
    COUNT_BIG(*) AS fully_joined_rows
FROM dbo.order_details od
INNER JOIN dbo.orders o ON o.order_id = od.order_id
INNER JOIN dbo.pizzas p ON p.pizza_id = od.pizza_id
INNER JOIN dbo.pizza_types pt ON pt.pizza_type_id = p.pizza_type_id;
