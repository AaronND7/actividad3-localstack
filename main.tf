# 1. Bucket simulado
resource "aws_s3_bucket" "seguro" {
  bucket        = "actividad3-seguro-local"
  force_destroy = true # permite borrarlo con objetos de prueba al terminar
}

# 2. Cifrado del lado del servidor con claves administradas por S3 (SSE-S3, AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "seguro" {
  bucket = aws_s3_bucket.seguro.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 3. Los cuatro controles de bloqueo de acceso público
resource "aws_s3_bucket_public_access_block" "seguro" {
  bucket = aws_s3_bucket.seguro.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

output "bucket" {
  value = aws_s3_bucket.seguro.id
}
