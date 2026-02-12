const express = require('express');
const { body, validationResult } = require('express-validator');
const pool = require('../config/database');
const { authenticate, requireRole } = require('../middleware/auth');

const router = express.Router();

// GET / - List all active products
router.get('/', async (req, res, next) => {
  try {
    const { category_id } = req.query;

    let query = `
      SELECT
        p.id, p.name, p.description, p.category_id, p.image_url,
        p.available, p.created_at, p.updated_at,
        c.name as category_name,
        c.color as category_color,
        json_agg(DISTINCT jsonb_build_object(
          'id', ps.id,
          'name', ps.name,
          'price', ps.price,
          'size_order', ps.size_order
        ) ORDER BY ps.size_order) FILTER (WHERE ps.id IS NOT NULL) as sizes,
        json_agg(DISTINCT jsonb_build_object(
          'id', e.id,
          'name', e.name,
          'price', e.price
        )) FILTER (WHERE e.id IS NOT NULL AND e.available = true) as extras
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN product_sizes ps ON p.id = ps.product_id
      LEFT JOIN extras e ON e.available = true
      WHERE p.available = true
    `;

    const params = [];
    if (category_id) {
      params.push(category_id);
      query += ` AND p.category_id = $${params.length}`;
    }

    query += `
      GROUP BY p.id, c.name, c.color
      ORDER BY c.display_order, p.name
    `;

    const result = await pool.query(query, params);

    res.json({
      success: true,
      count: result.rows.length,
      products: result.rows,
    });
  } catch (error) {
    next(error);
  }
});

// GET /:id - Get single product with full details
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    const productQuery = `
      SELECT
        p.id, p.name, p.description, p.category_id, p.image_url,
        p.available, p.created_at, p.updated_at,
        c.name as category_name,
        c.color as category_color,
        json_agg(DISTINCT jsonb_build_object(
          'id', ps.id,
          'name', ps.name,
          'price', ps.price,
          'size_order', ps.size_order
        ) ORDER BY ps.size_order) FILTER (WHERE ps.id IS NOT NULL) as sizes,
        json_agg(DISTINCT jsonb_build_object(
          'id', i.id,
          'name', i.name
        )) FILTER (WHERE i.id IS NOT NULL) as ingredients
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN product_sizes ps ON p.id = ps.product_id
      LEFT JOIN product_ingredients pi ON p.id = pi.product_id
      LEFT JOIN ingredients i ON pi.ingredient_id = i.id
      WHERE p.id = $1
      GROUP BY p.id, c.name, c.color
    `;

    const result = await pool.query(productQuery, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Product not found',
        message: 'The requested product does not exist'
      });
    }

    res.json({
      success: true,
      product: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
});

// POST / - Create new product (admin only)
router.post('/', authenticate, requireRole('admin'), [
  body('name').notEmpty().trim(),
  body('description').optional().trim(),
  body('category_id').isInt(),
  body('image_url').optional().isURL(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        errors: errors.array()
      });
    }

    const { name, description, category_id, image_url } = req.body;

    const result = await pool.query(
      `INSERT INTO products (name, description, category_id, image_url, available)
       VALUES ($1, $2, $3, $4, true)
       RETURNING *`,
      [name, description || null, category_id, image_url || null]
    );

    res.status(201).json({
      success: true,
      message: 'Product created successfully',
      product: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
});

// PUT /:id - Update product (admin only)
router.put('/:id', authenticate, requireRole('admin'), [
  body('name').optional().notEmpty().trim(),
  body('description').optional().trim(),
  body('category_id').optional().isInt(),
  body('image_url').optional().isURL(),
  body('available').optional().isBoolean(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        errors: errors.array()
      });
    }

    const { id } = req.params;
    const updates = [];
    const values = [];
    let paramCount = 1;

    const allowedFields = ['name', 'description', 'category_id', 'image_url', 'available'];

    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updates.push(`${field} = $${paramCount}`);
        values.push(req.body[field]);
        paramCount++;
      }
    }

    if (updates.length === 0) {
      return res.status(400).json({
        error: 'No valid fields to update',
        message: 'Please provide at least one field to update'
      });
    }

    values.push(id);
    const query = `
      UPDATE products
      SET ${updates.join(', ')}, updated_at = NOW()
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Product not found',
        message: 'The requested product does not exist'
      });
    }

    res.json({
      success: true,
      message: 'Product updated successfully',
      product: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /:id - Soft delete product (admin only)
router.delete('/:id', authenticate, requireRole('admin'), async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `UPDATE products
       SET available = false, updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Product not found',
        message: 'The requested product does not exist'
      });
    }

    res.json({
      success: true,
      message: 'Product deleted successfully',
      product: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
