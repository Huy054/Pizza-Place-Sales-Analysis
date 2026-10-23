/*
PIZZA PLACE SALES — 02. CHUẨN HÓA ĐƠN GIÁ
VẤN ĐỀ: quá trình nhập dữ liệu khiến một số giá mất dấu thập phân.
Ví dụ: 2075 -> 20,75 (chia 100); 125 -> 12,50 (chia 10);
       975 -> 9,75 (chia 100); 16 -> 16,00 (giữ nguyên).
LƯU Ý: Quy tắc suy luận theo khoảng giá chỉ áp dụng thử cho bộ dữ liệu này.
Việc khớp tổng doanh thu KHÔNG thay thế đối chiếu từng giá với CSV gốc.
Tác động: CREATE OR ALTER VIEW dbo.vw_pizza_prices_clean_v2;
         không UPDATE/DELETE bất kỳ bảng nguồn nào.
Kết quả đã chạy: 22 giá giữ nguyên, 28 chia 10, 45 chia 100,
                  1 trường hợp chia 100 thuộc nhóm giá thấp.
*/
USE Pizza_Sales_DB;
GO
CREATE OR ALTER VIEW dbo.vw_pizza_prices_clean_v2
AS
SELECT
    p.pizza_id,
    p.pizza_type_id,
    p.size,
    p.price AS price_imported,
    r.raw_price,
    x.price_clean,
    x.correction_method
FROM dbo.pizzas AS p
CROSS APPLY (
    SELECT TRY_CONVERT(decimal(19, 4), p.price) AS raw_price
) AS r
CROSS APPLY (
    SELECT
      CAST(CASE
        WHEN r.raw_price > 0 AND r.raw_price < 100
          THEN r.raw_price
        WHEN r.raw_price >= 1000
             AND r.raw_price / 100.0 BETWEEN 9.50 AND 36.00
          THEN r.raw_price / 100.0
        WHEN r.raw_price >= 100 AND r.raw_price < 1000
             AND r.raw_price / 10.0 BETWEEN 9.50 AND 36.00
          THEN r.raw_price / 10.0
        WHEN r.raw_price >= 100 AND r.raw_price < 1000
             AND r.raw_price / 100.0 BETWEEN 9.50 AND 36.00
          THEN r.raw_price / 100.0
        ELSE NULL
      END AS decimal(18, 2)) AS price_clean,
      CASE
        WHEN r.raw_price IS NULL OR r.raw_price <= 0 THEN 'INVALID'
        WHEN r.raw_price < 100 THEN 'KEEP_ORIGINAL'
        WHEN r.raw_price >= 1000
             AND r.raw_price / 100.0 BETWEEN 9.50 AND 36.00
          THEN 'DIVIDE_BY_100'
        WHEN r.raw_price >= 100 AND r.raw_price < 1000
             AND r.raw_price / 10.0 BETWEEN 9.50 AND 36.00
          THEN 'DIVIDE_BY_10'
        WHEN r.raw_price >= 100 AND r.raw_price < 1000
             AND r.raw_price / 100.0 BETWEEN 9.50 AND 36.00
          THEN 'DIVIDE_BY_100_LOW_PRICE'
        ELSE 'REVIEW_WITH_SOURCE_CSV'
      END AS correction_method
) AS x;
GO

-- [1] Đếm số SKU theo phương pháp chuẩn hóa giá (tổng cộng 96 SKU).
SELECT correction_method, COUNT(*) AS sku_count,
       MIN(price_clean) AS min_clean_price,
       MAX(price_clean) AS max_clean_price
FROM dbo.vw_pizza_prices_clean_v2
GROUP BY correction_method
ORDER BY correction_method;

-- [2] Soát tất cả giá gốc từ 100 đến 999.
--     Không phải giá nào trong khoảng này cũng chia cho 10.
SELECT pizza_id, size, price_imported, price_clean, correction_method
FROM dbo.vw_pizza_prices_clean_v2
WHERE raw_price >= 100 AND raw_price < 1000
ORDER BY raw_price, pizza_id;

-- [3] Kiểm tra dữ liệu sau chuẩn hóa.
--     price_null_skus và unmatched_order_lines đều cần bằng 0.
SELECT COUNT(*) AS pizza_sku_count,
       SUM(CASE WHEN price_clean IS NULL THEN 1 ELSE 0 END) AS price_null_skus,
       MIN(price_clean) AS min_clean_price,
       MAX(price_clean) AS max_clean_price
FROM dbo.vw_pizza_prices_clean_v2;

SELECT COUNT(*) AS unmatched_order_lines
FROM dbo.order_details AS od
LEFT JOIN dbo.vw_pizza_prices_clean_v2 AS pc
  ON pc.pizza_id = od.pizza_id
WHERE pc.pizza_id IS NULL OR pc.price_clean IS NULL;

-- [4] Đối chiếu KPI với bộ dữ liệu tham chiếu.
--     Nếu difference_vs_reference khác 0, cần kiểm tra lại trước khi dùng Power BI.
WITH orders_agg AS (
    SELECT
        o.order_id,
        SUM(CAST(od.quantity AS bigint)) AS pizzas_sold,
        SUM(CAST(od.quantity AS decimal(19,2)) * pc.price_clean) AS order_revenue
    FROM dbo.orders AS o
    INNER JOIN dbo.order_details AS od ON od.order_id = o.order_id
    INNER JOIN dbo.vw_pizza_prices_clean_v2 AS pc ON pc.pizza_id = od.pizza_id
    GROUP BY o.order_id
), total AS (
    SELECT COUNT_BIG(*) AS total_orders,
           SUM(pizzas_sold) AS total_pizzas_sold,
           CAST(SUM(order_revenue) AS decimal(19,2)) AS total_revenue
    FROM orders_agg
)
SELECT total_orders, total_pizzas_sold, total_revenue,
       CAST(total_revenue / NULLIF(total_orders, 0) AS decimal(19,2)) AS average_order_value,
       CAST(1.0 * total_pizzas_sold / NULLIF(total_orders, 0) AS decimal(19,2)) AS average_pizzas_per_order,
       CAST(total_revenue - 817860.05 AS decimal(19,2)) AS difference_vs_reference
FROM total;

-- [5] Xếp hạng 10 loại pizza theo doanh thu sau khi chuẩn hóa giá.
SELECT TOP (10)
    pt.name AS pizza_name,
    SUM(CAST(od.quantity AS bigint)) AS units_sold,
    CAST(SUM(CAST(od.quantity AS decimal(19,2)) * pc.price_clean) AS decimal(19,2)) AS revenue
FROM dbo.order_details od
INNER JOIN dbo.vw_pizza_prices_clean_v2 pc ON od.pizza_id = pc.pizza_id
INNER JOIN dbo.pizza_types pt ON pc.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue DESC, pt.name;

-- [6] Kiểm tra thủ công các SKU đại diện, kể cả 975 phải tương ứng 9,75.
SELECT pizza_id, size, price_imported, price_clean, correction_method
FROM dbo.vw_pizza_prices_clean_v2
WHERE pizza_id IN (
    'the_greek_xxl', 'brie_carre_s', 'bbq_ckn_l',
    'classic_dlx_m', 'pepperoni_s'
)
ORDER BY pizza_id;

/*
CÁC BƯỚC KIỂM CHỨNG TIẾP THEO
1. Kiểm tra kết quả [1], [3], [4]; số dòng không ghép được cần bằng 0.
2. Đối chiếu toàn bộ 96 giá sau chuẩn hóa với pizzas.csv gốc theo pizza_id.
3. Chỉ khi kiểm chứng xong, sử dụng VIEW sạch để phân tích doanh thu.
4. Không cập nhật trực tiếp bảng gốc; việc sửa nguồn import là bước riêng.
*/
