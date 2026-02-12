const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Default error
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal server error';
  let errors = err.errors || null;

  // Validation errors
  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = 'Validation failed';
    errors = err.errors;
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid token';
  }

  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Token expired';
  }

  // Database errors
  if (err.code === '23505') {
    statusCode = 409;
    message = 'Duplicate entry';
  }

  if (err.code === '23503') {
    statusCode = 400;
    message = 'Foreign key constraint violation';
  }

  if (err.code === '22P02') {
    statusCode = 400;
    message = 'Invalid input syntax';
  }

  // Not found
  if (err.name === 'NotFoundError') {
    statusCode = 404;
    message = err.message || 'Resource not found';
  }

  // Response structure
  const response = {
    error: message,
    statusCode,
  };

  // Include additional details in development
  if (process.env.NODE_ENV === 'development') {
    response.stack = err.stack;
    response.details = err.details || null;
  }

  // Include validation errors if present
  if (errors) {
    response.errors = errors;
  }

  res.status(statusCode).json(response);
};

module.exports = errorHandler;
