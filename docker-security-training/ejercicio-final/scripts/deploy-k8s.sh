#!/bin/bash
# =============================================================================
# KUBERNETES DEPLOY SCRIPT
# =============================================================================
# Uso: ./scripts/deploy-k8s.sh [--minikube] [--delete]
# =============================================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MINIKUBE=false
DELETE=false

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --minikube)
            MINIKUBE=true
            shift
            ;;
        --delete)
            DELETE=true
            shift
            ;;
        *)
            echo -e "${RED}Argumento desconocido: $1${NC}"
            exit 1
            ;;
    esac
done

# Directorio base
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S_DIR="${BASE_DIR}/k8s"

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Docker Security Training - Kubernetes Deploy${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Eliminar recursos si se solicito
if [ "$DELETE" = true ]; then
    echo -e "${YELLOW}Eliminando recursos...${NC}"
    kubectl delete namespace secure-app --ignore-not-found=true
    echo -e "${GREEN}Recursos eliminados${NC}"
    exit 0
fi

# Configurar para Minikube si se especifico
if [ "$MINIKUBE" = true ]; then
    echo -e "${YELLOW}Configurando para Minikube...${NC}"

    # Verificar que minikube esta corriendo
    if ! minikube status &> /dev/null; then
        echo -e "${RED}Minikube no esta corriendo. Iniciando...${NC}"
        minikube start --cpus=4 --memory=4096
    fi

    # Usar Docker daemon de Minikube
    eval $(minikube docker-env)

    # Construir imagenes
    echo -e "${YELLOW}Construyendo imagenes en Minikube...${NC}"
    docker build -t secure-database:1.0.0 "${BASE_DIR}/database"
    docker build -t secure-api:1.0.0 "${BASE_DIR}/api"
    docker build -t secure-frontend:1.0.0 "${BASE_DIR}/frontend"
fi

# Aplicar manifiestos en orden
echo -e "${YELLOW}Aplicando manifiestos...${NC}"
echo ""

echo -e "${BLUE}1. Creando namespace...${NC}"
kubectl apply -f "${K8S_DIR}/namespace.yaml"

echo -e "${BLUE}2. Aplicando RBAC...${NC}"
kubectl apply -f "${K8S_DIR}/rbac.yaml"

echo -e "${BLUE}3. Aplicando ConfigMap y Secret...${NC}"
kubectl apply -f "${K8S_DIR}/configmap.yaml"
kubectl apply -f "${K8S_DIR}/secret.yaml"

echo -e "${BLUE}4. Aplicando Network Policies...${NC}"
kubectl apply -f "${K8S_DIR}/networkpolicy.yaml"

echo -e "${BLUE}5. Desplegando PostgreSQL...${NC}"
kubectl apply -f "${K8S_DIR}/postgres-pvc.yaml"
kubectl apply -f "${K8S_DIR}/postgres-deployment.yaml"
kubectl apply -f "${K8S_DIR}/postgres-service.yaml"

echo -e "${YELLOW}Esperando PostgreSQL...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n secure-app --timeout=120s

echo -e "${BLUE}6. Desplegando API...${NC}"
kubectl apply -f "${K8S_DIR}/api-deployment.yaml"
kubectl apply -f "${K8S_DIR}/api-service.yaml"

echo -e "${YELLOW}Esperando API...${NC}"
kubectl wait --for=condition=ready pod -l app=api -n secure-app --timeout=120s

echo -e "${BLUE}7. Desplegando Frontend...${NC}"
kubectl apply -f "${K8S_DIR}/frontend-deployment.yaml"
kubectl apply -f "${K8S_DIR}/frontend-service.yaml"

echo -e "${YELLOW}Esperando Frontend...${NC}"
kubectl wait --for=condition=ready pod -l app=frontend -n secure-app --timeout=120s

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  Despliegue completado!${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""

# Mostrar estado
kubectl get all -n secure-app

echo ""
echo -e "${YELLOW}Para acceder a la aplicacion:${NC}"

if [ "$MINIKUBE" = true ]; then
    echo -e "  Frontend: $(minikube service frontend-service-external -n secure-app --url 2>/dev/null || echo 'minikube service frontend-service-external -n secure-app')"
    echo -e "  API: $(minikube service api-service-external -n secure-app --url 2>/dev/null || echo 'minikube service api-service-external -n secure-app')"
else
    echo -e "  kubectl port-forward svc/frontend-service 8080:8080 -n secure-app"
    echo -e "  kubectl port-forward svc/api-service 3001:3001 -n secure-app"
fi
