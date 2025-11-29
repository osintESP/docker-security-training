#!/bin/bash
set -e

echo "🔐 Ejercicio 11: Post-Quantum Cryptography Lab"
echo "================================================"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "Dockerfile" ]; then
    echo "❌ Error: Ejecuta este script desde el directorio ejercicio-11-hybrid"
    exit 1
fi

# 1. Generar certificados si no existen
if [ ! -d "certs" ] || [ ! -f "certs/server.crt" ]; then
    echo "📝 Generando certificados ECDSA..."
    sudo ./generate_certs.sh
    echo ""
else
    echo "✅ Certificados ya existen (saltando generación)"
    echo ""
fi

# 2. Detener contenedor anterior si existe
if sudo docker ps -a | grep -q pqc-hybrid; then
    echo "🛑 Deteniendo contenedor anterior..."
    sudo docker stop pqc-hybrid 2>/dev/null || true
    sudo docker rm pqc-hybrid 2>/dev/null || true
    echo ""
fi

# 3. Construir imagen
echo "🏗️  Construyendo imagen Docker..."
sudo docker build -t pqc-hybrid . -q
echo "✅ Imagen construida"
echo ""

# 4. Ejecutar contenedor
echo "🚀 Iniciando contenedor..."
sudo docker run -d -p 4434:4433 --name pqc-hybrid pqc-hybrid
echo ""

# 5. Esperar un momento para que nginx inicie
echo "⏳ Esperando 2 segundos..."
sleep 2
echo ""

# 6. Verificar que está corriendo
if sudo docker ps | grep -q pqc-hybrid; then
    echo "✅ ¡Contenedor corriendo exitosamente!"
    echo ""
    echo "📊 Estado del contenedor:"
    sudo docker ps | grep pqc-hybrid
    echo ""
    echo "🌐 Abre Chrome y navega a:"
    echo ""
    echo "    https://localhost:4434"
    echo ""
    echo "📝 Para verificar Post-Quantum Cryptography:"
    echo "   1. Presiona F12 (DevTools)"
    echo "   2. Ve a la pestaña 'Security'"
    echo "   3. Busca 'Connection' - debería mostrar: X25519MLKEM768"
    echo ""
    echo "📋 Comandos útiles:"
    echo "   Ver logs:     sudo docker logs pqc-hybrid"
    echo "   Detener:      sudo docker stop pqc-hybrid"
    echo "   Reiniciar:    sudo docker restart pqc-hybrid"
    echo ""
else
    echo "❌ Error: El contenedor no está corriendo"
    echo ""
    echo "Logs del contenedor:"
    sudo docker logs pqc-hybrid
    exit 1
fi
