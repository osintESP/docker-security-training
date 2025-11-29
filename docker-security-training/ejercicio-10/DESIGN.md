# PQC-TLS Lab en Kubernetes

Este proyecto implementa un servidor web seguro con criptografía post-cuántica (PQC) desplegado en Kubernetes.

## Arquitectura

1.  **Servidor (Deployment)**: Apache httpd con OpenQuantumSafe (OQS) habilitado.
    *   Imagen: `pqc-lab:v1` (Basada en `openquantumsafe/httpd`)
    *   Algoritmos: ML-KEM-768 (Key Exchange), ML-DSA-44 (Firmas Híbridas).
2.  **Acceso (Service)**: Expone el servidor en el puerto 443.
3.  **Cliente (Pod)**: `openquantumsafe/curl` para validar la conexión.

## Estado de la Implementación

✅ **Certificados Generados**:
   - CA Root PQC (`certs/ca_pqc.crt`)
   - Certificado de Servidor Híbrido (`certs/server.crt`)

✅ **Imagen Construida**:
   - Nombre: `pqc-lab:v1`
   - Incluye configuración y certificados embebidos.

✅ **Manifiestos Kubernetes**:
   - Disponibles en la carpeta `k8s/`.

## Instrucciones de Despliegue

1.  **Desplegar en Kubernetes**:
    ```bash
    kubectl apply -f k8s/
    ```

2.  **Verificar estado**:
    ```bash
    kubectl get pods
    # Esperar a que estén en estado Running
    ```

3.  **Probar Conexión PQC**:
    Ejecuta el siguiente comando para probar la negociación TLS post-cuántica desde el pod cliente:
    ```bash
    kubectl exec -it pqc-client-test -- curl -k https://pqc-service -v
    ```
    *Busca en la salida:* `SSL connection using ... mlkem768`

## Referencias
- Basado en: [jalvarezz13/pqc-tls-lab](https://github.com/jalvarezz13/pqc-tls-lab)
