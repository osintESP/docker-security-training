# Ejercicio 11: PQC Híbrido (Browser Compatible)

✅ **VERIFICADO**: Post-Quantum Cryptography funcionando con **X25519MLKEM768**

Este ejercicio demuestra el uso de **algoritmos post-quantum (PQC) híbridos** en navegadores comerciales actuales (Chrome 131+, Edge).

## Objetivo

Demostrar el **Intercambio de Claves Post-Cuántico (PQC Key Exchange)** usando **X25519MLKEM768** en un navegador estándar, protegiendo contra ataques "store now, decrypt later" de futuras computadoras cuánticas.

## Resultado Verificado

**Chrome DevTools muestra**: `TLS 1.3, X25519MLKEM768, and AES_128_GCM`

## Arquitectura Técnica

### Certificados
- **Algoritmo**: ECDSA con curva `prime256v1` (estándar reconocido)
- **Razón**: Los browsers requieren certificados con algoritmos reconocidos para validar la cadena de confianza X.509
- **Limitación actual**: Certificados puramente PQC (ej. ML-DSA) aún no son soportados por browsers comerciales

### Key Exchange
- **Algoritmo principal**: X25519Kyber768 (híbrido: clásico + post-quantum)
- **Sucesor**: x25519mlkem768 (Chrome 131+, versión estandarizada NIST)
- **Fallback**: X25519, prime256v1 (compatibilidad con clientes antiguos)
- **Protocolo**: TLS 1.3 (requerido)

### Servidor Web
- **Software**: OpenQuantumSafe Nginx
- **OpenSSL**: Versión con proveedor OQS (Open Quantum Safe)
- **Configuración clave**: `ssl_conf_command Groups X25519Kyber768:x25519mlkem768:X25519:prime256v1`

## Estado Actual de PQC en Browsers (2024)

### Chrome 124+ (Abril 2024)
- ✅ **X25519Kyber768 habilitado por defecto** en TLS 1.3 y QUIC
- ✅ Desktop: Windows, macOS, Linux, ChromeOS
- ⚠️ Mobile: No habilitado por defecto
- 🔄 Transición a ML-KEM768 comenzó en Chrome 131

### Edge
- ✅ Sigue el mismo timeline que Chrome (basado en Chromium)

### Firefox
- ⏳ En desarrollo, no habilitado por defecto (a Nov 2024)

## Diferencias con Ejercicio 10

| Aspecto | Ejercicio 10 | Ejercicio 11 (Híbrido) |
|---------|--------------|------------------------|
| **Certificados** | ML-DSA (PQC puro) | ECDSA (estándar) |
| **Key Exchange** | Kyber/ML-KEM | X25519Kyber768 (híbrido) |
| **Cliente** | OpenSSL personalizado | **Browser comercial** |
| **Compatibilidad** | ❌ Requiere cliente especial | ✅ Chrome 124+ estándar |

## Cómo Probar

### Prerequisitos
- Chrome 124+ o navegador compatible
- Docker instalado

### Pasos

1. **Generar certificados ECDSA**:
   ```bash
   ./generate_certs.sh
   ```

2. **Construir y ejecutar**:
   ```bash
   docker build -t pqc-hybrid .
   docker run -d -p 4434:4433 --name pqc-hybrid pqc-hybrid
   ```

3. **Abrir en Chrome**: 
   ```
   https://localhost:4434
   ```
   Acepta el certificado autofirmado ("Avanzado" → "Continuar...")

4. **Verificar PQC Key Exchange**:
   - Abre **Chrome DevTools** (F12)
   - Ve a la pestaña **"Security"**
   - En **"Connection"**, busca **"Key Exchange"**
   - Deberías ver: `X25519Kyber768` o `x25519mlkem768`

   **Alternativa**: En la pestaña **Network**, recarga la página, haz clic en el request a `localhost`, y busca "Key Exchange Group" en la pestaña Security del request.

## Verificación Exitosa

Si todo funcionó correctamente, verás:

```
Protocol:        TLS 1.3
Key Exchange:    X25519Kyber768
Cipher Suite:    TLS_AES_128_GCM_SHA256
Certificate:     ECDSA P-256
```

## Notas Importantes

### ¿Por qué no usamos certificados ML-DSA?

Aunque ML-DSA (firma post-quantum) es técnicamente superior, los browsers actuales:
- ❌ No reconocen OIDs de algoritmos PQC puros
- ❌ Fallan en la validación de la cadena de confianza X.509
- ✅ Requieren ECDSA o RSA para compatibilidad

**Solución adoptada**: Certificados clásicos + Key Exchange PQC (enfoque pragmático)

### ¿Qué protege este ejercicio?

- ✅ **Key Exchange**: Protegido contra ataques cuánticos (Kyber768)
- ⚠️ **Autenticación**: Usa ECDSA (vulnerable a Shor's algorithm en computadoras cuánticas)

**Riesgo aceptable**: La autenticación ocurre en tiempo real, no puede ser "almacenada para descifrar después". El key exchange es el objetivo principal de "store now, decrypt later".

## Referencias

- [Chrome PQC Blog Post](https://security.googleblog.com/2024/04/post-quantum-cryptography-in-chrome.html)
- [Open Quantum Safe Project](https://openquantumsafe.org/)
- [NIST PQC Standardization](https://csrc.nist.gov/projects/post-quantum-cryptography)

