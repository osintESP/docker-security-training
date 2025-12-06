/**
 * =============================================================================
 * SECURE API SERVER
 * =============================================================================
 * Security Features:
 * - Helmet for security headers
 * - CORS configuration
 * - Rate limiting
 * - Input validation
 * - Environment-based configuration
 * - Health check endpoint
 * =============================================================================
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const https = require('https');

// =============================================================================
// BITCOIN PRICE SERVICE
// =============================================================================
const COINGECKO_API = 'https://api.coingecko.com/api/v3';
const PRICE_CACHE_TTL = 10000; // 10 seconds cache

let priceCache = {
  data: null,
  timestamp: 0
};

/**
 * Fetch Bitcoin price from CoinGecko API
 * Implements caching to avoid rate limits
 */
function fetchBitcoinPrice() {
  return new Promise((resolve, reject) => {
    // Return cached data if still valid
    if (priceCache.data && (Date.now() - priceCache.timestamp) < PRICE_CACHE_TTL) {
      return resolve(priceCache.data);
    }

    const url = `${COINGECKO_API}/simple/price?ids=bitcoin&vs_currencies=usd,eur,gbp&include_24hr_change=true&include_last_updated_at=true`;

    https.get(url, {
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'SecureDockerApp/1.0'
      }
    }, (res) => {
      let data = '';

      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          if (res.statusCode !== 200) {
            return reject(new Error(`API returned status ${res.statusCode}`));
          }
          const parsed = JSON.parse(data);
          const result = {
            symbol: 'BTC',
            prices: {
              usd: parsed.bitcoin.usd,
              eur: parsed.bitcoin.eur,
              gbp: parsed.bitcoin.gbp
            },
            change_24h: parsed.bitcoin.usd_24h_change,
            last_updated: new Date(parsed.bitcoin.last_updated_at * 1000).toISOString(),
            cached: false
          };

          // Update cache
          priceCache = { data: result, timestamp: Date.now() };
          resolve(result);
        } catch (e) {
          reject(new Error('Failed to parse API response'));
        }
      });
    }).on('error', reject);
  });
}

// Create Express app
const app = express();

// =============================================================================
// CONFIGURATION (from environment variables)
// =============================================================================
const config = {
  port: process.env.PORT || 3001,
  nodeEnv: process.env.NODE_ENV || 'development',
  apiVersion: process.env.API_VERSION || '1.0.0',
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    database: process.env.DB_NAME || 'secureapp',
    user: process.env.DB_USER || 'appuser',
    password: process.env.DB_PASSWORD || 'changeme',
    // Connection pool settings
    max: parseInt(process.env.DB_POOL_MAX, 10) || 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  },
};

// =============================================================================
// DATABASE CONNECTION
// =============================================================================
const pool = new Pool(config.db);

// Test database connection
pool.on('connect', () => {
  console.log('Database connection established');
});

pool.on('error', (err) => {
  console.error('Unexpected database error:', err);
});

// =============================================================================
// MIDDLEWARE
// =============================================================================

// Security headers with Helmet
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:'],
    },
  },
  crossOriginEmbedderPolicy: false,
}));

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Body parsing
app.use(express.json({ limit: '10kb' })); // Limit body size
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// Request logging (simple)
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// =============================================================================
// ROUTES
// =============================================================================

/**
 * Health Check Endpoint
 * Used by Docker health checks and Kubernetes probes
 */
app.get('/health', async (req, res) => {
  try {
    // Check database connectivity
    await pool.query('SELECT 1');
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      database: 'connected',
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: error.message,
    });
  }
});

/**
 * Readiness Check (for Kubernetes)
 */
app.get('/ready', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ ready: true });
  } catch (error) {
    res.status(503).json({ ready: false, error: error.message });
  }
});

/**
 * Version Endpoint
 */
app.get('/version', (req, res) => {
  res.json({
    version: config.apiVersion,
    environment: config.nodeEnv,
    node: process.version,
  });
});

// =============================================================================
// BITCOIN ROUTES
// =============================================================================

/**
 * GET /api/bitcoin/price - Get current BTC price
 */
app.get('/api/bitcoin/price', async (req, res) => {
  try {
    const price = await fetchBitcoinPrice();
    res.json(price);
  } catch (error) {
    console.error('Error fetching Bitcoin price:', error.message);
    res.status(503).json({
      error: 'Unable to fetch Bitcoin price',
      message: error.message
    });
  }
});

/**
 * GET /api/bitcoin/history - Get price history from DB
 */
app.get('/api/bitcoin/history', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 100, 1000);
    const result = await pool.query(
      'SELECT id, price_usd, price_eur, change_24h, recorded_at FROM btc_price_history ORDER BY recorded_at DESC LIMIT $1',
      [limit]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching price history:', error);
    res.status(500).json({ error: 'Failed to fetch price history' });
  }
});

/**
 * POST /api/bitcoin/record - Record current price to DB
 */
app.post('/api/bitcoin/record', async (req, res) => {
  try {
    const price = await fetchBitcoinPrice();

    const result = await pool.query(
      'INSERT INTO btc_price_history (price_usd, price_eur, change_24h) VALUES ($1, $2, $3) RETURNING *',
      [price.prices.usd, price.prices.eur, price.change_24h]
    );

    res.status(201).json({
      recorded: true,
      data: result.rows[0],
      current_price: price
    });
  } catch (error) {
    console.error('Error recording price:', error);
    res.status(500).json({ error: 'Failed to record price' });
  }
});

/**
 * GET /api/bitcoin/stats - Get price statistics
 */
app.get('/api/bitcoin/stats', async (req, res) => {
  try {
    const [current, stats, recent] = await Promise.all([
      fetchBitcoinPrice(),
      pool.query(`
        SELECT
          COUNT(*) as total_records,
          MIN(price_usd) as min_price,
          MAX(price_usd) as max_price,
          AVG(price_usd) as avg_price,
          MIN(recorded_at) as first_record,
          MAX(recorded_at) as last_record
        FROM btc_price_history
      `),
      pool.query(
        'SELECT price_usd, recorded_at FROM btc_price_history ORDER BY recorded_at DESC LIMIT 10'
      )
    ]);

    res.json({
      current: current,
      statistics: stats.rows[0],
      recent_records: recent.rows
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

// =============================================================================
// ITEMS ROUTES
// =============================================================================

/**
 * GET /api/items - Retrieve all items
 */
app.get('/api/items', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, description, created_at FROM items ORDER BY created_at DESC'
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching items:', error);
    res.status(500).json({ error: 'Failed to fetch items' });
  }
});

/**
 * GET /api/items/:id - Retrieve single item
 */
app.get('/api/items/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID is a number
    if (!/^\d+$/.test(id)) {
      return res.status(400).json({ error: 'Invalid item ID' });
    }

    const result = await pool.query(
      'SELECT id, name, description, created_at FROM items WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Item not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching item:', error);
    res.status(500).json({ error: 'Failed to fetch item' });
  }
});

/**
 * POST /api/items - Create new item
 */
app.post('/api/items', async (req, res) => {
  try {
    const { name, description } = req.body;

    // Input validation
    if (!name || typeof name !== 'string') {
      return res.status(400).json({ error: 'Name is required and must be a string' });
    }

    if (name.length > 255) {
      return res.status(400).json({ error: 'Name must be 255 characters or less' });
    }

    if (description && typeof description !== 'string') {
      return res.status(400).json({ error: 'Description must be a string' });
    }

    if (description && description.length > 1000) {
      return res.status(400).json({ error: 'Description must be 1000 characters or less' });
    }

    // Sanitize inputs (basic - use a proper sanitization library in production)
    const sanitizedName = name.trim();
    const sanitizedDescription = description ? description.trim() : null;

    const result = await pool.query(
      'INSERT INTO items (name, description) VALUES ($1, $2) RETURNING id, name, description, created_at',
      [sanitizedName, sanitizedDescription]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating item:', error);
    res.status(500).json({ error: 'Failed to create item' });
  }
});

/**
 * DELETE /api/items/:id - Delete item
 */
app.delete('/api/items/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID is a number
    if (!/^\d+$/.test(id)) {
      return res.status(400).json({ error: 'Invalid item ID' });
    }

    const result = await pool.query(
      'DELETE FROM items WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Item not found' });
    }

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting item:', error);
    res.status(500).json({ error: 'Failed to delete item' });
  }
});

// =============================================================================
// ERROR HANDLING
// =============================================================================

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: config.nodeEnv === 'production'
      ? 'Internal server error'
      : err.message
  });
});

// =============================================================================
// SERVER STARTUP
// =============================================================================

const server = app.listen(config.port, '0.0.0.0', () => {
  console.log('='.repeat(60));
  console.log('SECURE API SERVER');
  console.log('='.repeat(60));
  console.log(`Environment: ${config.nodeEnv}`);
  console.log(`Version: ${config.apiVersion}`);
  console.log(`Listening on port: ${config.port}`);
  console.log(`Database host: ${config.db.host}`);
  console.log('='.repeat(60));
});

// =============================================================================
// GRACEFUL SHUTDOWN
// =============================================================================

const gracefulShutdown = async (signal) => {
  console.log(`\n${signal} received. Starting graceful shutdown...`);

  server.close(async () => {
    console.log('HTTP server closed');

    try {
      await pool.end();
      console.log('Database pool closed');
      process.exit(0);
    } catch (error) {
      console.error('Error during shutdown:', error);
      process.exit(1);
    }
  });

  // Force shutdown after 30 seconds
  setTimeout(() => {
    console.error('Forced shutdown after timeout');
    process.exit(1);
  }, 30000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
