/*
PIZZA PLACE SALES — 04. TẠO VIEW SẠCH CHO POWER BI
Nguồn: bốn bảng bán hàng và VIEW giá chuẩn hóa.
Tên VIEW: dbo.vw_PizzaSales_Master_Clean.
Mỗi dòng = một dòng chi tiết đơn (không phải một đơn duy nhất).
Cột revenue = quantity * price_clean; các cột order_year, order_month,
order_hour phục vụ trực quan hóa theo thời gian.
Tác động: chỉ CREATE OR ALTER VIEW; không sửa bảng nguồn.
Chỉ số được so với dữ liệu tham chiếu và kết quả SQL đã chạy.
*/
USE Pizza_Sales_DB;
GO

IF OBJECT_ID(N'dbo.vw_pizza_prices_clean_v2', N'V') IS NULL
    THROW 50001, N'Thieu VIEW vw_pizza_prices_clean_v2: can chay script 06 truoc.', 1;
IF EXISTS (
    SELECT 1 FROM dbo.vw_pizza_prices_clean_v2
    WHERE price_clean IS NULL OR price_clean <= 0
)
    THROW 50002, N'Phat hien don gia da chuan hoa khong hop le.', 1;
IF EXISTS (
    SELECT pizza_id FROM dbo.vw_pizza_prices_clean_v2
    GROUP BY pizza_id HAVING COUNT(*) <> 1
)
    THROW 50003, N'Gia tri pizza_id bi trung trong VIEW gia.', 1;
IF EXISTS (
    SELECT 1 FROM dbo.order_details d
    LEFT JOIN dbo.vw_pizza_prices_clean_v2 p ON d.pizza_id = p.pizza_id
    WHERE p.pizza_id IS NULL
)
    THROW 50004, N'Co dong order_details khong tim duoc pizza_id trong VIEW gia.', 1;
GO

CREATE OR ALTER VIEW dbo.vw_PizzaSales_Master_Clean
AS
SELECT
    o.order_id,
    CONVERT(date, o.[date]) AS order_date,
    o.[time] AS order_time,
    d.order_details_id,
    d.pizza_id,
    d.quantity,
    p.pizza_type_id,
    t.name AS pizza_name,
    t.category,
    p.size,
    p.price_clean AS unit_price,
    CAST(CAST(d.quantity AS decimal(18,2)) * p.price_clean AS decimal(19,2)) AS revenue,
    YEAR(o.[date]) AS order_year,
    MONTH(o.[date]) AS order_month,
    DATEPART(HOUR, o.[time]) AS order_hour,
    p.price_imported,
    p.correction_method
FROM dbo.orders o
JOIN dbo.order_details d ON o.order_id = d.order_id
JOIN dbo.vw_pizza_prices_clean_v2 p ON d.pizza_id = p.pizza_id
JOIN dbo.pizza_types t ON p.pizza_type_id = t.pizza_type_id;
GO

-- [A] Đối chiếu KPI khi không lọc dữ liệu.
--     Kỳ vọng: 48.620 dòng, 21.350 đơn, 49.574 pizza, 817.860,05 USD.
SELECT
    COUNT_BIG(*) AS detail_rows,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(CAST(quantity AS bigint)) AS pizzas_sold,
    CAST(SUM(revenue) AS decimal(19,2)) AS total_revenue,
    CAST(SUM(revenue) / NULLIF(COUNT(DISTINCT order_id),0) AS decimal(19,2)) AS average_order_value,
    CAST(SUM(revenue) - 817860.05 AS decimal(19,2)) AS difference_vs_reference
FROM dbo.vw_PizzaSales_Master_Clean;

-- [B] Kiểm tra đơn giá, doanh thu, ngày và số SKU được bán trong VIEW.
--     distinct_pizza_skus = 91: số SKU có giao dịch, không phải tổng danh mục 96.
SELECT
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) AS null_revenue_rows,
    SUM(CASE WHEN revenue < 0 THEN 1 ELSE 0 END) AS negative_revenue_rows,
    SUM(CASE WHEN unit_price IS NULL OR unit_price <= 0 THEN 1 ELSE 0 END) AS invalid_unit_price_rows,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_date_rows,
    COUNT(DISTINCT pizza_id) AS distinct_pizza_skus
FROM dbo.vw_PizzaSales_Master_Clean;

-- [C] Đối chiếu doanh thu 12 tháng với kết quả truy vấn [2] ở file 03.
SELECT
    DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month_start,
    COUNT(DISTINCT order_id) AS total_orders,
    CAST(SUM(revenue) AS decimal(19,2)) AS monthly_revenue
FROM dbo.vw_PizzaSales_Master_Clean
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY month_start;
