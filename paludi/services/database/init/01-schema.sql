-- Paludi Coffee Shop Database Schema
-- PostgreSQL 16
-- Created: 2026-02-12

-- =============================================================================
-- USERS TABLE
-- Stores system users (administrators, baristas, cashiers)
-- =============================================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'barista', 'cashier')),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE users IS 'System users including administrators, baristas, and cashiers';
COMMENT ON COLUMN users.password_hash IS 'Bcrypt hashed password';
COMMENT ON COLUMN users.role IS 'User role: admin, barista, or cashier';

-- =============================================================================
-- CATEGORIES TABLE
-- Product categories (Café, Té, Frappé, Snacks, etc.)
-- =============================================================================
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INT DEFAULT 0,
    active BOOLEAN DEFAULT true
);

COMMENT ON TABLE categories IS 'Product categories for menu organization';
COMMENT ON COLUMN categories.display_order IS 'Order in which categories appear in the menu';

-- =============================================================================
-- PRODUCTS TABLE
-- Menu items (drinks and food)
-- =============================================================================
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    category_id INT REFERENCES categories(id),
    name VARCHAR(150) NOT NULL,
    description TEXT,
    base_price DECIMAL(10,2) NOT NULL,
    image_url VARCHAR(500),
    available BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE products IS 'Menu items available for order';
COMMENT ON COLUMN products.base_price IS 'Base price for smallest size in local currency';
COMMENT ON COLUMN products.available IS 'Whether product is currently available for order';

-- =============================================================================
-- SIZES TABLE
-- Available sizes (Chico, Mediano, Grande / Tall, Grande, Venti)
-- =============================================================================
CREATE TABLE sizes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    multiplier DECIMAL(3,2) DEFAULT 1.00
);

COMMENT ON TABLE sizes IS 'Available drink sizes with price multipliers';
COMMENT ON COLUMN sizes.multiplier IS 'Price multiplier applied to base price (e.g., 1.25 = +25%)';

-- =============================================================================
-- EXTRAS TABLE
-- Customizations and add-ons (extra shot, whipped cream, alternative milks)
-- =============================================================================
CREATE TABLE extras (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50),
    available BOOLEAN DEFAULT true
);

COMMENT ON TABLE extras IS 'Product customizations and add-ons';
COMMENT ON COLUMN extras.category IS 'Extra category (e.g., shots, milk, toppings, syrups)';

-- =============================================================================
-- INGREDIENTS TABLE
-- Inventory items used to make products
-- =============================================================================
CREATE TABLE ingredients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    current_stock DECIMAL(10,3) DEFAULT 0,
    min_stock DECIMAL(10,3) DEFAULT 0,
    cost_per_unit DECIMAL(10,2) DEFAULT 0
);

COMMENT ON TABLE ingredients IS 'Inventory items and raw materials';
COMMENT ON COLUMN ingredients.unit IS 'Unit of measurement (kg, litros, unidades, ml, gramos)';
COMMENT ON COLUMN ingredients.current_stock IS 'Current stock level';
COMMENT ON COLUMN ingredients.min_stock IS 'Minimum stock level before reorder alert';
COMMENT ON COLUMN ingredients.cost_per_unit IS 'Cost per unit for COGS calculation';

-- =============================================================================
-- PRODUCT_INGREDIENTS TABLE
-- Recipe mapping (which ingredients are used in each product)
-- =============================================================================
CREATE TABLE product_ingredients (
    product_id INT REFERENCES products(id),
    ingredient_id INT REFERENCES ingredients(id),
    quantity_per_unit DECIMAL(10,3) NOT NULL,
    PRIMARY KEY (product_id, ingredient_id)
);

COMMENT ON TABLE product_ingredients IS 'Recipe mapping between products and ingredients';
COMMENT ON COLUMN product_ingredients.quantity_per_unit IS 'Quantity of ingredient needed per single product unit';

-- =============================================================================
-- ORDERS TABLE
-- Customer orders (POS and mobile)
-- =============================================================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(20) UNIQUE NOT NULL,
    customer_name VARCHAR(100),
    channel VARCHAR(10) NOT NULL CHECK (channel IN ('pos', 'mobile')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'preparing', 'ready', 'delivered', 'cancelled')),
    subtotal DECIMAL(10,2) DEFAULT 0,
    tax DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE orders IS 'Customer orders from POS or mobile app';
COMMENT ON COLUMN orders.order_number IS 'Human-readable order number displayed to customer';
COMMENT ON COLUMN orders.channel IS 'Order channel: pos (point of sale) or mobile (app)';
COMMENT ON COLUMN orders.status IS 'Order status: pending, preparing, ready, delivered, or cancelled';

-- =============================================================================
-- ORDER_ITEMS TABLE
-- Individual items within an order
-- =============================================================================
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(id) ON DELETE CASCADE,
    product_id INT REFERENCES products(id),
    size_id INT REFERENCES sizes(id),
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    notes TEXT
);

COMMENT ON TABLE order_items IS 'Line items within an order';
COMMENT ON COLUMN order_items.unit_price IS 'Final unit price including size multiplier (before extras)';
COMMENT ON COLUMN order_items.notes IS 'Special instructions (e.g., extra hot, no foam)';

-- =============================================================================
-- ORDER_ITEM_EXTRAS TABLE
-- Extras/customizations applied to order items
-- =============================================================================
CREATE TABLE order_item_extras (
    id SERIAL PRIMARY KEY,
    order_item_id INT REFERENCES order_items(id) ON DELETE CASCADE,
    extra_id INT REFERENCES extras(id),
    price DECIMAL(10,2) NOT NULL
);

COMMENT ON TABLE order_item_extras IS 'Extras and customizations added to order items';
COMMENT ON COLUMN order_item_extras.price IS 'Price of extra at time of order (for historical accuracy)';

-- =============================================================================
-- INVENTORY_MOVEMENTS TABLE
-- Track inventory changes (purchases, usage, adjustments)
-- =============================================================================
CREATE TABLE inventory_movements (
    id SERIAL PRIMARY KEY,
    ingredient_id INT REFERENCES ingredients(id),
    type VARCHAR(20) CHECK (type IN ('in', 'out', 'adjustment')),
    quantity DECIMAL(10,3) NOT NULL,
    reference TEXT,
    user_id INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE inventory_movements IS 'Audit trail for inventory changes';
COMMENT ON COLUMN inventory_movements.type IS 'Movement type: in (purchase), out (usage), adjustment (correction)';
COMMENT ON COLUMN inventory_movements.quantity IS 'Quantity moved (positive or negative)';
COMMENT ON COLUMN inventory_movements.reference IS 'Reference note (e.g., invoice number, order ID, reason)';

-- =============================================================================
-- INDEXES
-- Performance optimization for common queries
-- =============================================================================

-- Orders indexes
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_orders_channel ON orders(channel);

-- Products indexes
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_available ON products(available);

-- Inventory indexes
CREATE INDEX idx_inventory_movements_ingredient_id ON inventory_movements(ingredient_id);
CREATE INDEX idx_inventory_movements_created_at ON inventory_movements(created_at);

-- =============================================================================
-- TRIGGER: Auto-update orders.updated_at
-- =============================================================================

CREATE OR REPLACE FUNCTION update_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_orders_updated_at();

COMMENT ON FUNCTION update_orders_updated_at() IS 'Automatically updates updated_at timestamp on orders table';

-- =============================================================================
-- END OF SCHEMA
-- =============================================================================
