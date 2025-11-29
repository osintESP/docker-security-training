#!/bin/bash
set -e

echo "🔐 Generando certificados para PQC Hybrid Demo..."
echo ""
echo "NOTA: Para compatibilidad con browsers comerciales (Chrome, Firefox, Edge),"
echo "usamos certificados ECDSA estándar (prime256v1)."
echo "El intercambio de claves post-quantum (X25519Kyber768) se negocia en TLS 1.3."
echo ""

mkdir -p certs

# Usamos la imagen de Open Quantum Safe para generar los certificados
# Los browsers modernos requieren certificados con algoritmos reconocidos (ECDSA/RSA)
# El PQC se aplica al KEY EXCHANGE, no a los certificados

docker run --rm -v "$(pwd)/certs:/certs" openquantumsafe/oqs-ossl3 sh -c "
    cd /certs && \
    echo '📝 Generando CA Root (ECDSA prime256v1 - Browser Compatible)...' && \
    openssl req -x509 -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
        -keyout ca_pqc.key -out ca_pqc.crt -nodes \
        -subj '/CN=PQC Hybrid Lab Root CA/O=Docker Security Training/C=AR' \
        -days 365 && \
    echo '📝 Generando Clave y CSR del Servidor (ECDSA prime256v1)...' && \
    openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
        -keyout server.key -out server.csr -nodes \
        -subj '/CN=localhost/O=Docker Security Training/C=AR' && \
    echo '✍️  Firmando Certificado del Servidor con CA...' && \
    openssl x509 -req -in server.csr -out server.crt \
        -CA ca_pqc.crt -CAkey ca_pqc.key -CAcreateserial \
        -days 365 -sha256 && \
    echo '' && \
    echo '✅ Certificados generados:' && \
    ls -lh /certs/*.{crt,key} 2>/dev/null | awk '{print \"   \", \$9, \"(\"\$5\")\"}'
"

echo ""
echo "✅ Certificados generados en ./certs"
echo ""
echo "Para validar: openssl x509 -in certs/server.crt -text -noout | grep 'Public Key Algorithm'"

