#!/bin/bash
set -e

echo "🔐 Generando certificados Post-Cuánticos (PQC)..."

mkdir -p certs

# Usamos la imagen de Open Quantum Safe para generar los certificados
# Algoritmos:
# - CA: ML-DSA-44 (Firma PQC pura)
# - Server: p256_mldsa44 (Híbrido: Clásico + PQC)

docker run --rm -v "$(pwd)/certs:/certs" openquantumsafe/oqs-ossl3 sh -c "
    cd /certs && \
    echo 'Generando CA Root...' && \
    openssl req -x509 -new -newkey mldsa44 -keyout ca_pqc.key -out ca_pqc.crt -nodes -subj '/CN=PQC Lab Root CA' -days 365 && \
    echo 'Generando Clave y CSR del Servidor...' && \
    openssl req -new -newkey p256_mldsa44 -keyout server.key -out server.csr -nodes -subj '/CN=localhost' && \
    echo 'Firmando Certificado del Servidor...' && \
    openssl x509 -req -in server.csr -out server.crt -CA ca_pqc.crt -CAkey ca_pqc.key -CAcreateserial -days 365
"

echo "✅ Certificados generados en ./certs"
