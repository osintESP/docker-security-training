# Kubernetes Deployment Guide

Guia para desplegar la aplicacion en Kubernetes con configuraciones de seguridad.

## Prerequisitos

- kubectl >= 1.28
- Minikube >= 1.32 (para desarrollo local) o cluster Kubernetes
- Docker (para construir imagenes)

## Arquitectura en Kubernetes

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            NAMESPACE: secure-app                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                          NETWORK POLICIES                                ││
│  │  ┌──────────────┐     ┌──────────────┐     ┌──────────────────────────┐ ││
│  │  │   Frontend   │────▶│     API      │────▶│       PostgreSQL         │ ││
│  │  │  Deployment  │     │  Deployment  │     │       Deployment         │ ││
│  │  │  (2 replicas)│     │ (2 replicas) │     │       (1 replica)        │ ││
│  │  └──────┬───────┘     └──────┬───────┘     └────────────┬─────────────┘ ││
│  │         │                    │                          │               ││
│  │  ┌──────▼───────┐     ┌──────▼───────┐     ┌────────────▼─────────────┐ ││
│  │  │   Service    │     │   Service    │     │         Service          │ ││
│  │  │   NodePort   │     │   NodePort   │     │        ClusterIP         │ ││
│  │  │   :30080     │     │   :30001     │     │         :5432            │ ││
│  │  └──────────────┘     └──────────────┘     └──────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │   ConfigMap     │  │     Secret      │  │      PVC        │              │
│  │   (app-config)  │  │ (db-credentials)│  │  (postgres-pvc) │              │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Caracteristicas de Seguridad

- **Namespace aislado**: Todos los recursos en namespace dedicado
- **RBAC**: ServiceAccounts con permisos minimos
- **Network Policies**: Trafico restringido entre servicios
- **Security Contexts**: runAsNonRoot, readOnlyRootFilesystem
- **Resource Limits**: CPU y memoria limitados
- **Secrets**: Credenciales en objetos Secret (base64)

## Inicio Rapido con Minikube

### 1. Iniciar Minikube

```bash
# Iniciar minikube con recursos suficientes
minikube start --cpus=4 --memory=4096 --driver=docker

# Habilitar addons necesarios
minikube addons enable ingress
minikube addons enable metrics-server
```

### 2. Construir imagenes en Minikube

```bash
# Configurar Docker para usar el daemon de Minikube
eval $(minikube docker-env)

# Construir imagenes (desde el directorio raiz del proyecto)
docker build -t secure-frontend:1.0.0 ./frontend
docker build -t secure-api:1.0.0 ./api
docker build -t secure-database:1.0.0 ./database

# Verificar imagenes
docker images | grep secure
```

### 3. Aplicar manifiestos

**IMPORTANTE**: Aplicar en este orden para respetar dependencias.

```bash
# 1. Crear namespace
kubectl apply -f namespace.yaml

# 2. Aplicar RBAC
kubectl apply -f rbac.yaml

# 3. Aplicar ConfigMap y Secret
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# 4. Aplicar Network Policies
kubectl apply -f networkpolicy.yaml

# 5. Desplegar PostgreSQL
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Esperar a que PostgreSQL este listo
kubectl wait --for=condition=ready pod -l app=postgres -n secure-app --timeout=120s

# 6. Desplegar API
kubectl apply -f api-deployment.yaml
kubectl apply -f api-service.yaml

# Esperar a que API este lista
kubectl wait --for=condition=ready pod -l app=api -n secure-app --timeout=120s

# 7. Desplegar Frontend
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
```

### Script de despliegue completo

```bash
#!/bin/bash
# deploy.sh - Ejecutar desde el directorio k8s/

echo "Desplegando aplicacion en Kubernetes..."

kubectl apply -f namespace.yaml
kubectl apply -f rbac.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f networkpolicy.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

echo "Esperando PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n secure-app --timeout=120s

kubectl apply -f api-deployment.yaml
kubectl apply -f api-service.yaml

echo "Esperando API..."
kubectl wait --for=condition=ready pod -l app=api -n secure-app --timeout=120s

kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

echo "Despliegue completado!"
kubectl get pods -n secure-app
```

## Verificacion del Deployment

### Estado de los pods

```bash
# Ver todos los recursos del namespace
kubectl get all -n secure-app

# Ver pods con mas detalle
kubectl get pods -n secure-app -o wide

# Descripcion detallada de un pod
kubectl describe pod -l app=api -n secure-app
```

### Acceder a la aplicacion

```bash
# Obtener URL del frontend (Minikube)
minikube service frontend-service-external -n secure-app --url

# Obtener URL de la API (Minikube)
minikube service api-service-external -n secure-app --url

# O usar port-forward
kubectl port-forward svc/frontend-service 8080:8080 -n secure-app
kubectl port-forward svc/api-service 3001:3001 -n secure-app
```

### Verificar health checks

```bash
# Health check de la API
API_URL=$(minikube service api-service-external -n secure-app --url)
curl $API_URL/health
curl $API_URL/version
curl $API_URL/api/items
```

### Ver logs

```bash
# Logs de todos los pods de la API
kubectl logs -l app=api -n secure-app

# Logs en tiempo real
kubectl logs -l app=api -n secure-app -f

# Logs de un pod especifico
kubectl logs <pod-name> -n secure-app
```

## Comandos de Administracion

### Escalar deployments

```bash
# Escalar API a 3 replicas
kubectl scale deployment api --replicas=3 -n secure-app

# Ver estado del escalado
kubectl get pods -l app=api -n secure-app -w
```

### Actualizar deployment

```bash
# Actualizar imagen
kubectl set image deployment/api api=secure-api:1.1.0 -n secure-app

# Ver estado del rollout
kubectl rollout status deployment/api -n secure-app

# Rollback si es necesario
kubectl rollout undo deployment/api -n secure-app
```

### Ejecutar comandos en pods

```bash
# Shell en pod de la API
kubectl exec -it deployment/api -n secure-app -- sh

# Ejecutar comando en PostgreSQL
kubectl exec -it deployment/postgres -n secure-app -- psql -U appuser -d secureapp
```

## Troubleshooting

### Pod no inicia

```bash
# Ver eventos del pod
kubectl describe pod <pod-name> -n secure-app

# Ver eventos del namespace
kubectl get events -n secure-app --sort-by='.lastTimestamp'
```

### Errores de imagen

```bash
# Verificar que la imagen existe en Minikube
eval $(minikube docker-env)
docker images | grep secure

# Ver si hay error de pull
kubectl describe pod -l app=api -n secure-app | grep -A5 "Events"
```

### Problemas de conexion a base de datos

```bash
# Verificar que PostgreSQL esta corriendo
kubectl get pods -l app=postgres -n secure-app

# Ver logs de PostgreSQL
kubectl logs -l app=postgres -n secure-app

# Probar conectividad desde API
kubectl exec -it deployment/api -n secure-app -- sh -c 'nc -zv postgres-service 5432'
```

### Network Policies bloqueando trafico

```bash
# Verificar network policies
kubectl get networkpolicies -n secure-app

# Describir policy especifica
kubectl describe networkpolicy api-network-policy -n secure-app

# Temporalmente deshabilitar policies para debug
kubectl delete -f networkpolicy.yaml
```

### Verificar RBAC

```bash
# Ver ServiceAccounts
kubectl get serviceaccounts -n secure-app

# Ver Roles y RoleBindings
kubectl get roles,rolebindings -n secure-app

# Verificar permisos
kubectl auth can-i list pods --as=system:serviceaccount:secure-app:api-service-account -n secure-app
```

## Limpieza

```bash
# Eliminar todos los recursos del namespace
kubectl delete namespace secure-app

# O eliminar recursos individualmente
kubectl delete -f . -n secure-app
```

## Siguiente Pasos (Produccion)

1. **Ingress Controller**: Configurar Ingress para acceso HTTP/HTTPS
2. **Cert-Manager**: Certificados TLS automaticos
3. **External Secrets**: Integracion con Vault o AWS Secrets Manager
4. **Monitoring**: Prometheus + Grafana
5. **Logging**: EFK Stack (Elasticsearch, Fluentd, Kibana)
6. **Pod Disruption Budgets**: Alta disponibilidad
7. **Horizontal Pod Autoscaler**: Escalado automatico
