# Ghi chú Power BI

## Nguồn dữ liệu

Dashboard sử dụng `dbo.vw_PizzaSales_Master_Clean` từ SQL Server, không sử dụng đơn giá thô từng bị lỗi nhập liệu. Khi mở PBIX trên máy khác, **cần cập nhật cấu hình kết nối tới SQL Server của máy đó** và có dữ liệu tương ứng.

## Hai trang trong file PDF

- **Sales Overview:** 4 KPI; xu hướng doanh thu theo tháng, số đơn hàng theo giờ, doanh thu theo danh mục.
- **Product Performance:** Top 10 loại pizza, doanh thu theo size, phân loại ABC toàn năm và ba Card số loại pizza.

## Cách đọc bộ lọc

- `Month category` và `Pizza category` là hai bộ lọc đồng bộ giữa hai trang.
- Monthly Revenue Trend được cấu hình giữ đủ 12 tháng khi lọc tháng; lọc category vẫn tác động tới biểu đồ.
- Phân loại ABC là bảng DAX **cố định theo toàn bộ dữ liệu 2015**, không tự thay đổi theo hai bộ lọc.
- Với slicer danh mục, AOV được tính trên doanh thu của danh mục và số đơn có xuất hiện danh mục đó.

## Màu sắc

- Xanh `#60A5FA`: chỉ số/sản phẩm thông thường.
- Cam `#F59E0B`: giờ nhiều đơn nhất hoặc sản phẩm/kích cỡ có doanh thu cao nhất theo lựa chọn bộ lọc.
- Phần ABC dùng các màu riêng để phân biệt ba nhóm.

## Kiểm tra trước khi công bố

- Bảo đảm PBIX mở ra với **Month và Pizza Category = Tất cả**.
- Xóa hoặc ẩn trang `Trang 1` cũ nếu còn biểu đồ doanh thu chưa chuẩn hóa.
- Đối chiếu bốn KPI với ảnh/PDF: $817.860,05 | 21.350 | 49.574 | $38,31.
- Đảm bảo không công bố mật khẩu, khóa truy cập hoặc thông tin nội bộ trong cấu hình kết nối.
