# Ghi chú SQL — Pizza Place Sales Analysis

## 1. Dữ liệu gồm những gì?

| Bảng | Vai trò | Quan hệ |
|---|---|---|
| `orders` | Mã, ngày và giờ của đơn | `order_id` |
| `order_details` | Mã pizza và số lượng trên từng dòng đơn | `order_id`, `pizza_id` |
| `pizzas` | Giá, kích cỡ và mã loại pizza | `pizza_id`, `pizza_type_id` |
| `pizza_types` | Tên và danh mục pizza | `pizza_type_id` |

Một đơn hàng có thể chứa nhiều dòng chi tiết. Khi tính **số đơn**, dùng `COUNT(DISTINCT order_id)` hoặc đếm từng dòng trong `orders`, không dùng `COUNT(*)` trên bảng sau JOIN.

## 2. Tại sao cần chuẩn hóa đơn giá?

Khi nhập dữ liệu ban đầu, một số dấu thập phân đã bị mất, khiến doanh thu tính ra khoảng **47.429.918** thay vì **817.860,05 USD**. Đã phát hiện 74/96 mã SKU cần xử lý về tỷ lệ, trong khi 22 SKU có mức giá bình thường.

Ví dụ `2075` tương ứng `20.75`, `125` tương ứng `12.50`, `975` tương ứng `9.75`. Vì vậy **không thể chia toàn bộ cột giá cho 100**. File `02_chuan_hoa_don_gia.sql` tạo VIEW `vw_pizza_prices_clean_v2` để xử lý theo từng trường hợp mà không cập nhật dữ liệu gốc.

**Cảnh báo:** Đây là quy tắc suy luận theo bộ dữ liệu. Tổng doanh thu khớp chưa đủ để chứng minh từng SKU đúng; cần đối chiếu tất cả 96 giá với `pizzas.csv` gốc.

## 3. Các kỹ thuật T-SQL đã sử dụng

| Kỹ thuật | Ứng dụng |
|---|---|
| `JOIN` | Ghép đơn hàng, chi tiết, bảng giá và danh mục |
| `CASE WHEN` | Chuẩn hóa giá và chia nhóm ABC |
| `TRY_CONVERT` | Phát hiện giá và ngày không hợp lệ |
| `CTE` (`WITH ... AS`) | Chia truy vấn thành những bước logic |
| `LAG` | So sánh doanh thu tháng hiện tại và tháng trước |
| `DENSE_RANK`, `ROW_NUMBER` | Xếp hạng giờ cao điểm và sản phẩm |
| `SUM() OVER()` | Tính tổng và doanh thu cộng dồn |
| `NULLIF` | Tránh chia cho 0 trong KPI/tỷ lệ |
| `CREATE OR ALTER VIEW` | Chuẩn bị lớp dữ liệu dùng lại cho Power BI |

## 4. Câu hỏi kinh doanh và truy vấn tương ứng

1. **[1] KPI:** Doanh thu, số đơn, số pizza, AOV là bao nhiêu?
2. **[2] Doanh thu theo tháng:** Tháng nào cao nhất, tỷ lệ tăng/giảm MoM?
3. **[3] Theo giờ:** Khung giờ nào nhiều đơn nhất?
4. **[4] Thứ–giờ:** Nhu cầu đặt hàng thay đổi theo ngày trong tuần thế nào?
5. **[5] Top 10:** Loại pizza nào đóng góp doanh thu lớn nhất?
6. **[6] Cơ cấu:** Phân bổ doanh thu theo category và size?
7. **[7] ABC:** Doanh thu tích lũy phân bố ra sao giữa 32 loại pizza?
8. **[8] Theo ngày:** Ngày nào có biến động và trung bình trượt biến đổi thế nào?

## 5. Những lưu ý dễ nhầm

- **Doanh thu khác lợi nhuận**. Dữ liệu thiếu chi phí nên không tính được biên lợi nhuận.
- Có **96 SKU** (pizza × size) trong danh mục, nhưng **91 SKU** xuất hiện trong giao dịch.
- `rolling_7_sales_days_avg_revenue` là trung bình tối đa 7 **ngày có bản ghi bán hàng**, không luôn là 7 ngày lịch liên tiếp.
- ABC đang phân loại theo **doanh thu toàn năm 2015**, không phân nhóm lại khi người xem chọn slicer.
- Khi lọc theo danh mục, AOV dùng doanh thu của danh mục đó chia số đơn duy nhất có ít nhất một pizza thuộc danh mục; đây không phải giá trị toàn bộ giỏ hàng.

## 6. Thứ tự chạy trên SSMS

1. `01_kiem_tra_chat_luong_du_lieu.sql` — kiểm tra dữ liệu thô.
2. `02_chuan_hoa_don_gia.sql` — tạo VIEW chuẩn hóa giá và kiểm chứng.
3. `03_phan_tich_kinh_doanh_nang_cao.sql` — thực hiện 8 phần phân tích.
4. `04_tao_view_cho_power_bi.sql` — tạo VIEW để kết nối dashboard.

Các script mặc định `USE Pizza_Sales_DB`. Đổi tên database nếu máy khác có tên khác. SQL Server cần hỗ trợ `CREATE OR ALTER VIEW` (SQL Server 2016 SP1 trở lên).
