
-- ========================================
-- E-COMMERCE STORE DATABASE MANAGEMENT SYSTEM
-- ========================================
-- This database supports a complete e-commerce platform with:
-- User management, product catalog, shopping cart, orders, payments, and shipping

-- Create Database
CREATE DATABASE IF NOT EXISTS ecommerce_store;
USE ecommerce_store;

-- ========================================
-- USER MANAGEMENT TABLES
-- ========================================

-- Users table (customers and admins)
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender ENUM('Male', 'Female', 'Other'),
    user_type ENUM('Customer', 'Admin') DEFAULT 'Customer',
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_phone_format CHECK (phone REGEXP '^[+]?[0-9]{10,15}$'),
    CONSTRAINT chk_email_format CHECK (email REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
);

-- User addresses (One-to-Many: User can have multiple addresses)
CREATE TABLE user_addresses (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    address_type ENUM('Home', 'Work', 'Other') DEFAULT 'Home',
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'United States',
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ========================================
-- PRODUCT CATALOG TABLES
-- ========================================

-- Product categories
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_category_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- Brands
CREATE TABLE brands (
    brand_id INT AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    logo_url VARCHAR(255),
    website VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id INT NOT NULL,
    brand_id INT,
    sku VARCHAR(100) NOT NULL UNIQUE,
    price DECIMAL(10, 2) NOT NULL,
    cost_price DECIMAL(10, 2),
    weight DECIMAL(8, 2),
    dimensions VARCHAR(100),
    color VARCHAR(50),
    size VARCHAR(50),
    stock_quantity INT NOT NULL DEFAULT 0,
    min_stock_level INT DEFAULT 10,
    is_active BOOLEAN DEFAULT TRUE,
    featured BOOLEAN DEFAULT FALSE,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    total_reviews INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id) ON DELETE SET NULL,
    
    CONSTRAINT chk_price_positive CHECK (price > 0),
    CONSTRAINT chk_stock_non_negative CHECK (stock_quantity >= 0),
    CONSTRAINT chk_rating_range CHECK (rating >= 0 AND rating <= 5)
);

-- Product images
CREATE TABLE product_images (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    alt_text VARCHAR(255),
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- Product attributes (for flexible product specifications)
CREATE TABLE product_attributes (
    attribute_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    attribute_name VARCHAR(100) NOT NULL,
    attribute_value VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    UNIQUE KEY unique_product_attribute (product_id, attribute_name)
);

-- ========================================
-- INVENTORY MANAGEMENT
-- ========================================

-- Inventory movements (stock in/out tracking)
CREATE TABLE inventory_movements (
    movement_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    movement_type ENUM('IN', 'OUT', 'ADJUSTMENT') NOT NULL,
    quantity INT NOT NULL,
    reference_type ENUM('PURCHASE', 'SALE', 'RETURN', 'ADJUSTMENT') NOT NULL,
    reference_id INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

-- ========================================
-- SHOPPING CART TABLES
-- ========================================

-- Shopping carts
CREATE TABLE shopping_carts (
    cart_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_cart (user_id)
);

-- Cart items (Many-to-Many: Cart can have many products, products can be in many carts)
CREATE TABLE cart_items (
    cart_item_id INT AUTO_INCREMENT PRIMARY KEY,
    cart_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    price DECIMAL(10, 2) NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (cart_id) REFERENCES shopping_carts(cart_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_cart_product (cart_id, product_id),
    CONSTRAINT chk_cart_quantity_positive CHECK (quantity > 0)
);

-- ========================================
-- ORDER MANAGEMENT TABLES
-- ========================================

-- Orders
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    order_status ENUM('Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Returned') DEFAULT 'Pending',
    payment_status ENUM('Pending', 'Paid', 'Failed', 'Refunded', 'Partially_Refunded') DEFAULT 'Pending',
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0.00,
    shipping_cost DECIMAL(10, 2) DEFAULT 0.00,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    total_amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Shipping Information
    shipping_first_name VARCHAR(50) NOT NULL,
    shipping_last_name VARCHAR(50) NOT NULL,
    shipping_street_address VARCHAR(255) NOT NULL,
    shipping_city VARCHAR(100) NOT NULL,
    shipping_state VARCHAR(100) NOT NULL,
    shipping_postal_code VARCHAR(20) NOT NULL,
    shipping_country VARCHAR(100) NOT NULL,
    shipping_phone VARCHAR(20),
    
    -- Billing Information
    billing_first_name VARCHAR(50) NOT NULL,
    billing_last_name VARCHAR(50) NOT NULL,
    billing_street_address VARCHAR(255) NOT NULL,
    billing_city VARCHAR(100) NOT NULL,
    billing_state VARCHAR(100) NOT NULL,
    billing_postal_code VARCHAR(20) NOT NULL,
    billing_country VARCHAR(100) NOT NULL,
    
    notes TEXT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    
    CONSTRAINT chk_amounts_non_negative CHECK (
        subtotal >= 0 AND tax_amount >= 0 AND 
        shipping_cost >= 0 AND discount_amount >= 0 AND total_amount >= 0
    )
);

-- Order items
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    product_name VARCHAR(255) NOT NULL, -- Store product name at time of order
    product_sku VARCHAR(100) NOT NULL,   -- Store SKU at time of order
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    
    CONSTRAINT chk_order_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_order_prices_positive CHECK (unit_price > 0 AND total_price > 0)
);

-- ========================================
-- PAYMENT TABLES
-- ========================================

-- Payment methods
CREATE TABLE payment_methods (
    payment_method_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    method_type ENUM('Credit_Card', 'Debit_Card', 'PayPal', 'Bank_Transfer', 'Digital_Wallet') NOT NULL,
    card_last_four VARCHAR(4),
    card_brand VARCHAR(50),
    expiry_month INT,
    expiry_year INT,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Payments
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_method_id INT,
    payment_gateway ENUM('Stripe', 'PayPal', 'Square', 'Bank_Transfer') NOT NULL,
    transaction_id VARCHAR(255) UNIQUE,
    payment_status ENUM('Pending', 'Completed', 'Failed', 'Cancelled', 'Refunded') DEFAULT 'Pending',
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    gateway_response TEXT,
    processed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id) ON DELETE SET NULL,
    
    CONSTRAINT chk_payment_amount_positive CHECK (amount > 0)
);

-- ========================================
-- SHIPPING TABLES
-- ========================================

-- Shipping methods
CREATE TABLE shipping_methods (
    shipping_method_id INT AUTO_INCREMENT PRIMARY KEY,
    method_name VARCHAR(100) NOT NULL,
    description TEXT,
    base_cost DECIMAL(10, 2) NOT NULL,
    cost_per_kg DECIMAL(10, 2) DEFAULT 0.00,
    estimated_days_min INT,
    estimated_days_max INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Shipments
CREATE TABLE shipments (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    shipping_method_id INT NOT NULL,
    tracking_number VARCHAR(100) UNIQUE,
    carrier VARCHAR(100),
    shipment_status ENUM('Preparing', 'Shipped', 'In_Transit', 'Delivered', 'Failed', 'Returned') DEFAULT 'Preparing',
    shipped_date TIMESTAMP,
    estimated_delivery DATE,
    actual_delivery_date TIMESTAMP,
    weight DECIMAL(8, 2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,
    FOREIGN KEY (shipping_method_id) REFERENCES shipping_methods(shipping_method_id) ON DELETE RESTRICT
);

-- ========================================
-- REVIEW AND RATING TABLES
-- ========================================

-- Product reviews
CREATE TABLE product_reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    user_id INT NOT NULL,
    order_id INT, -- Optional: link to actual purchase
    rating INT NOT NULL,
    title VARCHAR(255),
    review_text TEXT,
    is_verified_purchase BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT FALSE,
    helpful_votes INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE SET NULL,

    UNIQUE KEY unique_user_product_review (user_id, product_id),
    CONSTRAINT chk_product_reviews_rating_range CHECK (rating >= 1 AND rating <= 5)
);

-- ========================================
-- DISCOUNT AND COUPON TABLES
-- ========================================

-- Coupons
CREATE TABLE coupons (
    coupon_id INT AUTO_INCREMENT PRIMARY KEY,
    coupon_code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    discount_type ENUM('Percentage', 'Fixed_Amount', 'Free_Shipping') NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    minimum_order_amount DECIMAL(10, 2) DEFAULT 0.00,
    maximum_discount_amount DECIMAL(10, 2),
    usage_limit INT,
    used_count INT DEFAULT 0,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_discount_value_positive CHECK (discount_value > 0),
    CONSTRAINT chk_usage_within_limit CHECK (used_count <= usage_limit OR usage_limit IS NULL)
);

-- Coupon usage tracking
CREATE TABLE coupon_usage (
    usage_id INT AUTO_INCREMENT PRIMARY KEY,
    coupon_id INT NOT NULL,
    user_id INT NOT NULL,
    order_id INT NOT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE RESTRICT
);

-- ========================================
-- WISHLIST TABLES
-- ========================================

-- Wishlists (One-to-One: Each user has one wishlist)
CREATE TABLE wishlists (
    wishlist_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Wishlist items (Many-to-Many: Wishlist can have many products)
CREATE TABLE wishlist_items (
    wishlist_item_id INT AUTO_INCREMENT PRIMARY KEY,
    wishlist_id INT NOT NULL,
    product_id INT NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (wishlist_id) REFERENCES wishlists(wishlist_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_wishlist_product (wishlist_id, product_id)
);

-- ========================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ========================================

-- User indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_type ON users(user_type);

-- Product indexes
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_featured ON products(featured);
CREATE INDEX idx_products_price ON products(price);

-- Order indexes
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_number ON orders(order_number);

-- Payment indexes
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_transaction ON payments(transaction_id);

-- Review indexes
CREATE INDEX idx_reviews_product ON product_reviews(product_id);
CREATE INDEX idx_reviews_user ON product_reviews(user_id);
CREATE INDEX idx_reviews_rating ON product_reviews(rating);

-- ========================================
-- SAMPLE DATA INSERTION (Optional)
-- ========================================

-- Insert sample categories
INSERT INTO categories (category_name, description) VALUES 
('Electronics', 'Electronic devices and accessories'),
('Clothing', 'Apparel and fashion items'),
('Books', 'Physical and digital books'),
('Home & Garden', 'Home improvement and garden supplies'),
('Sports & Outdoors', 'Sports equipment and outdoor gear');

-- Insert sample brands
INSERT INTO brands (brand_name, description) VALUES 
('TechCorp', 'Leading technology brand'),
('FashionHub', 'Trendy fashion brand'),
('BookWorld', 'Quality book publisher'),
('HomeMax', 'Home improvement specialists'),
('SportsPro', 'Professional sports equipment');

-- Insert sample shipping methods
INSERT INTO shipping_methods (method_name, description, base_cost, estimated_days_min, estimated_days_max) VALUES 
('Standard Shipping', 'Regular shipping service', 5.99, 5, 7),
('Express Shipping', 'Fast shipping service', 12.99, 2, 3),
('Overnight Shipping', 'Next day delivery', 24.99, 1, 1),
('Free Shipping', 'Free shipping for orders over $50', 0.00, 7, 10);

-- ========================================
-- DATABASE VIEWS FOR COMMON QUERIES
-- ========================================

-- View for product details with category and brand
CREATE VIEW product_details AS
SELECT 
    p.product_id,
    p.product_name,
    p.description,
    p.sku,
    p.price,
    p.stock_quantity,
    p.rating,
    p.total_reviews,
    c.category_name,
    b.brand_name,
    p.is_active,
    p.featured
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id
LEFT JOIN brands b ON p.brand_id = b.brand_id;

-- View for order summary
CREATE VIEW order_summary AS
SELECT 
    o.order_id,
    o.order_number,
    o.order_status,
    o.payment_status,
    CONCAT(u.first_name, ' ', u.last_name) AS customer_name,
    u.email AS customer_email,
    o.total_amount,
    o.order_date,
    COUNT(oi.order_item_id) AS total_items
FROM orders o
JOIN users u ON o.user_id = u.user_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id;

-- ========================================
-- STORED PROCEDURES (Examples)
-- ========================================


-- Procedure to update product stock after order
DELIMITER $$

CREATE PROCEDURE UpdateProductStock(
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_operation VARCHAR(10)
)
BEGIN
    DECLARE current_stock INT;

    -- Get current stock
    SELECT stock INTO current_stock
    FROM products
    WHERE product_id = p_product_id;

    -- Update stock based on operation
    IF p_operation = 'ADD' THEN
        UPDATE products
        SET stock = current_stock + p_quantity
        WHERE product_id = p_product_id;
    ELSEIF p_operation = 'SUBTRACT' THEN
        UPDATE products
        SET stock = current_stock - p_quantity
        WHERE product_id = p_product_id;
    END IF;
END$$

DELIMITER ;

-- ========================================
-- TRIGGERS FOR AUTOMATED OPERATIONS
-- ========================================

DELIMITER //

-- Trigger to update product rating after review insert/update
CREATE TRIGGER update_product_rating_after_review
AFTER INSERT ON product_reviews
FOR EACH ROW
BEGIN
    UPDATE products 
    SET rating = (
        SELECT AVG(rating) 
        FROM product_reviews 
        WHERE product_id = NEW.product_id AND is_approved = TRUE
    ),
    total_reviews = (
        SELECT COUNT(*) 
        FROM product_reviews 
        WHERE product_id = NEW.product_id AND is_approved = TRUE
    )
    WHERE product_id = NEW.product_id;
END //

-- Trigger to create shopping cart when user registers

DELIMITER $$

CREATE TRIGGER create_user_cart_after_registration
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    IF NEW.user_type = 'Customer' THEN
        INSERT INTO shopping_carts (user_id)
        VALUES (NEW.user_id);
    END IF;
END$$

DELIMITER ;

