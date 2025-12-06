#!/bin/bash
# =============================================================================
# SCAN SCRIPT - Escanea imagenes Docker con Trivy
# =============================================================================
# Uso: ./scripts/scan.sh [--severity LEVEL] [--format FORMAT]
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuracion por defecto
SEVERITY="HIGH,CRITICAL"
FORMAT="table"
VERSION="${VERSION:-1.0.0}"

# Imagenes a escanear
IMAGES=(
    "secure-frontend:${VERSION}"
    "secure-api:${VERSION}"
    "secure-database:${VERSION}"
)

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --severity)
            SEVERITY="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --all)
            SEVERITY="UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL"
            shift
            ;;
        -h|--help)
            echo "Uso: $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  --severity LEVEL  Niveles de severidad (default: HIGH,CRITICAL)"
            echo "  --format FORMAT   Formato de salida: table, json, sarif (default: table)"
            echo "  --all            Mostrar todas las vulnerabilidades"
            echo "  -h, --help       Mostrar esta ayuda"
            exit 0
            ;;
        *)
            echo -e "${RED}Argumento desconocido: $1${NC}"
            exit 1
            ;;
    esac
done

# Verificar que Trivy esta instalado
if ! command -v trivy &> /dev/null; then
    echo -e "${RED}Error: Trivy no esta instalado${NC}"
    echo ""
    echo "Instalar Trivy:"
    echo "  Ubuntu/Debian: sudo apt-get install trivy"
    echo "  macOS: brew install trivy"
    echo "  Docker: docker run aquasec/trivy image <image>"
    echo ""
    echo "Mas info: https://aquasecurity.github.io/trivy/"
    exit 1
fi

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  Docker Security Training - Security Scanner${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""
echo -e "${YELLOW}Trivy version: $(trivy --version | head -1)${NC}"
echo -e "${YELLOW}Severidad: ${SEVERITY}${NC}"
echo -e "${YELLOW}Formato: ${FORMAT}${NC}"
echo ""

# Actualizar base de datos de vulnerabilidades
echo -e "${YELLOW}Actualizando base de datos de vulnerabilidades...${NC}"
trivy image --download-db-only 2>/dev/null || true
echo ""

# Contador de vulnerabilidades
TOTAL_VULNS=0
declare -A IMAGE_VULNS

# Escanear cada imagen
for image in "${IMAGES[@]}"; do
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}Escaneando: ${image}${NC}"
    echo -e "${BLUE}=================================================${NC}"

    # Verificar que la imagen existe
    if ! docker image inspect "$image" &> /dev/null; then
        echo -e "${YELLOW}⚠ Imagen no encontrada: ${image}${NC}"
        echo -e "${YELLOW}  Ejecuta primero: ./scripts/build.sh${NC}"
        echo ""
        continue
    fi

    # Escanear imagen
    if [ "$FORMAT" == "table" ]; then
        trivy image \
            --severity "$SEVERITY" \
            --format table \
            "$image"

        # Contar vulnerabilidades
        VULN_COUNT=$(trivy image --severity "$SEVERITY" --format json "$image" 2>/dev/null | \
            jq '[.Results[]?.Vulnerabilities // [] | length] | add // 0')
        IMAGE_VULNS["$image"]=$VULN_COUNT
        TOTAL_VULNS=$((TOTAL_VULNS + VULN_COUNT))
    else
        trivy image \
            --severity "$SEVERITY" \
            --format "$FORMAT" \
            "$image"
    fi

    echo ""
done

# Resumen
echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  RESUMEN DE ESCANEO${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

for image in "${IMAGES[@]}"; do
    if docker image inspect "$image" &> /dev/null; then
        count=${IMAGE_VULNS["$image"]:-0}
        if [ "$count" -eq 0 ]; then
            echo -e "${GREEN}✓ ${image}: Sin vulnerabilidades ${SEVERITY}${NC}"
        else
            echo -e "${RED}✗ ${image}: ${count} vulnerabilidades ${SEVERITY}${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ ${image}: No escaneada (imagen no encontrada)${NC}"
    fi
done

echo ""
echo -e "${BLUE}=================================================${NC}"

if [ "$TOTAL_VULNS" -eq 0 ]; then
    echo -e "${GREEN}✓ Total: Sin vulnerabilidades ${SEVERITY} detectadas${NC}"
    exit 0
else
    echo -e "${RED}✗ Total: ${TOTAL_VULNS} vulnerabilidades ${SEVERITY} detectadas${NC}"
    echo ""
    echo -e "${YELLOW}Recomendaciones:${NC}"
    echo -e "  1. Actualizar imagenes base a versiones mas recientes"
    echo -e "  2. Actualizar dependencias de la aplicacion"
    echo -e "  3. Revisar vulnerabilidades individuales con:"
    echo -e "     trivy image --severity CRITICAL <imagen>"
    exit 1
fi
