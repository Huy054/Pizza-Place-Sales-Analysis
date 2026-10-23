# Các công thức DAX tiêu biểu

Đây là tài liệu giải thích công thức DAX đã triển khai theo quá trình xây dashboard. Có thể kiểm tra lại nội dung Measure trong file PBIX để xác nhận phiên bản mới nhất.

## KPI chính

```dax
Total Revenue = SUM('vw_PizzaSales_Master_Clean'[revenue])

Total Orders = DISTINCTCOUNT('vw_PizzaSales_Master_Clean'[order_id])

Pizzas Sold = SUM('vw_PizzaSales_Master_Clean'[quantity])

Average Order Value = DIVIDE([Total Revenue], [Total Orders])
```

### Giải thích
- Doanh thu: tổng `revenue` ở các dòng chi tiết đơn hàng.
- Đơn hàng: `DISTINCTCOUNT` để không đếm trùng nhiều dòng trong một đơn.
- Số chiếc: tổng quantity, có thể nhiều hơn số dòng chi tiết.
- AOV: doanh thu trong ngữ cảnh lọc / số đơn duy nhất cùng ngữ cảnh.

## Tô màu giờ cao điểm theo bộ lọc

```dax
Hour Bar Color =
VAR PeakOrders =
    MAXX(
        ALLSELECTED('vw_PizzaSales_Master_Clean'[order_hour]),
        CALCULATE([Total Orders])
    )
RETURN
    IF(
        NOT ISBLANK([Total Orders]) && [Total Orders] = PeakOrders,
        "#F59E0B",
        "#60A5FA"
    )
```

## Tô màu Top 1 pizza theo bộ lọc

```dax
Pizza Bar Color =
VAR MaxRevenue =
    MAXX(
        ALLSELECTED('vw_PizzaSales_Master_Clean'[pizza_name]),
        CALCULATE([Total Revenue])
    )
RETURN
    IF(
        NOT ISBLANK([Total Revenue]) && [Total Revenue] = MaxRevenue,
        "#F59E0B",
        "#60A5FA"
    )
```

## Tô màu kích cỡ có doanh thu cao nhất

```dax
Size Bar Color =
VAR CurrentRevenue = [Total Revenue]
VAR MaxRevenue =
    MAXX(
        ALLSELECTED('vw_PizzaSales_Master_Clean'[size]),
        CALCULATE([Total Revenue])
    )
RETURN
    IF(
        NOT ISBLANK(CurrentRevenue) && CurrentRevenue = MaxRevenue,
        "#F59E0B",
        "#60A5FA"
    )
```

Các Measure tô màu được liên kết tới `fx -> Field value` trong phần thiết lập màu của biểu đồ. Có thể có nhiều thanh cùng màu cam nếu đồng hạng cao nhất.

## Bảng ABC cố định

```dax
Product ABC =
VAR ProductSales =
    SUMMARIZE(
        'vw_PizzaSales_Master_Clean',
        'vw_PizzaSales_Master_Clean'[pizza_name],
        "Revenue", SUM('vw_PizzaSales_Master_Clean'[revenue])
    )
VAR TotalSales = SUMX(ProductSales, [Revenue])
VAR WithCumulative =
    ADDCOLUMNS(
        ProductSales,
        "CumulativePct",
        VAR CurrentRevenue = [Revenue]
        RETURN DIVIDE(
            SUMX(FILTER(ProductSales, [Revenue] >= CurrentRevenue), [Revenue]),
            TotalSales
        )
    )
RETURN
    ADDCOLUMNS(
        WithCumulative,
        "ABC Group", SWITCH(TRUE(), [CumulativePct] <= 0.80, "A", [CumulativePct] <= 0.95, "B", "C"),
        "Overview", "All Products"
    )
```

Quy tắc nhóm: A đến ngưỡng 80%, B đến 95%, C phần còn lại. Bảng này được tính khi mô hình nạp/làm mới dữ liệu, **không tính lại theo slicer**. Để thay đổi động theo bộ lọc cần Measure và thiết kế mô hình khác.
