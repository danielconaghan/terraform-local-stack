#!/bin/bash
set -euo pipefail

REGION="eu-west-2"
LOCALSTACK_ENDPOINT="http://localhost:4566"
ECR_REGISTRY="localhost:4566"
ACCOUNT_ID="000000000000"
PHP_IMAGE="php-service"
PHP_IMAGE_URI="${ECR_REGISTRY}/${ACCOUNT_ID}/${PHP_IMAGE}:latest"

# ── 1. Clean up and start LocalStack ──────────────────────────────────────────
echo "==> Stopping any previous stack..."
docker compose down --remove-orphans 2>/dev/null || true
rm -f terraform/terraform.tfstate terraform/terraform.tfstate.backup

echo "==> Starting LocalStack..."
docker compose up -d localstack

echo -n "==> Waiting for LocalStack"
until curl -sf "${LOCALSTACK_ENDPOINT}/_localstack/health" | grep -q '"lambda"'; do
  sleep 2; echo -n "."
done
echo " ready!"

# ── 2. Create ECR repository ──────────────────────────────────────────────────
echo ""
echo "==> Initialising Terraform..."
docker compose run --rm terraform init -input=false -upgrade -reconfigure

echo "==> Creating ECR repository..."
docker compose run --rm terraform apply -auto-approve -input=false \
  -target=aws_ecr_repository.php_service \
  -var="php_image_uri=placeholder"

# ── 3. Build and push PHP image ───────────────────────────────────────────────
echo ""
echo "==> Building PHP service image..."
docker build -t "${PHP_IMAGE}:latest" ./services/php-service

echo "==> Pushing image to LocalStack ECR..."
# LocalStack ECR does not validate credentials; any token works
echo "localstack" | docker login --username AWS --password-stdin "${ECR_REGISTRY}" 2>/dev/null || true
docker tag "${PHP_IMAGE}:latest" "${PHP_IMAGE_URI}"
docker push "${PHP_IMAGE_URI}"

# ── 4. Provision all infrastructure ──────────────────────────────────────────
echo ""
echo "==> Provisioning infrastructure (Lambda + API Gateway)..."
docker compose run --rm terraform apply -auto-approve -input=false \
  -var="php_image_uri=${PHP_IMAGE_URI}"

# ── 5. Capture API URL ────────────────────────────────────────────────────────
echo ""
echo "==> Reading outputs..."
RAW_API_URL=$(docker compose run --rm terraform output -raw api_url 2>/dev/null | tr -d '\r')
# Replace internal docker hostname with localhost if present
API_URL=$(echo "${RAW_API_URL}" | sed 's|://localstack:|://localhost:|g')

# ── 6. Build React app ────────────────────────────────────────────────────────
echo ""
echo "==> Building React frontend..."
docker run --rm \
  -v "$(pwd)/frontend:/app" \
  -w /app \
  node:20-alpine \
  sh -c "npm ci --silent && npm run build"

# ── 7. Start frontend ─────────────────────────────────────────────────────────
echo ""
echo "==> Starting frontend..."
export API_URL
docker compose up -d --build frontend

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "========================================="
echo " Done!"
echo ""
echo " Frontend : http://localhost:3000"
echo " API      : ${API_URL}"
echo "========================================="
