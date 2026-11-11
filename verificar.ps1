# Comprueba con AWS CLI lo que realmente quedó configurado en LocalStack.
# Uso: .\verificar.ps1   (requiere LocalStack arriba y terraform apply hecho)
$ErrorActionPreference = 'Continue'
$env:AWS_ACCESS_KEY_ID = 'test'; $env:AWS_SECRET_ACCESS_KEY = 'test'; $env:AWS_DEFAULT_REGION = 'us-east-1'
$ep = 'http://localhost:4566'; $b = 'actividad3-seguro-local'
function run($t) { "`n> $t"; Invoke-Expression "$t 2>&1"; "[codigo de salida: $LASTEXITCODE]" }

run "aws --endpoint-url $ep s3api list-buckets --query 'Buckets[].Name'"
run "aws --endpoint-url $ep s3api get-bucket-encryption --bucket $b"
run "aws --endpoint-url $ep s3api get-public-access-block --bucket $b"

"Archivo de prueba con datos ficticios - $(Get-Date -Format s)" | Out-File -Encoding ascii prueba.txt
run "aws --endpoint-url $ep s3 cp prueba.txt s3://$b/prueba.txt"
run "aws --endpoint-url $ep s3 ls s3://$b/"
run "aws --endpoint-url $ep s3api head-object --bucket $b --key prueba.txt --query ServerSideEncryption"

# Acceso anónimo: sin firmar la solicitud
run "aws --endpoint-url $ep --no-sign-request s3 cp s3://$b/prueba.txt descarga_anonima.txt"
run "curl.exe -s -o NUL -w 'HTTP %{http_code}' $ep/$b/prueba.txt"

run "aws --endpoint-url $ep s3api get-bucket-policy-status --bucket $b"
run "aws --endpoint-url $ep s3api get-bucket-policy --bucket $b"
