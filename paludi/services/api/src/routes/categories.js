const express = require('express');
const { body, validationResult } = require('express-validator');
const pool = require('../config/database');
const { authenticate, requireRole } = require('../middleware/auth');

const router = express.Router();

// GET / - List all active categories
router.get('/', async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, name, description, icon, color, display_order, created_at, updated_at
       FROM categories
       WHERE active = true
       ORDER BY display_order, name`
    );

    res.json({
      success: true,
      count: result.rows.length,
      categories: result.rows,
    });
  } catch (error) {
    next(error);
  }
});

// POST / - Create new category (admin only)
router.post('/', authenticate, requireRole('admin'), [
  body('name').notEmpty().trim(),
  body('description').optional().trim(),
  body('icon').optional().trim(),
  body('color').optional().trim(),
  body('display_order').optional().isInt(),
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        errors: errors.array()
      });
    }

    const { name, description, icon, color, display_order } = req.body;

    const result = await pool.query(
      `INSERT INTO categories (name, description, icon, color, display_order, active)
       VALUES ($1, $2, $3, $4, $5, true)
       RETURNING *`,
      [
        name,
        description || null,
        icon || null,
        color || null,
        display_order || 0
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Category created successfully',
      category: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
});

// PUT /:id - Update category (admin only)
router.put('/:id', authenticate, requireRole('admin'), [
  body('name').optional().notEmpty().trim(),
  body('description').optional().trim(),
  body('icon').optional().trim(),
  body('color').optional().trim(),
  body('display_order').optional().isInt(),
  body('active').optional().isBoolean(),
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

    const allowedFields = ['name', 'description', 'icon', 'color', 'display_order', 'active'];

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
      UPDATE categories
      SET ${updates.join(', ')}, updated_at = NOW()
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Category not found',
        message: 'The requested category does not exist'
      });
    }

    res.json({
      success: true,
      message: 'Category updated successfully',
      category: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
