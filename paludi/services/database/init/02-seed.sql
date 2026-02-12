-- Paludi Coffee Shop Seed Data
-- Initial data for development and testing
-- Created: 2026-02-12

-- =============================================================================
-- USERS
-- Default system users (password for all: 'admin123')
-- =============================================================================

INSERT INTO users (email, password_hash, name, role, active) VALUES
('admin@paludi.com', '$2b$12$LJ3m4ys3Lg2VhBMTgGKMeORC0gFCBMnmONOxpHKbMEzplRd0WWbWG', 'Administrador Principal', 'admin', true),
('barista@paludi.com', '$2b$12$LJ3m4ys3Lg2VhBMTgGKMeORC0gFCBMnmONOxpHKbMEzplRd0WWbWG', 'María González', 'barista', true);

-- =============================================================================
-- CATEGORIES
-- Product categories for menu organization
-- =============================================================================

INSERT INTO categories (name, description, display_order, active) VALUES
('Café Caliente', 'Bebidas de café caliente tradicionales', 1, true),
('Café Frío', 'Bebidas de café frías y refrescantes', 2, true),
('Frappé', 'Bebidas frappé cremosas y heladas', 3, true),
('Té', 'Selección de tés calientes y fríos', 4, true),
('Bebidas Especiales', 'Bebidas de temporada y especialidades', 5, true),
('Snacks', 'Alimentos y postres', 6, true);

-- =============================================================================
-- PRODUCTS
-- Menu items with base prices in MXN
-- =============================================================================

INSERT INTO products (category_id, name, description, base_price, available) VALUES
-- Café Caliente
(1, 'Americano', 'Espresso clásico con agua caliente', 38.00, true),
(1, 'Latte', 'Espresso con leche vaporizada y espuma suave', 48.00, true),
(1, 'Cappuccino', 'Espresso con espuma de leche cremosa', 48.00, true),
(1, 'Mocha', 'Latte con chocolate y crema batida', 55.00, true),
(1, 'Caramel Macchiato', 'Vainilla, leche, espresso y caramelo', 58.00, true),

-- Café Frío
(2, 'Café con Hielo', 'Espresso servido sobre hielo', 42.00, true),
(2, 'Cold Brew', 'Café de preparación fría suave y refrescante', 48.00, true),
(2, 'Iced Latte', 'Espresso con leche fría sobre hielo', 52.00, true),

-- Frappé
(3, 'Frappé de Café', 'Bebida helada cremosa de café', 62.00, true),
(3, 'Frappé de Chocolate', 'Bebida helada cremosa de chocolate', 62.00, true),
(3, 'Frappé de Caramelo', 'Bebida helada cremosa de caramelo', 65.00, true),
(3, 'Frappé de Vainilla', 'Bebida helada cremosa de vainilla', 62.00, true),

-- Té
(4, 'Té Verde', 'Té verde japonés premium', 35.00, true),
(4, 'Té Negro', 'Té negro english breakfast', 35.00, true),
(4, 'Chai Latte', 'Té chai especiado con leche vaporizada', 48.00, true),
(4, 'Matcha Latte', 'Té matcha japonés con leche', 58.00, true),

-- Bebidas Especiales
(5, 'Horchata Latte', 'Latte con sabor a horchata y canela', 55.00, true),
(5, 'Pink Drink', 'Bebida refrescante de frutos rojos con leche de coco', 58.00, true),

-- Snacks
(6, 'Croissant', 'Croissant francés de mantequilla', 35.00, true),
(6, 'Muffin de Chocolate', 'Muffin con chispas de chocolate', 42.00, true),
(6, 'Panini de Jamón y Queso', 'Panini caliente con jamón y queso', 68.00, true),
(6, 'Galleta de Avena', 'Galleta casera de avena con pasas', 28.00, true);

-- =============================================================================
-- SIZES
-- Available sizes with price multipliers
-- =============================================================================

INSERT INTO sizes (name, multiplier) VALUES
('Chico', 1.00),
('Mediano', 1.25),
('Grande', 1.50);

-- =============================================================================
-- EXTRAS
-- Customizations and add-ons (prices in MXN)
-- =============================================================================

INSERT INTO extras (name, price, category, available) VALUES
('Shot Extra de Espresso', 15.00, 'shots', true),
('Crema Batida', 10.00, 'toppings', true),
('Leche de Almendra', 12.00, 'milk', true),
('Leche de Coco', 12.00, 'milk', true),
('Leche Deslactosada', 8.00, 'milk', true),
('Jarabe de Vainilla', 8.00, 'syrups', true),
('Jarabe de Caramelo', 8.00, 'syrups', true),
('Jarabe de Avellana', 8.00, 'syrups', true),
('Canela en Polvo', 5.00, 'toppings', true),
('Chocolate Extra', 10.00, 'toppings', true);

-- =============================================================================
-- INGREDIENTS
-- Inventory items with initial stock levels
-- =============================================================================

INSERT INTO ingredients (name, unit, current_stock, min_stock, cost_per_unit) VALUES
('Café Espresso (granos)', 'kg', 25.000, 5.000, 180.00),
('Leche Entera', 'litros', 60.000, 20.000, 18.00),
('Leche de Almendra', 'litros', 15.000, 5.000, 45.00),
('Leche de Coco', 'litros', 12.000, 5.000, 42.00),
('Crema Batida', 'litros', 10.000, 3.000, 85.00),
('Chocolate en Polvo', 'kg', 8.000, 2.000, 120.00),
('Jarabe de Vainilla', 'litros', 5.000, 1.500, 95.00),
('Jarabe de Caramelo', 'litros', 5.000, 1.500, 95.00),
('Té Matcha en Polvo', 'kg', 2.000, 0.500, 850.00),
('Hielo', 'kg', 100.000, 30.000, 3.00),
('Azúcar', 'kg', 20.000, 5.000, 22.00),
('Canela en Polvo', 'kg', 1.500, 0.300, 180.00),
('Té Verde (hojas)', 'kg', 3.000, 0.500, 320.00),
('Té Negro (hojas)', 'kg', 3.000, 0.500, 280.00),
('Chai en Polvo', 'kg', 2.500, 0.500, 420.00);

-- =============================================================================
-- PRODUCT_INGREDIENTS
-- Recipe mappings (quantities per single unit)
-- =============================================================================

-- Americano (30g café, 240ml agua)
INSERT INTO product_ingredients (product_id, ingredient_id, quantity_per_unit) VALUES
(1, 1, 0.030); -- Café espresso

-- Latte (30g café, 240ml leche)
INSERT INTO product_ingredients (product_id, ingredient_id, quantity_per_unit) VALUES
(2, 1, 0.030), -- Café espresso
(2, 2, 0.240); -- Leche entera

-- Cappuccino (30g café, 180ml leche)
INSERT INTO product_ingredients (product_id, ingredient_id, quantity_per_unit) VALUES
(3, 1, 0.030), -- Café espresso
(3, 2, 0.180); -- Leche entera

-- Mocha (30g café, 200ml leche, 30g chocolate, 30ml crema)
INSERT INTO product_ingredients (product_id, ingredient_id, quantity_per_unit) VALUES
(4, 1, 0.030), -- Café espresso
(4, 2, 0.200), -- Leche entera
(4, 6, 0.030), -- Chocolate
(4, 5, 0.030); -- Crema batida

-- Caramel Macchiato (30g café, 220ml leche, 20ml vainilla, 15ml caramelo)
INSERT INTO product_ingredients (product_id, ingredient_id, quantity_per_unit) VALUES
(5, 1, 0.030), -- Café espresso
(5, 2, 0.220), -- Leche entera
(5, 7, 0.020), -- Jarabe vainilla
(5, 8, 0.015); -- Jarabe caramelo

-- Iced Latte (30g café, 200ml leche, 100g hielo)
INSERT INTO product_ingredients (product_id, ingredient_id, quantity_per_unit) VALUES
(8, 1, 0.030), -- Café espresso
(8, 2, 0.200), -- Leche entera
(8, 10, 0.100); -- Hielo

-- Frappé de Café (30g café, 120ml leche, 200g hielo, 30ml crema)
INSERT INTO product_ingredients (product_id, ingredient_id, quantity_per_unit) VALUES
(9, 1, 0.030), -- Café espresso
(9, 2, 0.120), -- Leche entera
(9, 10, 0.200), -- Hielo
(9, 5, 0.030), -- Crema batida
(9, 11, 0.020); -- Azúcar

-- Matcha Latte (15g matcha, 240ml leche)
INSERT INTO product_ingredients (product_id, ingredient_id, quantity_per_unit) VALUES
(16, 9, 0.015), -- Matcha
(16, 2, 0.240); -- Leche entera

-- Té Verde (8g té, 300ml agua)
INSERT INTO product_ingredients (product_id, ingredient_id, quantity_per_unit) VALUES
(13, 13, 0.008); -- Té verde

-- Chai Latte (20g chai, 240ml leche)
INSERT INTO product_ingredients (product_id, ingredient_id, quantity_per_unit) VALUES
(15, 15, 0.020), -- Chai en polvo
(15, 2, 0.240); -- Leche entera

-- =============================================================================
-- SAMPLE ORDERS
-- Example orders to demonstrate the system
-- =============================================================================

-- Order 1: POS order with multiple items
INSERT INTO orders (order_number, customer_name, channel, status, subtotal, tax, total, created_at) VALUES
('ORD-001', 'Juan Pérez', 'pos', 'delivered', 143.00, 22.88, 165.88, NOW() - INTERVAL '2 hours');

INSERT INTO order_items (order_id, product_id, size_id, quantity, unit_price, notes) VALUES
(1, 2, 2, 1, 60.00, 'Extra caliente'), -- Latte Mediano
(1, 20, 1, 2, 35.00, NULL), -- 2 Croissants
(1, 9, 3, 1, 93.00, NULL); -- Frappé de Café Grande

INSERT INTO order_item_extras (order_item_id, extra_id, price) VALUES
(1, 1, 15.00), -- Shot extra en el latte
(3, 2, 10.00); -- Crema extra en el frappé

-- Order 2: Mobile order in progress
INSERT INTO orders (order_number, customer_name, channel, status, subtotal, tax, total, created_at) VALUES
('ORD-002', 'Ana López', 'mobile', 'preparing', 106.00, 16.96, 122.96, NOW() - INTERVAL '15 minutes');

INSERT INTO order_items (order_id, product_id, size_id, quantity, unit_price, notes) VALUES
(2, 8, 2, 1, 65.00, 'Con leche de almendra'), -- Iced Latte Mediano
(2, 16, 2, 1, 72.50, NULL); -- Matcha Latte Mediano

INSERT INTO order_item_extras (order_item_id, extra_id, price) VALUES
(4, 3, 12.00); -- Leche de almendra

-- Order 3: Recent POS order pending
INSERT INTO orders (order_number, customer_name, channel, status, subtotal, tax, total, created_at) VALUES
('ORD-003', 'Carlos Ramírez', 'pos', 'pending', 186.00, 29.76, 215.76, NOW() - INTERVAL '5 minutes');

INSERT INTO order_items (order_id, product_id, size_id, quantity, unit_price, notes) VALUES
(3, 5, 3, 1, 87.00, NULL), -- Caramel Macchiato Grande
(3, 11, 3, 1, 97.50, 'Sin crema'), -- Frappé de Caramelo Grande
(3, 22, 1, 1, 68.00, NULL); -- Panini

INSERT INTO order_item_extras (order_item_id, extra_id, price) VALUES
(6, 1, 15.00), -- Shot extra
(7, 3, 12.00); -- Leche de almendra

-- Order 4: Morning rush order
INSERT INTO orders (order_number, customer_name, channel, status, subtotal, tax, total, created_at) VALUES
('ORD-004', 'María Sánchez', 'mobile', 'ready', 90.00, 14.40, 104.40, NOW() - INTERVAL '30 minutes');

INSERT INTO order_items (order_id, product_id, size_id, quantity, unit_price, notes) VALUES
(4, 1, 2, 2, 47.50, NULL); -- 2 Americano Mediano

INSERT INTO order_item_extras (order_item_id, extra_id, price) VALUES
(8, 5, 8.00), -- Leche deslactosada para uno
(9, 1, 15.00); -- Shot extra para el otro

-- =============================================================================
-- SAMPLE INVENTORY MOVEMENTS
-- Example inventory transactions
-- =============================================================================

INSERT INTO inventory_movements (ingredient_id, type, quantity, reference, user_id, created_at) VALUES
-- Recent stock replenishment
(1, 'in', 10.000, 'Compra - Factura #1234', 1, NOW() - INTERVAL '1 day'),
(2, 'in', 40.000, 'Compra - Factura #1234', 1, NOW() - INTERVAL '1 day'),
(10, 'in', 50.000, 'Compra - Factura #1235', 1, NOW() - INTERVAL '6 hours'),

-- Usage from orders
(1, 'out', -0.120, 'Órdenes del día - 4 bebidas con espresso', 2, NOW() - INTERVAL '2 hours'),
(2, 'out', -1.120, 'Órdenes del día - múltiples lattes', 2, NOW() - INTERVAL '2 hours'),
(10, 'out', -0.300, 'Órdenes del día - bebidas frías', 2, NOW() - INTERVAL '2 hours'),

-- Adjustment
(5, 'adjustment', -0.500, 'Ajuste por inventario físico - recipiente dañado', 1, NOW() - INTERVAL '3 hours');

-- =============================================================================
-- END OF SEED DATA
-- =============================================================================

-- Summary report
DO $$
BEGIN
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'Paludi Database Seed Completed Successfully';
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'Users created: %', (SELECT COUNT(*) FROM users);
    RAISE NOTICE 'Categories created: %', (SELECT COUNT(*) FROM categories);
    RAISE NOTICE 'Products created: %', (SELECT COUNT(*) FROM products);
    RAISE NOTICE 'Sizes created: %', (SELECT COUNT(*) FROM sizes);
    RAISE NOTICE 'Extras created: %', (SELECT COUNT(*) FROM extras);
    RAISE NOTICE 'Ingredients created: %', (SELECT COUNT(*) FROM ingredients);
    RAISE NOTICE 'Sample orders created: %', (SELECT COUNT(*) FROM orders);
    RAISE NOTICE '=============================================================================';
    RAISE NOTICE 'Default login credentials:';
    RAISE NOTICE '  Admin: admin@paludi.com / admin123';
    RAISE NOTICE '  Barista: barista@paludi.com / admin123';
    RAISE NOTICE '=============================================================================';
END $$;
