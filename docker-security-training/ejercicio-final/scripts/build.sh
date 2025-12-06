#!/bin/bash
# =============================================================================
# BUILD SCRIPT - Construye todas las imagenes Docker
# =============================================================================
# Uso: ./scripts/build.sh [--no-cache] [--push REGISTRY]
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuracion
VERSION="${VERSION:-1.0.0}"
NO_CACHE=""
REGISTRY=""

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --push)
            REGISTRY="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Argumento desconocido: $1${NC}"
            exit 1
            ;;
    esac
done

# Directorio base (un nivel arriba de scripts/)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR"

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Docker Security Training - Build Script${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""
echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo -e "${YELLOW}Directorio: ${BASE_DIR}${NC}"
echo ""

# Funcion para construir imagen
build_image() {
    local name=$1
    local context=$2
    local dockerfile=$3

    echo -e "${YELLOW}Construyendo ${name}:${VERSION}...${NC}"

    docker build \
        ${NO_CACHE} \
        -t "${name}:${VERSION}" \
        -t "${name}:latest" \
        -f "${dockerfile}" \
        "${context}"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${name}:${VERSION} construida exitosamente${NC}"
    else
        echo -e "${RED}✗ Error construyendo ${name}${NC}"
        exit 1
    fi
    echo ""
}

# Construir imagenes
echo -e "${BLUE}Construyendo imagenes...${NC}"
echo ""

build_image "secure-database" "./database" "./database/Dockerfile"
build_image "secure-api" "./api" "./api/Dockerfile"
build_image "secure-frontend" "./frontend" "./frontend/Dockerfile"

# Mostrar imagenes construidas
echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}Imagenes construidas:${NC}"
echo -e "${BLUE}=================================================${NC}"
docker images | grep -E "^secure-" | head -10

# Push a registry si se especifico
if [ -n "$REGISTRY" ]; then
    echo ""
    echo -e "${YELLOW}Pushing imagenes a ${REGISTRY}...${NC}"

    for img in secure-database secure-api secure-frontend; do
        echo -e "${YELLOW}Tagging ${img}...${NC}"
        docker tag "${img}:${VERSION}" "${REGISTRY}/${img}:${VERSION}"
        docker tag "${img}:latest" "${REGISTRY}/${img}:latest"

        echo -e "${YELLOW}Pushing ${REGISTRY}/${img}:${VERSION}...${NC}"
        docker push "${REGISTRY}/${img}:${VERSION}"
        docker push "${REGISTRY}/${img}:latest"

        echo -e "${GREEN}✓ ${img} pushed${NC}"
    done
fi

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  Build completado exitosamente!${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""
echo -e "Siguiente paso: ${YELLOW}docker compose up -d${NC}"
