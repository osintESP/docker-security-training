# Ejercicio 11: PQC Híbrido para Browsers Comerciales 🔐

✅ **VERIFICADO**: Post-Quantum Cryptography funcionando con **X25519MLKEM768**

Demostración de **criptografía post-cuántica (PQC)** usando **X25519MLKEM768** en browsers comerciales modernos como Chrome 131+.

## 🎯 Objetivo

Configurar un servidor HTTPS que negocie el intercambio de claves usando algoritmos **post-quantum híbridos**, específicamente **X25519MLKEM768** (versión estandarizada de Kyber768), protegiendo contra ataques "store now, decrypt later" de futuras computadoras cuánticas.

## ✅ Resultado Verificado

**Chrome negocia exitosamente**: `TLS 1.3, X25519MLKEM768, and AES_128_GCM`

- **X25519**: Curva elíptica clásica (seguridad actual)
- **MLKEM768**: ML-KEM-768 (NIST PQC estándar, basado en Kyber768)
- **Híbrido**: Combina ambos para máxima seguridad

## 🧬 ¿Qué es Post-Quantum Cryptography?

Los **algoritmos post-cuánticos** están diseñados para resistir ataques de computadoras cuánticas. Chrome 124+ (abril 2024) habilitó por defecto **X25519Kyber768**, un esquema **híbrido** que combina:

- **X25519**: Curva elíptica clásica (seguridad actual)
- **Kyber768**: Algoritmo post-cuántico basado en lattices (NIST PQC)

> **Nota**: Chrome 131+ migra a **ML-KEM768** (versión estandarizada de Kyber). Este ejercicio soporta ambos.

## 📋 Requisitos

- Docker instalado
- Chrome 124+ o navegador compatible con Kyber/ML-KEM
- Permisos para exponer puerto 4434

## 🚀 Inicio Rápido

### 1️⃣ Generar Certificados

```bash
./generate_certs.sh
```

Esto genera certificados **ECDSA estándar** (prime256v1) compatibles con browsers. El PQC se aplica al **intercambio de claves**, no a los certificados.

### 2️⃣ Construir Imagen Docker

```bash
docker build -t pqc-hybrid .
```

La imagen usa `openquantumsafe/nginx` que incluye OpenSSL con el proveedor OQS (Open Quantum Safe).

### 3️⃣ Ejecutar Contenedor

```bash
docker run -d -p 4434:4433 --name pqc-hybrid pqc-hybrid
```

### 4️⃣ Abrir en Chrome

Navega a:
```
https://localhost:4434
```

Acepta el certificado autofirmado:
- Haz clic en **"Avanzado"** → **"Continuar a localhost (no seguro)"**

## 🔍 Verificar Post-Quantum Key Exchange

### Método 1: Chrome DevTools - Security Tab

1. Presiona **F12** para abrir DevTools
2. Ve a la pestaña **"Security"**
3. En la sección **"Connection"**, busca **"Key Exchange"**
4. Deberías ver: `X25519Kyber768` o `x25519mlkem768`

### Método 2: Network Tab

1. Abre **DevTools** (F12) → pestaña **"Network"**
2. Recarga la página (Ctrl+R)
3. Haz clic en el request a `localhost`
4. En la pestaña **"Security"** del request, busca **"Key Exchange Group"**

### Captura de Pantalla Esperada

**VERIFICADO en Chrome DevTools - Security Tab:**

```
Connection - secure connection settings

The connection to this site is encrypted and authenticated using 
TLS 1.3, X25519MLKEM768, and AES_128_GCM.

Certificate - missing
This site is missing a valid, trusted certificate...
```

**Info confirmada**:
```
Protocol:        TLS 1.3
Key Exchange:    X25519MLKEM768  ← ✅ POST-QUANTUM HÍBRIDO
Cipher Suite:    AES_128_GCM
Certificate:     ECDSA P-256 (autofirmado)
```

### Explicación del Resultado

- **X25519MLKEM768** es el algoritmo híbrido que combina:
  - **X25519**: Diffie-Hellman sobre Curve25519 (clásico)
  - **ML-KEM-768**: Module-Lattice Key Encapsulation Mechanism (post-quantum)
  
- **ML-KEM** es la versión estandarizada por NIST de Kyber768
- Chrome 131+ usa ML-KEM768 en lugar de la versión draft Kyber768
- La imagen `openquantumsafe/nginx` tiene PQC habilitado por defecto

## 📁 Estructura del Proyecto

```
ejercicio-11-hybrid/
├── Dockerfile              # Imagen openquantumsafe/nginx
├── generate_certs.sh       # Script para generar certificados ECDSA
├── config/
│   └── nginx.conf          # Configuración Nginx con PQC
├── html/
│   └── index.html          # Página de demostración
├── certs/                  # Generados por script (no en git)
│   ├── ca_pqc.crt
│   ├── server.crt
│   └── server.key
└── k8s/                    # Configs de Kubernetes (opcional)
```

## 🧪 Arquitectura Técnica

### Certificados

- **Algoritmo**: ECDSA con curva `prime256v1`
- **Razón**: Browsers requieren algoritmos reconocidos para validación X.509
- **Nota**: Certificados PQC puros (ej. ML-DSA) no son compatibles con browsers actuales

### Key Exchange

- **Grupos configurados**: `X25519Kyber768`, `x25519mlkem768`, `X25519`, `prime256v1`
- **Protocolo**: TLS 1.3 (requerido para PQC)
- **Configuración**: `ssl_conf_command Groups` en nginx.conf

### Imagen Docker

- **Base**: `openquantumsafe/nginx:latest`
- **OpenSSL**: Incluye proveedor OQS con soporte para Kyber/ML-KEM
- **Alternativa**: Compilar nginx + OpenSSL 3.5+ desde fuentes (más complejo)

## 🛠️ Troubleshooting

### "This site can't provide a secure connection"

**Causa**: El browser no detectó el algoritmo PQC o hay un error de configuración.

**Solución**:
1. Verifica logs del contenedor: `docker logs pqc-hybrid`
2. Confirma versión de Chrome: `chrome://version` (debe ser 124+)
3. Revisa configuración de nginx: `docker exec pqc-hybrid cat /etc/nginx/nginx.conf`

### "Your connection is not private" (ERR_CERT_AUTHORITY_INVALID)

**Causa**: Certificado autofirmado esperado.

**Solución**:
- Haz clic en **"Avanzado"** → **"Continuar..."**
- Para producción, usa certificados de una CA reconocida (Let's Encrypt)

### No veo X25519Kyber768 en DevTools

**Causa posible**:
1. Chrome < 124 (verificar en `chrome://version`)
2. El servidor no negoció PQC (verifica logs)
3. Policy empresarial deshabilitó Kyber

**Verificación**:
```bash
# Logs del contenedor
docker logs pqc-hybrid

# Verificar configuración
docker exec pqc-hybrid nginx -T | grep -i groups
```

## 🧹 Limpieza

```bash
# Detener y eliminar contenedor
docker stop pqc-hybrid
docker rm pqc-hybrid

# Eliminar imagen (opcional)
docker rmi pqc-hybrid

# Eliminar certificados generados
rm -rf certs/
```

## 📚 Referencias

- [Open Quantum Safe](https://openquantumsafe.org/)
- [Chrome PQC Announcement](https://security.googleblog.com/2024/04/post-quantum-cryptography-in-chrome.html)
- [NIST Post-Quantum Standards](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [Kyber/ML-KEM Specification](https://pq-crystals.org/kyber/)

## 🔗 Ejercicios Relacionados

- **Ejercicio 10**: PQC puro (sin compatibilidad con browsers estándar)
- **Ejercicio 2**: API básica con TLS clásico

## 📝 Notas Educativas

### ¿Por qué híbrido?

Los algoritmos híbridos (X25519 + Kyber768) ofrecen:
- ✅ **Seguridad actual**: X25519 protege contra ataques convencionales
- ✅ **Seguridad futura**: Kyber768 protege contra ataques cuánticos
- ✅ **Compatibilidad**: Fallback a X25519 si el cliente no soporta Kyber

### Diferencia entre certificados y key exchange

| Aspecto | Certificados | Key Exchange |
|---------|--------------|--------------|
| **Propósito** | Autenticación (identidad del servidor) | Establecer claves simétricas |
| **Algoritmo en este lab** | ECDSA (prime256v1) | X25519Kyber768 |
| **Soporte PQC en browsers** | ❌ No (aún) | ✅ Sí (Chrome 124+) |

---

**Autor**: Docker Security Training  
**Licencia**: MIT  
**Última actualización**: 2024-11-29
