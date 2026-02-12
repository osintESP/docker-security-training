const { Server } = require('socket.io');

let io = null;

const setupSocket = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: process.env.CORS_ORIGIN || '*',
      methods: ['GET', 'POST'],
    },
  });

  // Orders namespace
  const ordersNamespace = io.of('/orders');

  ordersNamespace.on('connection', (socket) => {
    console.log('Client connected to /orders namespace:', socket.id);

    socket.on('disconnect', () => {
      console.log('Client disconnected from /orders namespace:', socket.id);
    });
  });

  // Main namespace for general events
  io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);

    socket.on('disconnect', () => {
      console.log('Client disconnected:', socket.id);
    });
  });

  console.log('Socket.IO initialized');
  return io;
};

const getIO = () => {
  if (!io) {
    throw new Error('Socket.IO not initialized');
  }
  return io;
};

const emitOrderNew = (orderData) => {
  if (io) {
    io.of('/orders').emit('order:new', orderData);
  }
};

const emitOrderStatusChanged = (orderData) => {
  if (io) {
    io.of('/orders').emit('order:status-changed', orderData);
  }
};

const emitInventoryAlert = (inventoryData) => {
  if (io) {
    io.emit('inventory:alert', inventoryData);
  }
};

module.exports = {
  setupSocket,
  getIO,
  emitOrderNew,
  emitOrderStatusChanged,
  emitInventoryAlert,
};
