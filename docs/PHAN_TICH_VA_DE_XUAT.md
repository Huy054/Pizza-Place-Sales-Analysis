# Pizza Place Sales Analysis — Phân tích kinh doanh và đề xuất

## 1. Phạm vi dự án

Dự án sử dụng **SQL Server** và **Power BI** để phân tích dữ liệu bán pizza năm **2015**, gồm **21.350 đơn hàng**, **49.574 chiếc pizza bán ra** và **32 loại pizza** (tương ứng **96 mã sản phẩm theo loại và kích cỡ — SKU** trong danh mục). Đơn vị tiền tệ là **USD**.

Đây là **phân tích mô tả dữ liệu bán hàng trong quá khứ**. Các kết quả không đủ để khẳng định quan hệ nguyên nhân–kết quả hoặc khả năng sinh lời của từng sản phẩm.

## 2. Kiểm tra và chuẩn hóa chất lượng dữ liệu

Trong quá trình kiểm tra dữ liệu bằng SQL, phát hiện **74/96 SKU có đơn giá nhập vào bị sai tỷ lệ do dấu thập phân**, trong khi 22 SKU còn lại có mức giá hợp lý. Dự án sử dụng **VIEW chuẩn hóa giá** để xử lý các dạng sai lệch khác nhau mà **không ghi đè lên bảng dữ liệu gốc**.

Sau khi chuẩn hóa, kết quả đối chiếu với số liệu tham chiếu đạt:

| Chỉ số | Kết quả |
|---|---:|
| Tổng doanh thu (Total Revenue) | **817.860,05 USD** |
| Tổng số đơn hàng duy nhất (Total Orders) | **21.350** |
| Tổng số pizza bán ra (Pizzas Sold) | **49.574** |
| Giá trị đơn hàng trung bình (AOV) | **38,31 USD** |
| Số dòng chi tiết đơn hàng | **48.620** |

Các phép kiểm tra đã thực hiện không phát hiện dòng doanh thu trống hoặc âm, đơn giá không hợp lệ, ngày đặt hàng trống hay chi tiết đơn hàng không ghép được với bảng liên quan.

**Giới hạn kiểm chứng:** Mặc dù KPI tổng đã khớp số liệu tham chiếu, vẫn nên đối chiếu trực tiếp **96 đơn giá theo SKU với file CSV gốc** trước khi xác nhận lỗi nguồn giá đã được khắc phục hoàn toàn ở cấp từng sản phẩm.

## 3. Kết quả phân tích kinh doanh

### 3.1. Doanh thu biến động theo tháng

- Tổng doanh thu năm 2015: **817.860,05 USD**.
- **Tháng 7** có doanh thu cao nhất: **72.557,90 USD**.
- **Tháng 10** có doanh thu thấp nhất: **64.027,60 USD**.
- Doanh thu tháng 11 tăng **9,95%** so với tháng 10, sau đó giảm **8,09%** vào tháng 12.

**Nhận xét:** Doanh thu không tăng đều mà biến động giữa các tháng. Dữ liệu hiện có chưa đủ để xác định nguyên nhân, vì không bao gồm thông tin chi tiết về chương trình khuyến mãi, lượt khách, số ngày mở cửa hoặc điều kiện thời tiết.

**Đề xuất:** Theo dõi đồng thời doanh thu, số đơn, doanh thu trung bình trên đơn, số ngày hoạt động và chương trình khuyến mãi để đánh giá trước khi điều chỉnh kế hoạch tồn kho hay ngân sách marketing.

### 3.2. Nhu cầu đặt hàng tập trung vào giờ trưa và đầu giờ tối

| Khung giờ | Số đơn hàng | Tỷ trọng số đơn năm 2015 |
|---|---:|---:|
| 12:00 | **2.520** | **11,80%** |
| 13:00 | 2.455 | 11,50% |
| 18:00 | 2.399 | 11,24% |
| 17:00 | 2.336 | 10,94% |
| 19:00 | 2.009 | 9,41% |

**Nhận xét:** Hai khoảng thời gian nổi bật là buổi trưa và đầu giờ tối. Xét toàn bộ dữ liệu năm, **12:00** là khung giờ có số đơn cao nhất.

**Đề xuất:** Đánh giá việc bố trí nhân viên bếp, công tác chuẩn bị nguyên liệu và năng lực phục vụ/giao hàng tại những giờ cao điểm. Dashboard đã có chức năng **tự động tô màu khung giờ có nhiều đơn nhất theo bộ lọc**, hỗ trợ kiểm tra sự thay đổi giữa các tháng và danh mục pizza.

### 3.3. Classic dẫn đầu doanh thu ở cấp danh mục

| Danh mục | Pizza bán ra | Doanh thu (USD) | Tỷ trọng doanh thu |
|---|---:|---:|---:|
| Classic | 14.888 | **220.053,10** | **26,91%** |
| Supreme | 11.987 | 208.197,00 | 25,46% |
| Chicken | 11.050 | 195.919,50 | 23,96% |
| Veggie | 11.649 | 193.690,45 | 23,68% |

**Nhận xét:** Doanh thu giữa bốn danh mục tương đối cân bằng, trong đó **Classic** đóng góp nhiều nhất.

**Đề xuất:** Đánh giá nhu cầu nguyên liệu và hiệu quả các chương trình theo từng danh mục. Không kết luận danh mục nào có lợi nhuận cao nhất chỉ dựa trên doanh thu.

### 3.4. Ba sản phẩm Chicken đứng đầu bảng xếp hạng doanh thu

| Loại pizza | Doanh thu (USD) | Tỷ trọng |
|---|---:|---:|
| The Thai Chicken Pizza | **43.434,25** | **5,31%** |
| The Barbecue Chicken Pizza | 42.768,00 | 5,23% |
| The California Chicken Pizza | 41.409,50 | 5,06% |

Ba sản phẩm này đóng góp **15,60% tổng doanh thu năm**.

**Nhận xét:** Mặc dù Classic dẫn đầu khi xét tổng doanh thu theo danh mục, **ba sản phẩm có doanh thu cao nhất đều thuộc Chicken**. Điều này cho thấy việc phân tích ở các cấp độ khác nhau có thể mang lại góc nhìn kinh doanh khác nhau.

**Đề xuất:** Theo dõi nguồn cung nguyên liệu cho các sản phẩm dẫn đầu, cân nhắc vị trí hiển thị trên thực đơn và kiểm chứng hiệu quả của các chương trình giới thiệu sản phẩm trước khi áp dụng rộng rãi.

### 3.5. Size L mang lại doanh thu lớn nhất

| Kích cỡ | Doanh thu (USD) | Tỷ trọng |
|---|---:|---:|
| L | **375.318,70** | **45,89%** |
| M | 249.382,25 | 30,49% |
| S | 178.076,50 | 21,77% |
| XL | 14.076,00 | 1,72% |
| XXL | 1.006,60 | 0,12% |

**Nhận xét:** Hai kích cỡ **L và M đóng góp khoảng 76,38% doanh thu**. Các kích cỡ XL và XXL có doanh thu thấp hơn đáng kể.

**Đề xuất:** Ưu tiên độ chính xác trong dự báo nguyên liệu và chuẩn bị vận hành đối với những kích cỡ có nhu cầu lớn. Trước khi cắt giảm các kích cỡ bán ít, cần xem xét chi phí, sự biến động nhu cầu và vai trò của chúng trong thực đơn.

### 3.6. Phân tích ABC hỗ trợ xác định nhóm sản phẩm cần ưu tiên theo dõi

Dựa trên thứ tự đóng góp doanh thu tích lũy của **32 loại pizza**, kết quả phân nhóm theo quy tắc áp dụng trong dự án như sau:

| Nhóm ABC | Số loại pizza | Tỷ trọng doanh thu năm |
|---|---:|---:|
| A | **21** | **78,90%** |
| B | **7** | **14,23%** |
| C | **4** | **6,87%** |
| **Tổng** | **32** | **100%** |

**Nhận xét:** Gần 79% doanh thu được tạo ra bởi **21 loại pizza thuộc nhóm A**, chứ không chỉ tập trung vào một hoặc hai sản phẩm.

**Đề xuất:** Có thể dùng phân nhóm ABC để xác định mức độ ưu tiên khi theo dõi sản phẩm và lập kế hoạch tồn kho. Tuy nhiên, đây là **ABC theo doanh thu**, không phải lợi nhuận. Không nên quyết định ngừng bán sản phẩm nhóm C khi chưa có thông tin về chi phí và biên lợi nhuận.

## 4. Các chức năng nổi bật trong Power BI

### 4.1. Trang Sales Overview

Trang này thể hiện bốn KPI chính (**Total Revenue, Total Orders, Pizzas Sold, Average Order Value**), biểu đồ doanh thu theo tháng, số đơn theo giờ và doanh thu theo danh mục. Hai bộ lọc **Month** và **Pizza Category** cho phép tương tác với dữ liệu, đồng thời biểu đồ số đơn tự động làm nổi bật giờ cao điểm tương ứng với lựa chọn hiện tại.

### 4.2. Trang Product Performance

Trang này có Top 10 pizza theo doanh thu, doanh thu theo kích cỡ, bộ lọc đồng bộ và tính năng tô màu tự động cho sản phẩm/kích cỡ có doanh thu cao nhất. Ngoài ra còn có **ABC Analysis theo toàn bộ năm 2015** và ba Card thể hiện số loại pizza thuộc từng nhóm.

### 4.3. Những lưu ý khi giải thích dashboard

1. Khi lọc theo danh mục, **AOV** được tính bằng *doanh thu của danh mục được chọn / số đơn duy nhất có chứa danh mục đó*. Đây **không phải** giá trị đầy đủ của toàn bộ giỏ hàng trong các đơn liên quan.
2. Bộ lọc tháng được thiết lập **không làm thay đổi biểu đồ Monthly Revenue Trend**, nhằm giữ đường xu hướng đủ 12 tháng; bộ lọc danh mục vẫn tác động đến đường xu hướng.
3. **ABC Analysis là phân nhóm cố định theo dữ liệu cả năm**, không tự tính lại ranh giới A/B/C theo bộ lọc tháng hoặc danh mục. Phần này cần ghi rõ: **“Full Year 2015 — All Products”**.
4. Bộ dữ liệu không có giá vốn và chi phí hoạt động, vì vậy không thể kết luận về **lợi nhuận**.
5. Dữ liệu chỉ bao gồm một năm, chưa đủ để kết luận chắc chắn về xu hướng mùa vụ lặp lại hoặc nguyên nhân biến động doanh thu.

## 5. Tài liệu và mã nguồn đi kèm

Xem `README.md` tại thư mục gốc để biết thứ tự chạy SQL, các tệp Power BI và cách đọc biểu đồ. Mọi số liệu trong tài liệu này được đối chiếu với kết quả SQL và dashboard năm 2015.
