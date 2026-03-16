create database Pizza_Sales_DB
go
use Pizza_Sales_DB

-- 1.Total Revenue
select 
    round(sum(od.quantity * p.price), 2) as Total_Revenue
from 
    order_details od
join 
    pizzas p on od.pizza_id = p.pizza_id;


-- 2. Total Orders
select 
    count(distinct order_id) as Total_Orders
from 
    orders;


-- 3. Khung giờ nào bán chạy nhất? (Busiest Hours)
select 
    datepart(hour, time) as Order_Hour,
    count(order_id) as Total_Orders
from 
    orders
group by 
    datepart(hour, time)
order by 
    Total_Orders desc;


-- 4. Top 5 Best Sellers
select top 5
    pt.name as Pizza_Name,
    round(sum(od.quantity * p.price), 2) as Revenue
from 
    order_details od
join 
    pizzas p on od.pizza_id = p.pizza_id
join 
    pizza_types pt on p.pizza_type_id = pt.pizza_type_id
group by 
    pt.name
order by 
    Revenue desc;


-- 5. Tạo View gộp 4 bảng thành một bảng  duy nhất
create view vw_PizzaSales_Master as
select 
    o.order_id,
    o.date,
    o.time,
    od.pizza_id,
    od.quantity,
    p.price,
    (od.quantity * p.price) as Total_Value,
    p.size,
    pt.name,
    pt.category
from 
    orders o
join 
    order_details od on o.order_id = od.order_id
join 
    pizzas p on od.pizza_id = p.pizza_id
join 
    pizza_types pt on p.pizza_type_id = pt.pizza_type_id;