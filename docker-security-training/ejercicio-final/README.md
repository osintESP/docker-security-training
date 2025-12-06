# Docker Security Training - Proyecto Final

Aplicacion containerizada de 3 capas con las mejores practicas de seguridad Docker.

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DOCKER NETWORK                               │
│  ┌──────────────────┐    ┌──────────────────┐    ┌────────────────┐ │
│  │     FRONTEND     │    │       API        │    │   DATABASE     │ │
│  │   (React/Nginx)  │───▶│  (Node/Express)  │───▶│  (PostgreSQL)  │ │
│  │   Port: 8080     │    │   Port: 3001     │    │   Port: 5432   │ │
│  │   Alpine Linux   │    │   Alpine Linux   │    │  Alpine Linux  │ │
│  │   Non-root user  │    │   Non-root user  │    │  postgres user │ │
│  └──────────────────┘    └──────────────────┘    └────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Caracteristicas de Seguridad Implementadas

| Caracteristica | Frontend | API | Database |
|----------------|----------|-----|----------|
| Multi-stage build | ✅ | ✅ | N/A |
| Imagen Alpine | ✅ | ✅ | ✅ |
| Version pineada | ✅ | ✅ | ✅ |
| Usuario non-root | ✅ | ✅ | ✅ |
| Health checks | ✅ | ✅ | ✅ |
| Read-only FS | ✅ | ✅ | N/A |
| No secrets hardcoded | ✅ | ✅ | ✅ |
| Labels OCI | ✅ | ✅ | ✅ |
| .dockerignore | ✅ | ✅ | ✅ |
| Resource limits | ✅ | ✅ | ✅ |

## Prerequisitos

- Docker >= 24.0
- Docker Compose >= 2.20
- (Opcional) Trivy para escaneo de vulnerabilidades

## Quick Start con Docker Compose

### 1. Clonar y configurar

```bash
cd ejercicio-final

# Crear archivo de variables de entorno
cp .env.example .env

# Editar .env con credenciales seguras (IMPORTANTE en produccion)
nano .env
```

### 2. Construir imagenes

```bash
# Construir todas las imagenes
sudo docker compose build

# O usar el script
chmod +x scripts/build.sh
sudo ./scripts/build.sh
```

### 3. Iniciar servicios

```bash
# Iniciar todos los servicios
sudo docker compose up -d

# Ver logs
sudo docker compose logs -f

# Verificar estado
sudo docker compose ps
```

### 4. Verificar aplicacion

```bash
# Health check de la API
curl http://localhost:3001/health

# Version de la API
curl http://localhost:3001/version

# Listar items
curl http://localhost:3001/api/items

# Crear item
curl -X POST http://localhost:3001/api/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Item", "description": "Descripcion de prueba"}'

# Frontend
open http://localhost:8080
```

### 5. Detener servicios

```bash
sudo docker compose down

# Con eliminacion de volumenes (CUIDADO: elimina datos)
sudo docker compose down -v
```

## Escaneo de Seguridad con Trivy

### Instalar Trivy

```bash
# Ubuntu/Debian
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# macOS
brew install trivy
```

### Escanear imagenes

```bash
# Escanear imagen individual
trivy image secure-frontend:1.0.0
trivy image secure-api:1.0.0
trivy image secure-database:1.0.0

# Escanear con nivel de severidad
trivy image --severity HIGH,CRITICAL secure-api:1.0.0

# Usar script de escaneo
chmod +x scripts/scan.sh
./scripts/scan.sh
```

## Estructura del Proyecto

```
ejercicio-final/
├── frontend/
│   ├── Dockerfile          # Multi-stage build con Nginx Alpine
│   ├── nginx.conf          # Configuracion Nginx hardened
│   ├── .dockerignore
│   ├── package.json
│   ├── public/
│   │   └── index.html
│   └── src/
│       ├── App.js
│       └── index.js
├── api/
│   ├── Dockerfile          # Multi-stage build con Node Alpine
│   ├── .dockerignore
│   ├── package.json
│   └── src/
│       └── server.js
├── database/
│   ├── Dockerfile          # PostgreSQL Alpine
│   ├── .dockerignore
│   └── init/
│       └── 01-init-schema.sql
├── k8s/                    # Manifiestos Kubernetes
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── rbac.yaml
│   ├── networkpolicy.yaml
│   ├── postgres-*.yaml
│   ├── api-*.yaml
│   └── frontend-*.yaml
├── scripts/
│   ├── build.sh            # Script de construccion
│   └── scan.sh             # Script de escaneo Trivy
├── docker-compose.yml
├── .env.example
├── .gitignore
└── README.md
```

## Comandos Utiles

### Docker

```bash
# Ver imagenes construidas
sudo docker images | grep secure

# Ver contenedores en ejecucion
sudo docker ps

# Inspeccionar configuracion de seguridad
sudo docker inspect secure-api | jq '.[0].Config.User'

# Ver logs de un servicio
sudo docker compose logs api -f

# Ejecutar comando en contenedor
sudo docker compose exec api sh

# Estadisticas de recursos
sudo docker stats
```

### Build y Push a Registry

```bash
# Tagear imagenes para registry
sudo docker tag secure-frontend:1.0.0 myregistry.com/secure-frontend:1.0.0
sudo docker tag secure-api:1.0.0 myregistry.com/secure-api:1.0.0
sudo docker tag secure-database:1.0.0 myregistry.com/secure-database:1.0.0

# Push a registry
sudo docker push myregistry.com/secure-frontend:1.0.0
sudo docker push myregistry.com/secure-api:1.0.0
sudo docker push myregistry.com/secure-database:1.0.0
```

## Seguridad en Docker Compose

El archivo `docker-compose.yml` implementa:

1. **Redes aisladas**: Frontend y backend en redes separadas
2. **Resource limits**: CPU y memoria limitados
3. **Read-only filesystem**: Donde es posible
4. **No new privileges**: Previene escalada de privilegios
5. **Health checks**: Monitoreo de salud de servicios
6. **Restart policies**: Recuperacion automatica
7. **Logging limitado**: Rotacion de logs

## Despliegue en Kubernetes

Ver documentacion en [k8s/README.md](k8s/README.md)

## Troubleshooting

### La base de datos no inicia

```bash
# Verificar logs
sudo docker compose logs database

# Verificar permisos del volumen
sudo docker volume inspect secure-app-postgres-data
```

### La API no conecta a la base de datos

```bash
# Verificar conectividad
sudo docker compose exec api ping database

# Verificar variables de entorno
sudo docker compose exec api env | grep DB_
```

### Error de permisos en nginx

```bash
# Verificar usuario
sudo docker compose exec frontend id

# Verificar permisos de archivos
sudo docker compose exec frontend ls -la /usr/share/nginx/html
```

## Referencias

- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Container Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
