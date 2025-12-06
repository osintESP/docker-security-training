# Networking: Docker Compose vs Kubernetes

## Resumen de Puertos

### Docker Compose
- **Frontend**: `localhost:8080`
- **API**: `localhost:3001`
- **Database**: `localhost:5432`

### Kubernetes (Minikube)
- **Frontend**: `172.17.0.2:30080` (NodePort)
- **API**: `172.17.0.2:30001` (NodePort)
- **Database**: Interno (ClusterIP) - no accesible desde fuera

## Diferencias de Networking

| Aspecto | Docker Compose | Kubernetes (Minikube) |
|---------|----------------|----------------------|
| **Networking** | Bridge network local | Cluster network interno |
| **Frontend Port** | 8080 | 30080 (NodePort) |
| **API Port** | 3001 | 30001 (NodePort) |
| **DB Access** | localhost:5432 | Solo dentro del cluster |
| **CORS Origin** | http://localhost:8080 | * (para desarrollo) |
| **API URL** | http://localhost:3001 | http://172.17.0.2:30001 |

## Cómo Evitar Colisiones

### ✅ NO HAY COLISIÓN de Puertos

Ambos entornos usan **diferentes puertos** por diseño:
- Docker Compose: `8080`, `3001`, `5432` en `localhost`
- Kubernetes: `30080`, `30001` en IP de Minikube (`172.17.0.2`)

Sin embargo, Docker Compose usa los puertos estándar que **pueden colisionar** si intentas correr ambos simultáneamente.

### Regla de Oro

**NUNCA correr Docker Compose y Kubernetes al mismo tiempo en este proyecto.**

## Instrucciones de Cambio

### De Docker Compose a Kubernetes

```bash
# 1. Detener Docker Compose
cd ejercicio-final
docker compose down

# 2. Iniciar Kubernetes (ver k8s/README.md para guía completa)
cd k8s
kubectl apply -f namespace.yaml
# ... (ver README.md para secuencia completa)
```

### De Kubernetes a Docker Compose

```bash
# 1. Detener Kubernetes
kubectl delete namespace secure-app

# 2. Iniciar Docker Compose
cd ejercicio-final
docker compose up -d
```

## Configuraciones Específicas

### Docker Compose
- API CORS via `.env`: `CORS_ORIGIN=http://localhost:8080`
- Frontend API URL: `http://localhost:3001` (default)

### Kubernetes
- API CORS via ConfigMap: `CORS_ORIGIN: "*"`
- Frontend API URL: `http://172.17.0.2:30001` (hardcoded en build)
