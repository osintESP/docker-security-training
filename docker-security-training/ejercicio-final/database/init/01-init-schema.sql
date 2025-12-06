-- =============================================================================
-- DATABASE INITIALIZATION SCRIPT
-- =============================================================================
-- This script runs automatically when the PostgreSQL container is first created
-- It sets up the database schema and initial data
-- =============================================================================

-- Create the items table
CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_items_created_at ON items(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_items_name ON items(name);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_items_updated_at ON items;
CREATE TRIGGER update_items_updated_at
    BEFORE UPDATE ON items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data
INSERT INTO items (name, description) VALUES
    ('Docker Security', 'Learn about container security best practices'),
    ('Multi-stage Builds', 'Reduce image size and attack surface'),
    ('Non-root Users', 'Never run containers as root'),
    ('Alpine Images', 'Use minimal base images'),
    ('Health Checks', 'Monitor container health')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- BITCOIN PRICE HISTORY TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS btc_price_history (
    id SERIAL PRIMARY KEY,
    price_usd DECIMAL(18, 2) NOT NULL,
    price_eur DECIMAL(18, 2),
    change_24h DECIMAL(10, 4),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries on price history
CREATE INDEX IF NOT EXISTS idx_btc_price_recorded_at ON btc_price_history(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_btc_price_usd ON btc_price_history(price_usd);

-- Insert some sample Bitcoin data
INSERT INTO btc_price_history (price_usd, price_eur, change_24h, recorded_at) VALUES
    (97500.00, 92000.00, 2.45, NOW() - INTERVAL '2 hours'),
    (97200.00, 91800.00, 2.12, NOW() - INTERVAL '1 hour'),
    (97800.00, 92200.00, 2.78, NOW() - INTERVAL '30 minutes')
ON CONFLICT DO NOTHING;

-- Grant permissions (if using a separate app user)
-- The app user is created via environment variable POSTGRES_USER
-- These grants ensure the app has necessary permissions

-- Create read-only user for monitoring (optional)
-- CREATE USER readonly_user WITH PASSWORD 'readonly_password';
-- GRANT CONNECT ON DATABASE secureapp TO readonly_user;
-- GRANT USAGE ON SCHEMA public TO readonly_user;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

-- Log initialization complete
DO $$
BEGIN
    RAISE NOTICE 'Database initialization completed successfully';
END $$;
