# Paludi - Arquitectura del Sistema

## Visión General

Sistema integral para cafetería tipo Starbucks. MVP para 1 local con capacidad de escalar.

## Stack Tecnológico

| Capa | Tecnología | Justificación |
|------|-----------|---------------|
| **Backend API** | Node.js 20 + Express | Rendimiento, ecosistema amplio, real-time con Socket.IO |
| **Frontend POS** | React 18 + Vite | UI rápida para baristas, builds optimizados |
| **Frontend PWA** | React 18 + Vite (PWA) | Pedidos desde celular sin instalar app nativa |
| **Admin Dashboard** | React 18 + Vite | Métricas y gestión de inventario |
| **Base de datos** | PostgreSQL 16 | Relacional, ACID, ideal para transacciones y stock |
| **Cache/Sesiones** | Redis 7 | Sesiones JWT, cache de menú, cola de órdenes |
| **Real-time** | Socket.IO | Estado de órdenes en tiempo real (POS ↔ Cliente) |
| **Auth** | JWT + bcrypt | Stateless, escalable |
| **Contenedores** | Docker + Docker Compose | Consistencia dev/prod, orquestación |

## Arquitectura de Microservicios

```
                    ┌─────────────────┐
                    │   Nginx Proxy   │
                    │   (puerto 80)   │
                    └────────┬────────┘
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │  POS App   │  │  PWA App   │  │   Admin    │
     │  :3001     │  │  :3002     │  │  :3003     │
     └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
           │               │               │
           └───────────────┼───────────────┘
                           ▼
                 ┌───────────────────┐
                 │    API Backend    │
                 │    :4000         │
                 │  (Express +      │
                 │   Socket.IO)     │
                 └──┬───────────┬───┘
                    ▼           ▼
            ┌───────────┐ ┌─────────┐
            │ PostgreSQL│ │  Redis  │
            │  :5432    │ │  :6379  │
            └───────────┘ └─────────┘
```

## Módulos del Sistema

### 1. POS (Point of Sale) - Interfaz Barista
- Tomar pedidos presenciales
- Visualizar cola de pedidos entrantes (móvil + presencial)
- Marcar pedidos como: preparando → listo → entregado
- Cobrar (efectivo/tarjeta - integración futura)
- Vista optimizada para tablet/pantalla táctil

### 2. PWA (Progressive Web App) - Cliente
- Ver menú con categorías, precios y fotos
- Personalizar bebida (tamaño, leche, extras)
- Realizar pedido y pagar (integración futura)
- Seguir estado del pedido en tiempo real
- Historial de pedidos

### 3. Inventario
- CRUD de productos e ingredientes
- Stock actual con alertas de bajo nivel
- Registro de movimientos (entrada/salida)
- Relación producto → ingredientes (receta)
- Descuento automático de stock al vender

### 4. Dashboard Analytics
- Ventas del día/semana/mes
- Productos más vendidos (ranking)
- Ingresos por período
- Horas pico de venta
- Gráficos interactivos (Chart.js)

## Modelo de Datos (PostgreSQL)

### Tablas principales:

```sql
-- Usuarios del sistema (baristas, admin)
users: id, email, password_hash, name, role, active, created_at

-- Categorías de productos (Café, Té, Frappé, Snacks...)
categories: id, name, description, display_order, active

-- Productos del menú
products: id, category_id, name, description, base_price, image_url, available, created_at

-- Tamaños disponibles
sizes: id, name, multiplier (e.g., Tall=1.0, Grande=1.25, Venti=1.5)

-- Extras/personalizaciones
extras: id, name, price, category, available

-- Ingredientes para inventario
ingredients: id, name, unit, current_stock, min_stock, cost_per_unit

-- Receta: producto → ingredientes
product_ingredients: product_id, ingredient_id, quantity_per_unit

-- Órdenes
orders: id, customer_name, order_number, channel (pos/mobile),
        status (pending/preparing/ready/delivered/cancelled),
        subtotal, tax, total, created_at, updated_at

-- Detalle de cada orden
order_items: id, order_id, product_id, size_id, quantity, unit_price, notes

-- Extras por item
order_item_extras: order_item_id, extra_id, price

-- Movimientos de inventario
inventory_movements: id, ingredient_id, type (in/out/adjustment),
                     quantity, reference, created_at, user_id
```

## Endpoints API (REST)

### Auth
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `GET  /api/auth/me` - Usuario actual

### Products
- `GET    /api/products` - Listar productos (con categoría)
- `GET    /api/products/:id` - Detalle de producto
- `POST   /api/products` - Crear producto (admin)
- `PUT    /api/products/:id` - Actualizar (admin)
- `DELETE /api/products/:id` - Desactivar (admin)

### Categories
- `GET    /api/categories` - Listar categorías
- `POST   /api/categories` - Crear (admin)

### Orders
- `POST   /api/orders` - Crear orden (POS o móvil)
- `GET    /api/orders` - Listar órdenes (filtros: status, fecha, channel)
- `GET    /api/orders/:id` - Detalle de orden
- `PATCH  /api/orders/:id/status` - Cambiar estado
- `GET    /api/orders/queue` - Cola activa (pending + preparing)

### Sizes & Extras
- `GET /api/sizes` - Listar tamaños
- `GET /api/extras` - Listar extras

### Inventory
- `GET    /api/inventory` - Stock actual
- `POST   /api/inventory/movement` - Registrar movimiento
- `GET    /api/inventory/alerts` - Ingredientes bajo mínimo

### Analytics
- `GET /api/analytics/sales` - Ventas por período
- `GET /api/analytics/top-products` - Productos más vendidos
- `GET /api/analytics/revenue` - Ingresos
- `GET /api/analytics/peak-hours` - Horas pico

### WebSocket Events (Socket.IO)
- `order:new` - Nueva orden creada
- `order:status-changed` - Estado de orden actualizado
- `inventory:alert` - Alerta de stock bajo

## Estructura del Proyecto

```
paludi/
├── ARCHITECTURE.md
├── docker-compose.yml
├── .env.example
├── nginx/
│   └── nginx.conf
├── services/
│   ├── api/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── src/
│   │       ├── server.js
│   │       ├── config/
│   │       │   └── database.js
│   │       ├── middleware/
│   │       │   ├── auth.js
│   │       │   └── errorHandler.js
│   │       ├── routes/
│   │       │   ├── auth.js
│   │       │   ├── products.js
│   │       │   ├── categories.js
│   │       │   ├── orders.js
│   │       │   ├── inventory.js
│   │       │   └── analytics.js
│   │       ├── models/
│   │       │   └── index.js
│   │       └── socket/
│   │           └── index.js
│   ├── pos/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── index.html
│   │   ├── vite.config.js
│   │   └── src/
│   │       ├── main.jsx
│   │       ├── App.jsx
│   │       ├── components/
│   │       ├── pages/
│   │       └── services/
│   ├── mobile/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── index.html
│   │   ├── vite.config.js
│   │   ├── vite-pwa.config.js
│   │   └── src/
│   │       ├── main.jsx
│   │       ├── App.jsx
│   │       ├── components/
│   │       ├── pages/
│   │       └── services/
│   ├── admin/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── index.html
│   │   ├── vite.config.js
│   │   └── src/
│   │       ├── main.jsx
│   │       ├── App.jsx
│   │       ├── components/
│   │       ├── pages/
│   │       └── services/
│   └── database/
│       ├── Dockerfile
│       └── init/
│           ├── 01-schema.sql
│           └── 02-seed.sql
└── scripts/
    ├── build.sh
    └── dev.sh
```

## Seguridad (aplicada desde el MVP)

- JWT con expiración y refresh tokens
- Passwords hasheados con bcrypt (salt rounds: 12)
- Helmet.js para headers de seguridad
- Rate limiting en endpoints de auth
- CORS configurado por origen
- Variables sensibles en .env (nunca hardcodeadas)
- Contenedores non-root
- Docker multi-stage builds
- Validación de input con express-validator

## Plan de Ejecución Paralela (Agentes Sonnet)

### Fase 1 - Infraestructura (4 agentes en paralelo)
1. **Agent-DB**: Esquema SQL completo + seed data
2. **Agent-Docker**: Dockerfiles + docker-compose.yml + nginx.conf + scripts
3. **Agent-API-Core**: Scaffolding API (server.js, config, middleware, auth)
4. **Agent-Frontend-Scaffold**: Scaffolding de las 3 apps React

### Fase 2 - Lógica de negocio (4 agentes en paralelo)
5. **Agent-API-Orders**: Rutas de productos, órdenes + Socket.IO
6. **Agent-API-Inventory**: Rutas de inventario + analytics
7. **Agent-POS-UI**: Interfaz completa del POS
8. **Agent-Mobile-UI**: Interfaz completa de la PWA

### Fase 3 - Dashboard + Integración (2 agentes en paralelo)
9. **Agent-Admin-UI**: Dashboard de analytics e inventario
10. **Agent-Integration**: Verificación, ajustes, documentación
