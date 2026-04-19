CREATE DATABASE newECommerceDB;
GO
USE newECommerceDB;
GO
-- =============================================
-- 1. Independent Tables (Level 1)
-- =============================================

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(255) NOT NULL, 
    CONSTRAINT CHK_FullNameNotEmpty CHECK (LEN(TRIM(FullName)) > 0),
    Email VARCHAR(255) NOT NULL UNIQUE CHECK (Email LIKE '%_@__%.__%'),
    Phone VARCHAR(20) NULL UNIQUE,
    PasswordHash VARCHAR(MAX) NOT NULL, 
    CONSTRAINT CHK_PasswordLength CHECK (LEN(PasswordHash) >= 8),
    RegistrationDate DATETIME DEFAULT GETDATE(), 
    Status VARCHAR(50) DEFAULT 'Active' 
        CHECK (Status IN ('Active', 'Inactive', 'Banned', 'Pending')),
    TotalSpend DECIMAL(10, 2) DEFAULT 0 CHECK (TotalSpend >= 0),
    DateOfBirth DATE NULL,        
    Gender VARCHAR(10) NULL CHECK (Gender IN ('Male','Female','Other')),
    LoyaltyPoints INT DEFAULT 0 CHECK (LoyaltyPoints >= 0),
    LastLogin DATETIME NULL
);

CREATE TABLE Category (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE,
    Description VARCHAR(255) NULL,
    CategoryImage VARCHAR(255) NULL, 
    ParentCategoryID INT NULL, 
    IsActive BIT DEFAULT 1,
    CONSTRAINT CHK_CategoryName CHECK (LEN(TRIM(CategoryName)) >= 3),
    CONSTRAINT CHK_CategoryImageFormat CHECK (CategoryImage IS NULL OR CategoryImage LIKE '%.jpg%' OR CategoryImage LIKE '%.jpeg%' OR CategoryImage LIKE '%.png%' OR CategoryImage LIKE '%.webp%' OR CategoryImage LIKE '%.svg%'),
    CONSTRAINT CHK_NoSelfParent CHECK (ParentCategoryID IS NULL OR ParentCategoryID <> CategoryID),
    CONSTRAINT FK_ParentCategory FOREIGN KEY (ParentCategoryID) REFERENCES Category(CategoryID) ON DELETE NO ACTION
);

CREATE TABLE Promotion (
    PromotionID INT PRIMARY KEY IDENTITY(1,1),
    Code VARCHAR(50) NOT NULL UNIQUE, 
    DiscountValue DECIMAL(10, 2) NOT NULL,
    DiscountType VARCHAR(50) NOT NULL CHECK (DiscountType IN ('Percentage', 'FixedAmount')),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    UsageLimit INT DEFAULT 100 CHECK (UsageLimit >= 0),
    IsActive BIT DEFAULT 1, 
    CONSTRAINT CHK_PromoDates CHECK (EndDate >= StartDate),
    CONSTRAINT CHK_DiscountValue CHECK ((DiscountType = 'Percentage' AND DiscountValue <= 100) OR (DiscountType = 'FixedAmount' AND DiscountValue > 0)),
    CONSTRAINT CHK_UsageActive CHECK (UsageLimit > 0 OR IsActive = 0),
    CONSTRAINT CHK_CodeLength CHECK (LEN(Code) >= 3 AND LEN(Code) <= 50)
);

-- =============================================
-- 2. Tables Dependent on Level 1 (Level 2)
-- =============================================

CREATE TABLE Address (
    AddressID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    AddressLine VARCHAR(255) NOT NULL,
    City VARCHAR(100) NOT NULL,
    State VARCHAR(100) NULL,
    ZipCode VARCHAR(20) NULL,
    Country VARCHAR(100) NOT NULL,
    AddressType VARCHAR(50) NOT NULL CHECK (AddressType IN ('Home', 'Work', 'Billing', 'Shipping')),
    IsDefault BIT DEFAULT 0,
    Notes VARCHAR(255) NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    UpdatedDate DATETIME NULL,
    CONSTRAINT FK_Address_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    CONSTRAINT UQ_CustomerAddress UNIQUE (CustomerID, AddressLine, City, Country),
    CONSTRAINT CHK_AddressLine_Min CHECK (LEN(TRIM(AddressLine)) >= 5),
    CONSTRAINT CHK_City_Min CHECK (LEN(TRIM(City)) >= 2),
    CONSTRAINT CHK_Dates_Logical CHECK (UpdatedDate IS NULL OR UpdatedDate >= CreatedDate),
    Phone VARCHAR(20) NULL
);

CREATE TABLE Cart (
    CartID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(), 
    Status VARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Converted', 'Abandoned')),
    CONSTRAINT FK_Cart_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE
);

CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(255) NOT NULL,
    SKU VARCHAR(50) NOT NULL UNIQUE,
    Description VARCHAR(500),
    OriginalPrice DECIMAL(10,2) NOT NULL CHECK (OriginalPrice > 0),
    SalePrice DECIMAL(10,2) NULL CHECK (SalePrice >= 0),
    IsOnSale BIT DEFAULT 0,
    ReorderLevel INT DEFAULT 5 CHECK (ReorderLevel >= 0),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CategoryID INT NOT NULL,
    BrandID INT NULL,
    CONSTRAINT FK_Product_Category 
    FOREIGN KEY (CategoryID) 
    REFERENCES Category(CategoryID) ON DELETE NO ACTION,
    CONSTRAINT CHK_SalePrice_Logical 
    CHECK (SalePrice IS NULL OR SalePrice <= OriginalPrice),
    CONSTRAINT CHK_ProductName_Length 
    CHECK (LEN(TRIM(ProductName)) >= 3),
    CONSTRAINT CHK_SKU_NoSpaces 
    CHECK (SKU NOT LIKE '% %')
);

CREATE TABLE Brand (
    BrandID INT IDENTITY(1,1) PRIMARY KEY,
    BrandName VARCHAR(100) NOT NULL UNIQUE,
    Country VARCHAR(100) NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);

CREATE TABLE Size (
    SizeID INT IDENTITY(1,1) PRIMARY KEY,
    SizeValue VARCHAR(50) NOT NULL,
    SizeType VARCHAR(50) NOT NULL
);

CREATE TABLE Color (
    ColorID INT IDENTITY(1,1) PRIMARY KEY,
    ColorName VARCHAR(50) NOT NULL UNIQUE,
    HexCode VARCHAR(7) NULL
);

CREATE TABLE ProductVariant (
    VariantID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    SizeID INT NULL,
    ColorID INT NULL,
    VariantSKU VARCHAR(80) NOT NULL UNIQUE,
    Price DECIMAL(10,2) NOT NULL CHECK (Price > 0),
    StockQuantity INT DEFAULT 0 CHECK (StockQuantity >= 0),
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Variant_Product
    FOREIGN KEY (ProductID)
    REFERENCES Product(ProductID)
    ON DELETE CASCADE,
    CONSTRAINT FK_Variant_Size
    FOREIGN KEY (SizeID)
    REFERENCES Size(SizeID),
    CONSTRAINT FK_Variant_Color
    FOREIGN KEY (ColorID)
    REFERENCES Color(ColorID)
);

-- =============================================
-- 3. Tables Dependent on Level 2 (Level 3)
-- =============================================

CREATE TABLE ProductImage (
    ImageID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT NOT NULL,
    ImageURL VARCHAR(255) NOT NULL,
    IsPrimary BIT DEFAULT 0,
    DisplayOrder INT DEFAULT 0 CHECK (DisplayOrder >= 0),
    CONSTRAINT FK_Product_Images FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE CASCADE,
    CONSTRAINT UQ_Product_Image UNIQUE (ProductID, ImageURL),
    CONSTRAINT CHK_ProductImageFormat CHECK (ImageURL LIKE '%.jpg' OR ImageURL LIKE '%.png' OR ImageURL LIKE '%.webp' OR ImageURL LIKE '%.jpeg' OR ImageURL LIKE '%.JPG' OR ImageURL LIKE '%.PNG' OR ImageURL LIKE '%.WEBP' OR ImageURL LIKE '%.JPEG')
);

CREATE TABLE ProductPromotion (
    ProductID INT NOT NULL,
    PromotionID INT NOT NULL,
    AddedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_ProductPromotion PRIMARY KEY (ProductID, PromotionID),
    CONSTRAINT FK_PP_Product FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE CASCADE,
    CONSTRAINT FK_PP_Promotion FOREIGN KEY (PromotionID) REFERENCES Promotion(PromotionID) ON DELETE CASCADE
);

CREATE TABLE CartItem (
    CartItemID INT PRIMARY KEY IDENTITY(1,1),
    CartID INT NOT NULL,
    VariantID INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1 CHECK (Quantity > 0),
    AddedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_Cart_Product UNIQUE (CartID, VariantID),
    CONSTRAINT FK_CartItem_Cart 
    FOREIGN KEY (CartID) 
    REFERENCES Cart(CartID) 
    ON DELETE CASCADE,
    CONSTRAINT FK_CartItem_Variant 
    FOREIGN KEY (VariantID) 
    REFERENCES ProductVariant(VariantID) 
    ON DELETE CASCADE
);

-- =============================================
-- 4. Orders and Transactions (Level 4)
-- =============================================

CREATE TABLE [Order] (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    ShippingAddressID INT NOT NULL,
    CartID INT NULL, 
    OrderDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    OrderStatus VARCHAR(50) DEFAULT 'Pending' CHECK (OrderStatus IN ('Pending','Processing','Shipped','Delivered', 'Cancelled')),
    TotalAmount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (TotalAmount >= 0), 
    PromotionID INT NULL, 
    PointsEarned INT DEFAULT 0 CHECK (PointsEarned >= 0),   
    PointsRedeemed INT DEFAULT 0 CHECK (PointsRedeemed >= 0), 
    FinalAmount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (FinalAmount >= 0),
    CONSTRAINT FK_Order_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    CONSTRAINT FK_Order_Address FOREIGN KEY (ShippingAddressID) REFERENCES Address(AddressID),
    CONSTRAINT FK_Order_Promotion FOREIGN KEY (PromotionID) REFERENCES Promotion(PromotionID),
    CONSTRAINT FK_Order_Cart FOREIGN KEY (CartID) REFERENCES Cart(CartID),
    CONSTRAINT CHK_FinalAmount_Logical CHECK (FinalAmount <= TotalAmount),
    CONSTRAINT CHK_OrderDate_Limit CHECK (OrderDate <= CURRENT_TIMESTAMP)
);

CREATE TABLE OrderItem (
    OrderID INT NOT NULL,
    VariantID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL CHECK (UnitPrice >= 0),
    LineTotal DECIMAL(10,2) NOT NULL CHECK (LineTotal >= 0),
    PromotionID INT NULL,
    DiscountApplied DECIMAL(10,2) DEFAULT 0 CHECK (DiscountApplied >= 0),
    UnitPriceFinal AS (UnitPrice - DiscountApplied) PERSISTED,
    CONSTRAINT CHK_DiscountNotExceedPrice 
    CHECK (DiscountApplied <= UnitPrice),
    PRIMARY KEY (OrderID, VariantID),
    CONSTRAINT FK_OI_Order 
    FOREIGN KEY (OrderID) 
    REFERENCES [Order](OrderID) 
    ON DELETE CASCADE,
    CONSTRAINT FK_OI_Variant 
    FOREIGN KEY (VariantID) 
    REFERENCES ProductVariant(VariantID) 
    ON DELETE NO ACTION,
    CONSTRAINT FK_OI_Promotion 
    FOREIGN KEY (PromotionID) 
    REFERENCES Promotion(PromotionID)
);

-- =============================================
-- 5. Dependent and Post-Operation Tables (Level 5)
-- =============================================

CREATE TABLE OrderStatusHistory (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    OldStatus VARCHAR(50) NULL,
    NewStatus VARCHAR(50) NOT NULL,
    ChangedBy VARCHAR(100) DEFAULT 'System',
    Reason NVARCHAR(255) NULL,
    ChangedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_History_Order FOREIGN KEY (OrderID) REFERENCES [Order](OrderID) ON DELETE CASCADE,
    CONSTRAINT CHK_NewStatus CHECK (NewStatus IN ('Pending','Processing','Shipped','Delivered', 'Cancelled'))
);

CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod VARCHAR(50) NOT NULL CHECK (PaymentMethod IN ('Credit Card', 'Debit Card', 'PayPal', 'Cash on Delivery', 'Wallet')),
    PaymentStatus VARCHAR(50) DEFAULT 'Pending' CHECK (PaymentStatus IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    TransactionReference VARCHAR(100) NOT NULL UNIQUE,
    PaymentDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Payment_Order FOREIGN KEY (OrderID) REFERENCES [Order](OrderID) ON DELETE CASCADE,
    CONSTRAINT CHK_PaymentAmount CHECK (Amount > 0)
);

CREATE TABLE Shipping (
    ShipmentID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    TrackingNumber VARCHAR(100) NOT NULL UNIQUE,
    CourierName VARCHAR(100) NOT NULL,
    ShippingStatus VARCHAR(50) DEFAULT 'Preparing' CHECK (ShippingStatus IN ('Preparing', 'In Transit', 'Out for Delivery', 'Delivered', 'Failed')),
    ShippedDate DATETIME NULL, 
    DeliveredDate DATETIME NULL, 
    DeliveryDuration AS (DATEDIFF(day, ShippedDate, DeliveredDate)) PERSISTED,
    CONSTRAINT FK_Shipping_Order FOREIGN KEY (OrderID) REFERENCES [Order](OrderID) ON DELETE CASCADE,
    CONSTRAINT CHK_Delivery_After_Shipping CHECK (DeliveredDate >= ShippedDate),
    CONSTRAINT CHK_Shipping_Not_Before_Order CHECK (ShippedDate IS NULL OR ShippedDate >= '2024-01-01') 
);

CREATE TABLE [Return] (
    ReturnID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    VariantID INT NOT NULL,
    QuantityReturned INT NOT NULL CHECK (QuantityReturned > 0),
    ReturnReason NVARCHAR(500) NULL,
    ReturnDate DATETIME DEFAULT GETDATE(),
    ReturnStatus VARCHAR(50) DEFAULT 'Pending' 
        CHECK (ReturnStatus IN ('Pending', 'Approved', 'Rejected', 'Completed')),
    CONSTRAINT FK_Return_OrderItem 
    FOREIGN KEY (OrderID, VariantID) 
    REFERENCES OrderItem(OrderID, VariantID) 
    ON DELETE CASCADE
);

CREATE TABLE Refund (
    RefundID INT PRIMARY KEY IDENTITY(1,1),
    ReturnID INT NOT NULL UNIQUE,
    RefundAmount DECIMAL(10,2) NOT NULL CHECK (RefundAmount >= 0),
    RefundDate DATETIME DEFAULT GETDATE(),
    RefundMethod VARCHAR(50) NOT NULL CHECK (RefundMethod IN ('Original Method', 'Store Wallet', 'Bank Transfer')),
    RefundStatus VARCHAR(50) DEFAULT 'Pending' CHECK (RefundStatus IN ('Pending', 'Processed', 'Failed')),
    CONSTRAINT FK_Refund_Return FOREIGN KEY (ReturnID) REFERENCES [Return](ReturnID) ON DELETE CASCADE
);

CREATE TABLE Review (
    ReviewID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    VariantID INT NOT NULL,
    Rating INT NOT NULL 
        CONSTRAINT CHK_Rating_Range CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(MAX) NULL,
    ReviewDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Review_OrderItem 
    FOREIGN KEY (OrderID, VariantID) 
    REFERENCES OrderItem(OrderID, VariantID) 
    ON DELETE CASCADE,
    CONSTRAINT UQ_OrderVariantReview 
    UNIQUE (OrderID, VariantID)
);
CREATE TABLE SupportTicket (
    TicketID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    Priority VARCHAR(20) DEFAULT 'Medium' CHECK (Priority IN ('Low', 'Medium', 'High', 'Urgent')),
    Status VARCHAR(20) DEFAULT 'Open' CHECK (Status IN ('Open', 'In Progress', 'Resolved', 'Closed')),
    CreatedAt DATETIME DEFAULT GETDATE(),
    ClosedAt DATETIME NULL,
    ResolutionHours AS (DATEDIFF(HOUR, CreatedAt, ClosedAt)) PERSISTED,
    SLA_Breached AS (CASE WHEN DATEDIFF(HOUR, CreatedAt, ISNULL(ClosedAt, GETDATE())) > 48 THEN 1 ELSE 0 END),
    CONSTRAINT FK_Ticket_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    CONSTRAINT CHK_DescriptionMinLength CHECK (LEN(TRIM(Description)) >= 10),
    CONSTRAINT CHK_TicketDates CHECK (ClosedAt IS NULL OR ClosedAt >= CreatedAt)
);
CREATE TABLE LoyaltyTransaction (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    OrderID INT NULL, 
    PointsChange INT NOT NULL, 
    TransactionType VARCHAR(20) NOT NULL 
        CHECK (TransactionType IN ('Earned', 'Redeemed', 'Expired')),
    TransactionDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    Description VARCHAR(255) NULL,
    CONSTRAINT FK_Loyalty_Customer FOREIGN KEY (CustomerID) 
        REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    CONSTRAINT FK_Loyalty_Order FOREIGN KEY (OrderID) 
        REFERENCES [Order](OrderID) ON DELETE NO ACTION 
);
-- =============================================
-- 6. Triggers
-- =============================================

CREATE TRIGGER trg_ValidateReturnDelivery
ON [Return]
FOR INSERT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM Shipping s
        JOIN inserted i ON s.OrderID = i.OrderID
        WHERE s.ShippingStatus = 'Delivered'
    )
    BEGIN
        RAISERROR ('Cannot process a return for an order that has not been marked as Delivered in the shipping system!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
-- =============================================
-- 7. Trigger: Reverse Loyalty Points on Order Cancellation
-- =============================================
CREATE TRIGGER trg_ReverseLoyaltyOnCancel
ON [Order]
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.OrderID = d.OrderID
        WHERE i.OrderStatus = 'Cancelled'
        AND d.OrderStatus <> 'Cancelled'
    )
    BEGIN
        INSERT INTO LoyaltyTransaction (CustomerID, OrderID, PointsChange, TransactionType, Description)
        SELECT
            i.CustomerID,
            i.OrderID,
            -lt.PointsChange,
            'Redeemed',
            'Reversal due to order cancellation'
        FROM inserted i
        JOIN LoyaltyTransaction lt ON lt.OrderID = i.OrderID
        WHERE lt.TransactionType = 'Earned';
    END
END;
GO
CREATE DATABASE ECommerceDB;
GO
USE ECommerceDB;
GO
-- =============================================
-- 1. Independent Tables (Level 1)
-- =============================================

CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(255) NOT NULL, 
    CONSTRAINT CHK_FullNameNotEmpty CHECK (LEN(TRIM(FullName)) > 0),
    Email VARCHAR(255) NOT NULL UNIQUE CHECK (Email LIKE '%_@__%.__%'),
    Phone VARCHAR(20) NULL UNIQUE,
    PasswordHash VARCHAR(MAX) NOT NULL, 
    CONSTRAINT CHK_PasswordLength CHECK (LEN(PasswordHash) >= 8),
    RegistrationDate DATETIME DEFAULT GETDATE(), 
    Status VARCHAR(50) DEFAULT 'Active' 
        CHECK (Status IN ('Active', 'Inactive', 'Banned', 'Pending')),
    TotalSpend DECIMAL(10, 2) DEFAULT 0 CHECK (TotalSpend >= 0),
    DateOfBirth DATE NULL,        
    Gender VARCHAR(10) NULL CHECK (Gender IN ('Male','Female','Other')),
    LoyaltyPoints INT DEFAULT 0 CHECK (LoyaltyPoints >= 0),
    LastLogin DATETIME NULL
);
CREATE TABLE Category (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE,
    Description VARCHAR(255) NULL,
    CategoryImage VARCHAR(255) NULL, 
    ParentCategoryID INT NULL, 
    IsActive BIT DEFAULT 1,
    CONSTRAINT CHK_CategoryName CHECK (LEN(TRIM(CategoryName)) >= 3),
    CONSTRAINT CHK_CategoryImageFormat CHECK (CategoryImage IS NULL OR CategoryImage LIKE '%.jpg%' OR CategoryImage LIKE '%.jpeg%' OR CategoryImage LIKE '%.png%' OR CategoryImage LIKE '%.webp%' OR CategoryImage LIKE '%.svg%'),
    CONSTRAINT CHK_NoSelfParent CHECK (ParentCategoryID IS NULL OR ParentCategoryID <> CategoryID),
    CONSTRAINT FK_ParentCategory FOREIGN KEY (ParentCategoryID) REFERENCES Category(CategoryID) ON DELETE NO ACTION
);
CREATE TABLE Promotion (
    PromotionID INT PRIMARY KEY IDENTITY(1,1),
    Code VARCHAR(50) NOT NULL UNIQUE, 
    DiscountValue DECIMAL(10, 2) NOT NULL,
    DiscountType VARCHAR(50) NOT NULL CHECK (DiscountType IN ('Percentage', 'FixedAmount')),
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    UsageLimit INT DEFAULT 100 CHECK (UsageLimit >= 0),
    IsActive BIT DEFAULT 1, 
    CONSTRAINT CHK_PromoDates CHECK (EndDate >= StartDate),
    CONSTRAINT CHK_DiscountValue CHECK ((DiscountType = 'Percentage' AND DiscountValue <= 100) OR (DiscountType = 'FixedAmount' AND DiscountValue > 0)),
    CONSTRAINT CHK_UsageActive CHECK (UsageLimit > 0 OR IsActive = 0),
    CONSTRAINT CHK_CodeLength CHECK (LEN(Code) >= 3 AND LEN(Code) <= 50)
);
-- =============================================
-- 2. Tables Dependent on Level 1 (Level 2)
-- =============================================

CREATE TABLE Address (
    AddressID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    AddressLine VARCHAR(255) NOT NULL,
    City VARCHAR(100) NOT NULL,
    State VARCHAR(100) NULL,
    ZipCode VARCHAR(20) NULL,
    Country VARCHAR(100) NOT NULL,
    AddressType VARCHAR(50) NOT NULL CHECK (AddressType IN ('Home', 'Work', 'Billing', 'Shipping')),
    IsDefault BIT DEFAULT 0,
    Notes VARCHAR(255) NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    UpdatedDate DATETIME NULL,
    CONSTRAINT FK_Address_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    CONSTRAINT UQ_CustomerAddress UNIQUE (CustomerID, AddressLine, City, Country),
    CONSTRAINT CHK_AddressLine_Min CHECK (LEN(TRIM(AddressLine)) >= 5),
    CONSTRAINT CHK_City_Min CHECK (LEN(TRIM(City)) >= 2),
    CONSTRAINT CHK_Dates_Logical CHECK (UpdatedDate IS NULL OR UpdatedDate >= CreatedDate),
    Phone VARCHAR(20) NULL
);
CREATE TABLE Cart (
    CartID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(), 
    Status VARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Converted', 'Abandoned')),
    CONSTRAINT FK_Cart_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE
);
CREATE TABLE Product (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(255) NOT NULL,
    SKU VARCHAR(50) NOT NULL UNIQUE,
    Description VARCHAR(500),
    OriginalPrice DECIMAL(10,2) NOT NULL CHECK (OriginalPrice > 0),
    SalePrice DECIMAL(10,2) NULL CHECK (SalePrice >= 0),
    IsOnSale BIT DEFAULT 0,
    ReorderLevel INT DEFAULT 5 CHECK (ReorderLevel >= 0),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CategoryID INT NOT NULL,
    BrandID INT NULL,
    CONSTRAINT FK_Product_Category 
    FOREIGN KEY (CategoryID) 
    REFERENCES Category(CategoryID) ON DELETE NO ACTION,
    CONSTRAINT CHK_SalePrice_Logical 
    CHECK (SalePrice IS NULL OR SalePrice <= OriginalPrice),
    CONSTRAINT CHK_ProductName_Length 
    CHECK (LEN(TRIM(ProductName)) >= 3),
    CONSTRAINT CHK_SKU_NoSpaces 
    CHECK (SKU NOT LIKE '% %')
);
CREATE TABLE Brand (
    BrandID INT IDENTITY(1,1) PRIMARY KEY,
    BrandName VARCHAR(100) NOT NULL UNIQUE,
    Country VARCHAR(100) NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);

CREATE TABLE Size (
    SizeID INT IDENTITY(1,1) PRIMARY KEY,
    SizeValue VARCHAR(50) NOT NULL,
    SizeType VARCHAR(50) NOT NULL
);

CREATE TABLE Color (
    ColorID INT IDENTITY(1,1) PRIMARY KEY,
    ColorName VARCHAR(50) NOT NULL UNIQUE,
    HexCode VARCHAR(7) NULL
);
CREATE TABLE ProductVariant (
    VariantID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    SizeID INT NULL,
    ColorID INT NULL,
    VariantSKU VARCHAR(80) NOT NULL UNIQUE,
    Price DECIMAL(10,2) NOT NULL CHECK (Price > 0),
    StockQuantity INT DEFAULT 0 CHECK (StockQuantity >= 0),
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Variant_Product
    FOREIGN KEY (ProductID)
    REFERENCES Product(ProductID)
    ON DELETE CASCADE,
    CONSTRAINT FK_Variant_Size
    FOREIGN KEY (SizeID)
    REFERENCES Size(SizeID),
    CONSTRAINT FK_Variant_Color
    FOREIGN KEY (ColorID)
    REFERENCES Color(ColorID)
);

-- =============================================
-- 3. Tables Dependent on Level 2 (Level 3)
-- =============================================

CREATE TABLE ProductImage (
    ImageID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT NOT NULL,
    ImageURL VARCHAR(255) NOT NULL,
    IsPrimary BIT DEFAULT 0,
    DisplayOrder INT DEFAULT 0 CHECK (DisplayOrder >= 0),
    CONSTRAINT FK_Product_Images FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE CASCADE,
    CONSTRAINT UQ_Product_Image UNIQUE (ProductID, ImageURL),
    CONSTRAINT CHK_ProductImageFormat CHECK (ImageURL LIKE '%.jpg' OR ImageURL LIKE '%.png' OR ImageURL LIKE '%.webp' OR ImageURL LIKE '%.jpeg' OR ImageURL LIKE '%.JPG' OR ImageURL LIKE '%.PNG' OR ImageURL LIKE '%.WEBP' OR ImageURL LIKE '%.JPEG')
);

CREATE TABLE ProductPromotion (
    ProductID INT NOT NULL,
    PromotionID INT NOT NULL,
    AddedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_ProductPromotion PRIMARY KEY (ProductID, PromotionID),
    CONSTRAINT FK_PP_Product FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE CASCADE,
    CONSTRAINT FK_PP_Promotion FOREIGN KEY (PromotionID) REFERENCES Promotion(PromotionID) ON DELETE CASCADE
);

CREATE TABLE CartItem (
    CartItemID INT PRIMARY KEY IDENTITY(1,1),
    CartID INT NOT NULL,
    VariantID INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 1 CHECK (Quantity > 0),
    AddedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT UQ_Cart_Product UNIQUE (CartID, VariantID),
    CONSTRAINT FK_CartItem_Cart 
    FOREIGN KEY (CartID) 
    REFERENCES Cart(CartID) 
    ON DELETE CASCADE,
    CONSTRAINT FK_CartItem_Variant 
    FOREIGN KEY (VariantID) 
    REFERENCES ProductVariant(VariantID) 
    ON DELETE CASCADE
);

-- =============================================
-- 4. Orders and Transactions (Level 4)
-- =============================================

CREATE TABLE [Order] (
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    ShippingAddressID INT NOT NULL,
    CartID INT NULL, 
    OrderDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    OrderStatus VARCHAR(50) DEFAULT 'Pending' CHECK (OrderStatus IN ('Pending','Processing','Shipped','Delivered', 'Cancelled')),
    TotalAmount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (TotalAmount >= 0), 
    PromotionID INT NULL, 
    PointsEarned INT DEFAULT 0 CHECK (PointsEarned >= 0),   
    PointsRedeemed INT DEFAULT 0 CHECK (PointsRedeemed >= 0), 
    FinalAmount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (FinalAmount >= 0),
    CONSTRAINT FK_Order_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    CONSTRAINT FK_Order_Address FOREIGN KEY (ShippingAddressID) REFERENCES Address(AddressID),
    CONSTRAINT FK_Order_Promotion FOREIGN KEY (PromotionID) REFERENCES Promotion(PromotionID),
    CONSTRAINT FK_Order_Cart FOREIGN KEY (CartID) REFERENCES Cart(CartID),
    CONSTRAINT CHK_FinalAmount_Logical CHECK (FinalAmount <= TotalAmount),
    CONSTRAINT CHK_OrderDate_Limit CHECK (OrderDate <= CURRENT_TIMESTAMP)
);

CREATE TABLE OrderItem (
    OrderID INT NOT NULL,
    VariantID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL CHECK (UnitPrice >= 0),
    LineTotal DECIMAL(10,2) NOT NULL CHECK (LineTotal >= 0),
    PromotionID INT NULL,
    DiscountApplied DECIMAL(10,2) DEFAULT 0 CHECK (DiscountApplied >= 0),
    UnitPriceFinal AS (UnitPrice - DiscountApplied) PERSISTED,
    CONSTRAINT CHK_DiscountNotExceedPrice 
    CHECK (DiscountApplied <= UnitPrice),
    PRIMARY KEY (OrderID, VariantID),
    CONSTRAINT FK_OI_Order 
    FOREIGN KEY (OrderID) 
    REFERENCES [Order](OrderID) 
    ON DELETE CASCADE,
    CONSTRAINT FK_OI_Variant 
    FOREIGN KEY (VariantID) 
    REFERENCES ProductVariant(VariantID) 
    ON DELETE NO ACTION,
    CONSTRAINT FK_OI_Promotion 
    FOREIGN KEY (PromotionID) 
    REFERENCES Promotion(PromotionID)
);

-- =============================================
-- 5. Dependent and Post-Operation Tables (Level 5)
-- =============================================

CREATE TABLE OrderStatusHistory (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    OldStatus VARCHAR(50) NULL,
    NewStatus VARCHAR(50) NOT NULL,
    ChangedBy VARCHAR(100) DEFAULT 'System',
    Reason NVARCHAR(255) NULL,
    ChangedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_History_Order FOREIGN KEY (OrderID) REFERENCES [Order](OrderID) ON DELETE CASCADE,
    CONSTRAINT CHK_NewStatus CHECK (NewStatus IN ('Pending','Processing','Shipped','Delivered', 'Cancelled'))
);

CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod VARCHAR(50) NOT NULL CHECK (PaymentMethod IN ('Credit Card', 'Debit Card', 'PayPal', 'Cash on Delivery', 'Wallet')),
    PaymentStatus VARCHAR(50) DEFAULT 'Pending' CHECK (PaymentStatus IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    TransactionReference VARCHAR(100) NOT NULL UNIQUE,
    PaymentDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Payment_Order FOREIGN KEY (OrderID) REFERENCES [Order](OrderID) ON DELETE CASCADE,
    CONSTRAINT CHK_PaymentAmount CHECK (Amount > 0)
);

CREATE TABLE Shipping (
    ShipmentID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    TrackingNumber VARCHAR(100) NOT NULL UNIQUE,
    CourierName VARCHAR(100) NOT NULL,
    ShippingStatus VARCHAR(50) DEFAULT 'Preparing' CHECK (ShippingStatus IN ('Preparing', 'In Transit', 'Out for Delivery', 'Delivered', 'Failed')),
    ShippedDate DATETIME NULL, 
    DeliveredDate DATETIME NULL, 
    DeliveryDuration AS (DATEDIFF(day, ShippedDate, DeliveredDate)) PERSISTED,
    CONSTRAINT FK_Shipping_Order FOREIGN KEY (OrderID) REFERENCES [Order](OrderID) ON DELETE CASCADE,
    CONSTRAINT CHK_Delivery_After_Shipping CHECK (DeliveredDate >= ShippedDate),
    CONSTRAINT CHK_Shipping_Not_Before_Order CHECK (ShippedDate IS NULL OR ShippedDate >= '2024-01-01') 
);

CREATE TABLE [Return] (
    ReturnID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    VariantID INT NOT NULL,
    QuantityReturned INT NOT NULL CHECK (QuantityReturned > 0),
    ReturnReason NVARCHAR(500) NULL,
    ReturnDate DATETIME DEFAULT GETDATE(),
    ReturnStatus VARCHAR(50) DEFAULT 'Pending' 
        CHECK (ReturnStatus IN ('Pending', 'Approved', 'Rejected', 'Completed')),
    CONSTRAINT FK_Return_OrderItem 
    FOREIGN KEY (OrderID, VariantID) 
    REFERENCES OrderItem(OrderID, VariantID) 
    ON DELETE CASCADE
);

CREATE TABLE Refund (
    RefundID INT PRIMARY KEY IDENTITY(1,1),
    ReturnID INT NOT NULL UNIQUE,
    RefundAmount DECIMAL(10,2) NOT NULL CHECK (RefundAmount >= 0),
    RefundDate DATETIME DEFAULT GETDATE(),
    RefundMethod VARCHAR(50) NOT NULL CHECK (RefundMethod IN ('Original Method', 'Store Wallet', 'Bank Transfer')),
    RefundStatus VARCHAR(50) DEFAULT 'Pending' CHECK (RefundStatus IN ('Pending', 'Processed', 'Failed')),
    CONSTRAINT FK_Refund_Return FOREIGN KEY (ReturnID) REFERENCES [Return](ReturnID) ON DELETE CASCADE
);

CREATE TABLE Review (
    ReviewID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    VariantID INT NOT NULL,
    Rating INT NOT NULL 
        CONSTRAINT CHK_Rating_Range CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(MAX) NULL,
    ReviewDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Review_OrderItem 
    FOREIGN KEY (OrderID, VariantID) 
    REFERENCES OrderItem(OrderID, VariantID) 
    ON DELETE CASCADE,
    CONSTRAINT UQ_OrderVariantReview 
    UNIQUE (OrderID, VariantID)
);

CREATE TABLE SupportTicket (
    TicketID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    Priority VARCHAR(20) DEFAULT 'Medium' CHECK (Priority IN ('Low', 'Medium', 'High', 'Urgent')),
    Status VARCHAR(20) DEFAULT 'Open' CHECK (Status IN ('Open', 'In Progress', 'Resolved', 'Closed')),
    CreatedAt DATETIME DEFAULT GETDATE(),
    ClosedAt DATETIME NULL,
    ResolutionHours AS (DATEDIFF(HOUR, CreatedAt, ClosedAt)) PERSISTED,
    SLA_Breached AS (CASE WHEN DATEDIFF(HOUR, CreatedAt, ISNULL(ClosedAt, GETDATE())) > 48 THEN 1 ELSE 0 END),
    CONSTRAINT FK_Ticket_Customer FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    CONSTRAINT CHK_DescriptionMinLength CHECK (LEN(TRIM(Description)) >= 10),
    CONSTRAINT CHK_TicketDates CHECK (ClosedAt IS NULL OR ClosedAt >= CreatedAt)
);

CREATE TABLE LoyaltyTransaction (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    OrderID INT NULL, 
    PointsChange INT NOT NULL, 
    TransactionType VARCHAR(20) NOT NULL 
        CHECK (TransactionType IN ('Earned', 'Redeemed', 'Expired')),
    TransactionDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    Description VARCHAR(255) NULL,
    CONSTRAINT FK_Loyalty_Customer FOREIGN KEY (CustomerID) 
        REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    CONSTRAINT FK_Loyalty_Order FOREIGN KEY (OrderID) 
        REFERENCES [Order](OrderID) ON DELETE NO ACTION 
);

GO

-- =============================================
-- 6. Triggers
-- =============================================

CREATE TRIGGER trg_ValidateReturnDelivery
ON [Return]
FOR INSERT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM Shipping s
        JOIN inserted i ON s.OrderID = i.OrderID
        WHERE s.ShippingStatus = 'Delivered'
    )
    BEGIN
        RAISERROR ('Cannot process a return for an order that has not been marked as Delivered in the shipping system!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- =============================================
-- 7. Trigger: Reverse Loyalty Points on Order Cancellation
-- =============================================
CREATE TRIGGER trg_ReverseLoyaltyOnCancel
ON [Order]
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.OrderID = d.OrderID
        WHERE i.OrderStatus = 'Cancelled'
        AND d.OrderStatus <> 'Cancelled'
    )
    BEGIN
        INSERT INTO LoyaltyTransaction (CustomerID, OrderID, PointsChange, TransactionType, Description)
        SELECT
            i.CustomerID,
            i.OrderID,
            -lt.PointsChange,
            'Redeemed',
            'Reversal due to order cancellation'
        FROM inserted i
        JOIN LoyaltyTransaction lt ON lt.OrderID = i.OrderID
        WHERE lt.TransactionType = 'Earned';
    END
END;
GO

-- 1. vw_CustomerMaster
-- Objective: Displays customers with total orders and total completed payments amount.
DROP VIEW IF EXISTS vw_CustomerMaster;
GO

CREATE VIEW vw_CustomerMaster AS
SELECT
    c.CustomerID,
    c.FullName,
    c.Email,
    c.Phone,
    COUNT(o.OrderID)            AS TotalOrders,
    ISNULL(SUM(p.Amount), 0)    AS TotalSpend
FROM Customer c
LEFT JOIN [Order] o ON c.CustomerID = o.CustomerID
LEFT JOIN Payment p ON o.OrderID = p.OrderID AND p.PaymentStatus = 'Completed'
GROUP BY
    c.CustomerID,
    c.FullName,
    c.Email,
    c.Phone;
GO

SELECT TOP 20 * FROM vw_CustomerMaster ORDER BY TotalSpend DESC;
GO

SELECT TOP 20 * FROM vw_CustomerMaster ORDER BY TotalSpend DESC;
GO

-- 2. vw_ProductCatalog
-- Objective: Shows products with current price, total stock quantity, and stock status.
DROP VIEW IF EXISTS vw_ProductCatalog;
GO

CREATE VIEW vw_ProductCatalog AS
SELECT 
    p.ProductID,
    p.SKU,
    p.ProductName,
    c.CategoryName,
    CASE 
        WHEN p.IsOnSale = 1 AND p.SalePrice IS NOT NULL THEN p.SalePrice
        ELSE p.OriginalPrice
    END AS Price,
    ISNULL(SUM(pv.StockQuantity), 0) AS StockQuantity,
    CASE 
        WHEN ISNULL(SUM(pv.StockQuantity), 0) = 0              THEN 'Out of Stock'
        WHEN ISNULL(SUM(pv.StockQuantity), 0) <= p.ReorderLevel THEN 'Low Stock'
        ELSE                                                         'In Stock'
    END AS StockStatus
FROM Product p
JOIN Category c ON p.CategoryID = c.CategoryID
LEFT JOIN ProductVariant pv ON p.ProductID = pv.ProductID
WHERE p.IsActive = 1
GROUP BY 
    p.ProductID, p.SKU, p.ProductName, c.CategoryName, 
    p.IsOnSale, p.SalePrice, p.OriginalPrice, p.ReorderLevel;
GO

-- 3. Daily Sales Analysis
-- Objective: Analyzes daily sales performance including orders, revenue, and items sold.
SELECT 
    CAST(o.OrderDate AS DATE)       AS SaleDate,
    COUNT(DISTINCT o.OrderID)       AS OrdersCount,
    SUM(o.FinalAmount)              AS TotalRevenue,
    AVG(o.FinalAmount)              AS AverageOrderValue,
    SUM(oi.Quantity)                AS ItemsSold
FROM [Order] o
JOIN OrderItem oi ON o.OrderID = oi.OrderID
WHERE o.OrderStatus != 'Cancelled'
GROUP BY CAST(o.OrderDate AS DATE)
ORDER BY SaleDate ASC;
GO

-- 4. vw_OrderDetails
-- Objective: Displays detailed order info including customer, product, payment, and shipment status.
DROP VIEW IF EXISTS vw_OrderDetails;
GO

CREATE VIEW vw_OrderDetails AS
SELECT 
    o.OrderID,
    CAST(o.OrderDate AS DATE) AS OrderDate,
    c.FullName AS CustomerName,
    p.ProductName,
    oi.Quantity,
    oi.UnitPrice,
    oi.LineTotal,
    ISNULL(pay.PaymentStatus, 'Pending') AS PaymentStatus, 
    ISNULL(s.ShippingStatus, 'Processing') AS ShipmentStatus
FROM [Order] o
JOIN Customer c ON o.CustomerID = c.CustomerID 
JOIN OrderItem oi ON o.OrderID = oi.OrderID 
JOIN ProductVariant pv ON oi.VariantID = pv.VariantID 
JOIN Product p ON pv.ProductID = p.ProductID 
LEFT JOIN Payment pay ON o.OrderID = pay.OrderID 
LEFT JOIN Shipping s ON o.OrderID = s.OrderID;

GO

-- 5. Cart Conversion Rate (Monthly)
-- Objective: Calculates monthly cart-to-order conversion rate.
SELECT 
    FORMAT(c.CreatedAt, 'yyyy-MM')              AS MonthYear,
    COUNT(DISTINCT c.CartID)                    AS TotalCarts,
    COUNT(DISTINCT o.CartID)                    AS ConvertedCarts,
    ROUND(COUNT(DISTINCT o.CartID) * 100.0 / NULLIF(COUNT(DISTINCT c.CartID), 0), 2) AS ConversionRate
FROM Cart c
LEFT JOIN [Order] o ON c.CartID = o.CartID
GROUP BY FORMAT(c.CreatedAt, 'yyyy-MM')
ORDER BY MonthYear ASC;
GO

-- 6. Top 3 Products per Category
-- Objective: Identifies the top 3 best-selling products in each category based on revenue.
WITH ProductSales AS (
    SELECT 
        c.CategoryName,
        p.ProductName,
        SUM(oi.Quantity) AS TotalQuantitySold,
        SUM(oi.LineTotal) AS TotalRevenue,
        DENSE_RANK() OVER (PARTITION BY c.CategoryName ORDER BY SUM(oi.LineTotal) DESC) AS SalesRank
    FROM OrderItem oi
    JOIN ProductVariant pv ON oi.VariantID = pv.VariantID
    JOIN Product p ON pv.ProductID = p.ProductID
    JOIN Category c ON p.CategoryID = c.CategoryID
    GROUP BY c.CategoryName, p.ProductName
)
SELECT * FROM ProductSales WHERE SalesRank <= 3 ORDER BY CategoryName, SalesRank;
GO

-- 7. Payment Method Analysis
-- Objective: Analyzes payment methods by transaction volume, revenue, and failure rates.
SELECT 
    PaymentMethod,
    COUNT(PaymentID) AS TotalTransactions,
    SUM(CASE WHEN PaymentStatus = 'Completed' THEN Amount ELSE 0 END) AS TotalPaid,
    SUM(CASE WHEN PaymentStatus = 'Failed' THEN 1 ELSE 0 END) AS FailedPayments,
    SUM(CASE WHEN PaymentStatus = 'Refunded' THEN 1 ELSE 0 END) AS RefundedPayments
FROM Payment
GROUP BY PaymentMethod
ORDER BY TotalPaid DESC;
GO

-- 8. Outstanding Payments
-- Objective: Identifies delivered orders that have not been fully paid.
SELECT 
    o.OrderID,
    c.FullName AS CustomerName,
    o.FinalAmount AS OrderAmount,
    ISNULL(p.Amount, 0) AS AmountPaid,
    o.FinalAmount - ISNULL(p.Amount, 0) AS OutstandingAmount
FROM [Order] o
JOIN Customer c ON o.CustomerID = c.CustomerID
LEFT JOIN Payment p ON o.OrderID = p.OrderID AND p.PaymentStatus = 'Completed'
WHERE o.OrderStatus = 'Delivered' AND (p.PaymentStatus != 'Completed' OR p.PaymentStatus IS NULL)
ORDER BY OutstandingAmount DESC;
GO

-- 9. vw_SupportSLA
-- Objective: Monitors support ticket SLA compliance based on priority.
IF OBJECT_ID('vw_SupportSLA', 'V') IS NOT NULL DROP VIEW vw_SupportSLA;
GO

CREATE VIEW vw_SupportSLA AS
SELECT 
    st.TicketID,
    c.FullName AS CustomerName,
    st.CreatedAt,
    st.ClosedAt,
    st.Priority,
    ROUND(DATEDIFF(MINUTE, st.CreatedAt, ISNULL(st.ClosedAt, GETDATE())) / 60.0, 2) AS ResolutionHours,
    CASE 
        WHEN st.Priority = 'High' AND DATEDIFF(HOUR, st.CreatedAt, ISNULL(st.ClosedAt, GETDATE())) > 24 THEN 'Yes'
        WHEN st.Priority = 'Medium' AND DATEDIFF(HOUR, st.CreatedAt, ISNULL(st.ClosedAt, GETDATE())) > 48 THEN 'Yes'
        WHEN st.Priority = 'Low' AND DATEDIFF(HOUR, st.CreatedAt, ISNULL(st.ClosedAt, GETDATE())) > 72 THEN 'Yes'
        ELSE 'No'
    END AS SLA_Breached
FROM SupportTicket st
JOIN Customer c ON st.CustomerID = c.CustomerID;
GO