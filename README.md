# Actividad 3: bucket S3 seguro con Terraform y LocalStack

Laboratorio de Infraestructura como Código (Fase 1). Terraform declara un bucket S3 simulado con cifrado SSE-S3 (AES256) y los cuatro controles de bloqueo de acceso público. Después, AWS CLI comprueba qué quedó configurado y cómo se comporta el servicio.

Todo corre en **LocalStack**, un contenedor de Docker que emula AWS en `http://localhost:4566`. **No se usa AWS real ni se necesita una cuenta de AWS.**

| Dato | Valor |
|---|---|
| Bucket | `actividad3-seguro-local` |
| Región | `us-east-1` |
| Endpoint | `http://localhost:4566` (solo localhost) |
| Cifrado | SSE-S3, `AES256` |
| Recursos de Terraform | 3 (bucket, cifrado y bloqueo de acceso público) |

## Archivos

| Archivo | Contenido |
|---|---|
| `compose.yaml` | LocalStack con S3, puerto 4566 solo en `127.0.0.1`, token por variable de entorno y chequeo de salud |
| `providers.tf` | Provider AWS con región `us-east-1`, credenciales ficticias (`test`) y endpoint de S3 local |
| `main.tf` | Bucket, cifrado AES256 y los cuatro controles de bloqueo público |
| `verificar.ps1` | Consultas con AWS CLI: buckets, cifrado, bloqueo, carga, acceso anónimo y política |
| `.env.example` | Plantilla para el token; el `.env` real no se sube |
| `.gitignore` | Excluye `.env`, tokens, `*.tfstate`, `.terraform/` y el plan |

## Requisitos

- Docker Desktop (Windows y macOS) o Docker Engine (Linux), con Docker Compose v2
- Terraform 1.5 o posterior
- AWS CLI v2
- Una cuenta gratuita de LocalStack (plan **Hobby**) y su token personal

Versiones usadas: Docker 29.2.1, Docker Compose v5.0.2, Terraform 1.17.1, AWS CLI 2.34.13 y LocalStack 2026.10.6.

## Cómo ejecutarlo

1. **Token:** copia `.env.example` como `.env` y pega tu token después de `LOCALSTACK_AUTH_TOKEN=`. No lo subas ni lo muestres.

2. **LocalStack:**
   ```bash
   docker compose up -d
   docker compose ps                       # debe decir (healthy)
   curl http://localhost:4566/_localstack/health
   ```

3. **Terraform:**
   ```bash
   terraform init
   terraform validate
   terraform plan -out=tfplan              # Plan: 3 to add
   terraform apply tfplan
   ```

4. **Verificación con AWS CLI** (PowerShell):
   ```powershell
   .\verificar.ps1
   ```
   En otros sistemas, usa los mismos comandos del script con `--endpoint-url http://localhost:4566` y las credenciales `test`/`test`.

5. **Limpieza:**
   ```bash
   terraform destroy
   docker compose down
   ```

## Resultados obtenidos

- `terraform plan`: `3 to add`. `terraform apply`: `3 added`.
- `get-bucket-encryption`: `SSEAlgorithm: AES256`. El objeto subido reporta `ServerSideEncryption: AES256`.
- `get-public-access-block`: los cuatro controles en `true`.
- **Acceso anónimo** (`--no-sign-request` y `curl` sin firma): **permitido**, con HTTP 200 y el mismo contenido (hash SHA-256 idéntico). En AWS real, con el bloqueo de acceso público activo, la ACL privada y sin política de bucket, se esperaría una negación (`403 AccessDenied`).
- `get-bucket-policy-status`: `NoSuchBucketPolicy`, es decir, el bucket no tiene política. Eso **no** prueba que el bucket sea público; solo indica que no hay una política que lo otorgue.

### Por qué LocalStack permitió el acceso anónimo

LocalStack emula las APIs de AWS, pero **no aplica por defecto todas las reglas de autorización**. La evaluación de IAM está desactivada salvo que se active `ENFORCE_IAM=1`, y en este laboratorio no estaba definida. Por eso guarda y devuelve la configuración de bloqueo, pero no la usa para negar solicitudes. El resultado se trata como una limitación del simulador hasta contar con una validación independiente, por ejemplo en una cuenta de AWS de pruebas.

## Conclusión

- **Infraestructura declarada:** lo que dice el código (`main.tf`): cifrado AES256 y los cuatro bloqueos públicos.
- **Configuración consultada:** lo que el servicio reporta al preguntarle con AWS CLI. Aquí coincidió con lo declarado.
- **Seguridad efectivamente aplicada:** lo que el servicio hace ante una solicitud real. LocalStack aceptó una descarga anónima pese a la configuración. Que algo esté declarado y aparezca en las consultas no prueba que se haga cumplir: hay que comprobarlo con pruebas de comportamiento en el entorno real.

## Seguridad del repositorio

- No contiene tokens, contraseñas, `.env` ni archivos `*.tfstate`.
- Las credenciales `test`/`test` son ficticias y solo funcionan contra LocalStack.
- Todos los datos de prueba son ficticios.
