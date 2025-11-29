# Ejercicio 11: PQC Híbrido (Browser Compatible)

Este ejercicio es una variante del Ejercicio 10, diseñado para ser compatible con navegadores actuales (Chrome, Edge, Firefox).

## Objetivo
Demostrar el **Intercambio de Claves Post-Cuántico (PQC Key Exchange)** en un navegador estándar.

## Diferencias con Ejercicio 10
- **Certificados**: Se utilizan certificados estándar **ECDSA (prime256v1)** en lugar de ML-DSA. Esto permite que los navegadores validen la cadena de confianza (o al menos entiendan el formato X.509).
- **Key Exchange**: El servidor sigue configurado para negociar claves usando algoritmos híbridos (ej. X25519Kyber768) si el cliente lo soporta.

## Cómo probar
1. Generar certificados: `./generate_certs.sh`
2. Construir y correr:
   ```bash
   docker build -t pqc-hybrid .
   docker run -d -p 4434:4433 --name pqc-hybrid pqc-hybrid
   ```
3. Abrir en Chrome (con flag Kyber activado): `https://localhost:4434`
4. Inspeccionar seguridad (F12 -> Security) para ver "Key Exchange: X25519Kyber768".
