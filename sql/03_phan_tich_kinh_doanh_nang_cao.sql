/* PIZZA PLACE SALES — 03. PHÂN TÍCH KINH DOANH NÂNG CAO
Microsoft SQL Server. Chạy sau 02_chuan_hoa_don_gia.sql.
Toàn bộ truy vấn doanh thu sử dụng dbo.vw_pizza_prices_clean_v2.price_clean,
không lấy trực tiếp từ dbo.pizzas.price bị lỗi khi nhập liệu.
Phân tích DOANH THU, KHÔNG phải LỢI NHUẬN (không có chi phí/giá vốn).
Các lệnh chỉ đọc; ngoại trừ kiểm tra tồn tại VIEW không có tác động dữ liệu.
*/
USE Pizza_Sales_DB;
GO
SET NOCOUNT ON;

/* KIỂM TRA TRƯỚC KHI PHÂN TÍCH
- VIEW giá sạch phải tồn tại và tất cả price_clean phải lớn hơn 0.
- pizza_id trong VIEW phải duy nhất, tránh nhân doanh thu khi JOIN.
- Mọi dòng chi tiết đơn hàng phải nối được với mã pizza.
- Nếu có lỗi, THROW sẽ dừng phiên chạy trước khi tạo báo cáo sai.
*/
IF OBJECT_ID(N'dbo.vw_pizza_prices_clean_v2', N'V') IS NULL
    THROW 50001, 'Chua co VIEW gia sach: chay file 02 truoc.', 1;

IF EXISTS (SELECT 1 FROM dbo.vw_pizza_prices_clean_v2 WHERE price_clean IS NULL OR price_clean <= 0)
    THROW 50002, 'Invalid normalized price detected; đối chiếu pizzas.csv gốc.', 1;

IF EXISTS (
    SELECT pizza_id
    FROM dbo.vw_pizza_prices_clean_v2
    GROUP BY pizza_id HAVING COUNT(*) > 1
)
    THROW 50003, 'Trung pizza_id trong VIEW gia, se lam tang doanh thu khi JOIN.', 1;

IF EXISTS (
    SELECT 1
    FROM dbo.order_details od
    LEFT JOIN dbo.vw_pizza_prices_clean_v2 pc ON pc.pizza_id = od.pizza_id
    WHERE pc.pizza_id IS NULL
)
    THROW 50004, 'Co dong chi tiet khong ghep duoc voi bang gia sach.', 1;

/* [1] TỔNG QUAN KPI: Tổng đơn, số chiếc, tổng doanh thu và trung bình.
Một order_id chỉ được tính một đơn, dù có nhiều dòng chi tiết.
AOV = tổng doanh thu / số đơn hàng, không phải doanh thu / số dòng.
*/
WITH order_totals AS (
    SELECT
        o.order_id,
        COALESCE(SUM(CAST(od.quantity AS decimal(18,2)) *
                     pc.price_clean), 0) AS order_revenue,
        COALESCE(SUM(CAST(od.quantity AS bigint)), 0) AS pizzas_sold
    FROM dbo.orders o
    LEFT JOIN dbo.order_details od ON o.order_id = od.order_id
    LEFT JOIN dbo.vw_pizza_prices_clean_v2 pc ON od.pizza_id = pc.pizza_id
    GROUP BY o.order_id
)
SELECT
    COUNT_BIG(*) AS total_orders,
    CAST(SUM(order_revenue) AS decimal(19,2)) AS total_revenue,
    SUM(pizzas_sold) AS pizzas_sold,
    CAST(AVG(CAST(order_revenue AS decimal(19,4))) AS decimal(19,2)) AS average_order_value,
    CAST(AVG(CAST(pizzas_sold AS decimal(19,4))) AS decimal(19,2)) AS average_pizzas_per_order
FROM order_totals;

/* [2] DOANH THU THEO THÁNG VÀ TĂNG TRƯỞNG MOM.
Gom theo tháng; dùng LAG lấy doanh thu tháng có bản ghi ngay trước.
Cần kiểm tra tháng bị thiếu nếu áp dụng cho bộ dữ liệu khác.
revenue_mom_pct = (doanh thu tháng này - tháng trước) / tháng trước * 100.
*/
WITH monthly AS (
    SELECT
        DATEFROMPARTS(YEAR(o.[date]), MONTH(o.[date]), 1) AS month_start,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(CAST(od.quantity AS bigint)) AS pizzas_sold,
        SUM(CAST(od.quantity AS decimal(18,2)) * pc.price_clean) AS revenue
    FROM dbo.orders o
    INNER JOIN dbo.order_details od ON o.order_id = od.order_id
    INNER JOIN dbo.vw_pizza_prices_clean_v2 pc ON od.pizza_id = pc.pizza_id
    GROUP BY DATEFROMPARTS(YEAR(o.[date]), MONTH(o.[date]), 1)
), monthly_comparison AS (
    SELECT month_start, orders, pizzas_sold, revenue,
           LAG(revenue) OVER (ORDER BY month_start) AS previous_month_revenue
    FROM monthly
)
SELECT
    month_start,
    orders,
    pizzas_sold,
    CAST(revenue AS decimal(19,2)) AS revenue,
    CAST(previous_month_revenue AS decimal(19,2)) AS previous_month_revenue,
    CAST(100.0 * (revenue - previous_month_revenue) /
         NULLIF(previous_month_revenue, 0) AS decimal(10,2)) AS revenue_mom_pct
FROM monthly_comparison
ORDER BY month_start;

/* [3] GIỜ ĐẶT HÀNG CAO ĐIỂM.
Đếm số order_id theo giờ, tính tỷ trọng và xếp hạng DENSE_RANK.
Đây là chỉ báo nhu cầu đơn hàng, chưa phản ánh chính xác tải bếp.
*/
WITH orders_by_hour AS (
    SELECT DATEPART(HOUR, o.[time]) AS order_hour, COUNT_BIG(*) AS order_count
    FROM dbo.orders o
    GROUP BY DATEPART(HOUR, o.[time])
)
SELECT order_hour, order_count,
       CAST(100.0 * order_count /
            NULLIF(SUM(order_count) OVER (), 0) AS decimal(10,2)) AS pct_of_orders,
       DENSE_RANK() OVER (ORDER BY order_count DESC) AS demand_rank
FROM orders_by_hour
ORDER BY order_count DESC, order_hour;

/* [4] MA TRẬN THỨ TRONG TUẦN × GIỜ ĐẶT HÀNG.
weekday_mon_1: 1 = thứ Hai, ..., 7 = Chủ nhật.
Dùng ngày mốc 1900-01-01 để không phụ thuộc SET DATEFIRST.
Kết quả dùng để làm heatmap và nghiên cứu phân bổ nhân sự.
*/
SELECT
    ((DATEDIFF(DAY, CONVERT(date,'19000101'), CONVERT(date,o.[date])) % 7) + 1) AS weekday_mon_1,
    DATEPART(HOUR, o.[time]) AS order_hour,
    COUNT_BIG(*) AS order_count
FROM dbo.orders o
GROUP BY
    ((DATEDIFF(DAY, CONVERT(date,'19000101'), CONVERT(date,o.[date])) % 7) + 1),
    DATEPART(HOUR, o.[time])
ORDER BY weekday_mon_1, order_hour;

/* [5] TOP 10 LOẠI PIZZA THEO DOANH THU.
Đếm số chiếc, tổng doanh thu, tỷ trọng và hạng doanh thu.
ROW_NUMBER giới hạn đúng 10 dòng; DENSE_RANK thể hiện đồng hạng.
Top theo doanh thu khác với top theo số lượng bán.
*/
WITH pizza_type_sales AS (
    SELECT pt.pizza_type_id, pt.name AS pizza_name, pt.category,
           SUM(CAST(od.quantity AS bigint)) AS units_sold,
           SUM(CAST(od.quantity AS decimal(18,2)) * pc.price_clean) AS revenue
    FROM dbo.order_details od
    INNER JOIN dbo.vw_pizza_prices_clean_v2 pc ON od.pizza_id = pc.pizza_id
    INNER JOIN dbo.pizza_types pt ON pc.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.pizza_type_id, pt.name, pt.category
), ranked AS (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
           ROW_NUMBER() OVER (ORDER BY revenue DESC, pizza_type_id) AS row_num,
           CAST(100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0)
                AS decimal(10,2)) AS revenue_share_pct
    FROM pizza_type_sales
)
SELECT pizza_name, category, units_sold,
       CAST(revenue AS decimal(19,2)) AS revenue,
       revenue_share_pct, revenue_rank
FROM ranked
WHERE row_num <= 10
ORDER BY row_num;

/* [6] CƠ CẤU DOANH THU: DANH MỤC VÀ KÍCH CỠ.
Hai truy vấn riêng để so sánh category và size.
Doanh thu cao không đồng nghĩa lợi nhuận cao nếu thiếu giá vốn.
*/
WITH category_sales AS (
    SELECT pt.category,
           SUM(CAST(od.quantity AS bigint)) AS pizzas_sold,
           SUM(CAST(od.quantity AS decimal(18,2)) * pc.price_clean) AS revenue
    FROM dbo.order_details od
    INNER JOIN dbo.vw_pizza_prices_clean_v2 pc ON od.pizza_id = pc.pizza_id
    INNER JOIN dbo.pizza_types pt ON pc.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category
)
SELECT category, pizzas_sold, CAST(revenue AS decimal(19,2)) AS revenue,
       CAST(100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0)
            AS decimal(10,2)) AS revenue_share_pct
FROM category_sales ORDER BY revenue DESC;

WITH size_sales AS (
    SELECT pc.size,
           SUM(CAST(od.quantity AS bigint)) AS pizzas_sold,
           SUM(CAST(od.quantity AS decimal(18,2)) * pc.price_clean) AS revenue
    FROM dbo.order_details od
    INNER JOIN dbo.vw_pizza_prices_clean_v2 pc ON od.pizza_id = pc.pizza_id
    GROUP BY pc.size
)
SELECT size, pizzas_sold, CAST(revenue AS decimal(19,2)) AS revenue,
       CAST(100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0)
            AS decimal(10,2)) AS revenue_share_pct
FROM size_sales ORDER BY revenue DESC;

/* [7] PHÂN LOẠI ABC THEO DOANH THU CỘNG DỒN.
Sắp xếp 32 loại pizza theo doanh thu, tính phần trăm lũy kế bằng
SUM(...) OVER (ORDER BY ... ROWS UNBOUNDED PRECEDING).
A khi lũy kế <= 80%; B khi <=95%; còn lại là C.
Nhóm ABC phản ánh đóng góp DOANH THU của sản phẩm, không phải lợi nhuận.
*/
WITH type_sales AS (
    SELECT pt.pizza_type_id, pt.name AS pizza_name,
           SUM(CAST(od.quantity AS decimal(18,2)) * pc.price_clean) AS revenue
    FROM dbo.order_details od
    INNER JOIN dbo.vw_pizza_prices_clean_v2 pc ON od.pizza_id = pc.pizza_id
    INNER JOIN dbo.pizza_types pt ON pc.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.pizza_type_id, pt.name
), cumulative AS (
    SELECT pizza_name, pizza_type_id, revenue,
           SUM(revenue) OVER (ORDER BY revenue DESC, pizza_type_id
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_revenue,
           SUM(revenue) OVER () AS total_revenue
    FROM type_sales
)
SELECT pizza_name, CAST(revenue AS decimal(19,2)) AS revenue,
       CAST(100.0 * revenue / NULLIF(total_revenue, 0) AS decimal(10,2)) AS revenue_share_pct,
       CAST(100.0 * cum_revenue / NULLIF(total_revenue, 0) AS decimal(10,2)) AS cumulative_pct,
       CASE WHEN 100.0 * cum_revenue / NULLIF(total_revenue, 0) <= 80 THEN 'A'
            WHEN 100.0 * cum_revenue / NULLIF(total_revenue, 0) <= 95 THEN 'B'
            ELSE 'C' END AS abc_segment
FROM cumulative
ORDER BY revenue DESC, pizza_type_id;

/* [8] DOANH THU TỪNG NGÀY VÀ TRUNG BÌNH TRƯỢT.
rolling_7_sales_days_avg_revenue là trung bình của tối đa 7 NGÀY
CÓ BẢN GHI gần nhất; KHÔNG mặc nhiên là 7 ngày lịch liên tiếp.
Bộ dữ liệu năm 2015 có 358 ngày bán ghi nhận, thiếu 7 ngày lịch.
*/
WITH daily AS (
    SELECT CONVERT(date, o.[date]) AS order_date,
           COUNT(DISTINCT o.order_id) AS orders,
           SUM(CAST(od.quantity AS decimal(18,2)) * pc.price_clean) AS revenue
    FROM dbo.orders o
    INNER JOIN dbo.order_details od ON o.order_id = od.order_id
    INNER JOIN dbo.vw_pizza_prices_clean_v2 pc ON od.pizza_id = pc.pizza_id
    GROUP BY CONVERT(date, o.[date])
)
SELECT order_date, orders, CAST(revenue AS decimal(19,2)) AS revenue,
       CAST(AVG(revenue) OVER (
           ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ) AS decimal(19,2)) AS rolling_7_sales_days_avg_revenue
FROM daily ORDER BY order_date;
