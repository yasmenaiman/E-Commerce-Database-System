# E-Commerce-Database-System
Full e-commerce database system built with SQL Server covering order lifecycle, payments, shipping, and customer support — with triggers, views, and business-driven solutions.
# 🛒 E-Commerce Database System

## 🔍 About the Project
A fully structured relational database designed for an E-Commerce platform,
built with **Microsoft SQL Server**.
The database covers the complete order lifecycle, customer management,
product catalog, payments, shipping, and customer support.

## 🗄️ Database Structure

### 📌 Level 1 – Independent Tables
- **Customer** – stores customer info, loyalty points, and account status
- **Category** – product categories with parent/child hierarchy
- **Promotion** – discount codes with percentage or fixed amount types

### 📌 Level 2 – Dependent Tables
- **Address** – customer shipping and billing addresses
- **Cart** – shopping cart per customer
- **Product** – product catalog with pricing and sale flags
- **Brand** – product brands
- **Size / Color** – product attributes
- **ProductVariant** – product variants combining size, color, and stock

### 📌 Level 3 – Junction & Media Tables
- **ProductImage** – product images per listing
- **ProductPromotion** – links promotions to products
- **CartItem** – items added to each cart

### 📌 Level 4 – Orders & Transactions
- **Order** – customer orders with loyalty points and promotions
- **OrderItem** – individual items per order
- **Payment** – payment records and methods
- **Shipping** – shipment tracking and status
- **Review** – product reviews and ratings
- **SupportTicket** – customer support tickets
- **LoyaltyTransaction** – loyalty points history

## ⚙️ Key Features
- **Constraints & Validations** – email format, price logic, date checks
- **Triggers** – auto-update loyalty points, reverse points on cancellation
- **Views** – pre-built analytical views for reporting
- **Advanced Queries** – sales analysis, cart conversion, top products

## 📊 Views & Queries Included

| Name | Description |
|---|---|
| `vw_CustomerMaster` | Customers with total orders and spend |
| `vw_ProductCatalog` | Products with stock status |
| `vw_OrderDetails` | Full order info with payment and shipment |
| `vw_SupportSLA` | Support ticket SLA compliance |
| Daily Sales Analysis | Orders, revenue, and items sold per day |
| Cart Conversion Rate | Monthly cart-to-order conversion % |
| Top 3 Products per Category | Best sellers by revenue per category |
| Payment Method Analysis | Transaction volume and failure rates |
| Outstanding Payments | Delivered orders with pending payments |

## 🛠️ Tools Used
- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- T-SQL (Transact-SQL)

## 📂 Files
ECommerce-Database/
│── Ecommerce_Project.sql
│── index.html
│── README.md

## 🔧 Business Problems Solved

### 1. 🔄 Loyalty Points Not Reversed on Cancellation
**Problem:** When an order was cancelled, loyalty points earned were never
reversed — causing customers to exploit cancellations to collect free points.

**Solution:** A trigger `trg_ReverseLoyaltyOnCancel` was created to
automatically reverse earned points when an order status changes to Cancelled.

---

### 2. ⚠️ Missing Critical Data Validations
**Problem:** No validation on key fields — invalid emails, negative prices,
and expired promotions were being saved to the database causing dirty data.

**Solution:** Added strict constraints including email format check,
price logic (SalePrice must be ≤ OriginalPrice), promotion date validation
(EndDate ≥ StartDate), and password minimum length enforcement.

---

### 3. 🐌 Heavy Database Due to Storing Images Directly
**Problem:** Storing product images as binary data inside the database
made it extremely slow and increased storage costs significantly.

**Solution:** Switched to storing image URLs (VARCHAR) instead of raw images,
keeping only the file path in the database while images are hosted externally.
Added format validation to ensure only accepted formats (jpg, png, webp) are stored.

---

### 4. 💳 No Tracking for Outstanding Payments
**Problem:** Orders marked as Delivered had no way to flag unpaid or
partially paid transactions, leading to revenue loss.

**Solution:** Built a dedicated query to detect delivered orders
with missing or incomplete payments, enabling the finance team
to follow up on outstanding amounts.

---

### 5. 📦 No Visibility on Cart Abandonment
**Problem:** The business had no insight into how many carts
were created vs actually converted to orders.

**Solution:** Implemented a monthly Cart Conversion Rate query
to track abandoned vs converted carts, helping the marketing
team identify drop-off patterns.

