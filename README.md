# terraform-local-stack

A minimal AWS stack running locally via [LocalStack](https://localstack.cloud), fully provisioned with Terraform. The same Terraform code deploys to real AWS.

## Architecture

```
Browser
  └── React app (nginx, port 3000)
        └── fetches /hello
              └── API Gateway HTTP API  (LocalStack → AWS)
                    └── Lambda function (PHP via Bref)
                          └── {"message": "Hello, World!"}
```

| Component | Local | AWS |
|---|---|---|
| PHP runtime | Lambda container image (Bref) | Lambda container image (Bref) |
| API | API Gateway v2 HTTP API | API Gateway v2 HTTP API |
| Image registry | LocalStack ECR | Amazon ECR |
| Frontend | nginx container | S3 + CloudFront *(future)* |

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (includes Docker Compose)
- Bash (macOS / Linux)

That's it. Terraform, Node, and PHP all run inside containers.

## One-click start

```bash
./run.sh
```

Then open **http://localhost:3000**.

The script:
1. Starts LocalStack
2. Creates the ECR repository via Terraform
3. Builds the PHP service image and pushes it to LocalStack ECR
4. Provisions the Lambda + API Gateway via Terraform
5. Builds the React app inside a Node container
6. Starts the nginx frontend with the API URL injected at runtime

## Useful commands

**Watch LocalStack logs**
```bash
docker compose logs -f localstack
```

**Open a Terraform shell**
```bash
docker compose run --rm terraform console
```

**Show Terraform outputs**
```bash
docker compose run --rm terraform output -var="php_image_uri=placeholder"
```

**Invoke the Lambda directly**
```bash
docker exec localstack awslocal lambda invoke \
  --function-name php-service \
  --region eu-west-2 \
  /tmp/response.json && cat /tmp/response.json
```

**List API Gateway APIs**
```bash
docker exec localstack awslocal apigatewayv2 get-apis --region eu-west-2
```

**Tear down**
```bash
docker compose down
```

## Deploying to real AWS

The Terraform is AWS-compatible. Swap the provider config and supply a real ECR URI:

```bash
# 1. Build and push to real ECR
aws ecr get-login-password --region eu-west-2 | \
  docker login --username AWS --password-stdin <account>.dkr.ecr.eu-west-2.amazonaws.com

docker build -t php-service ./services/php-service
docker tag php-service:latest <account>.dkr.ecr.eu-west-2.amazonaws.com/php-service:latest
docker push <account>.dkr.ecr.eu-west-2.amazonaws.com/php-service:latest

# 2. Apply (using standard AWS credentials, not the LocalStack dummy ones)
cd terraform
terraform init
terraform apply -var="php_image_uri=<account>.dkr.ecr.eu-west-2.amazonaws.com/php-service:latest"
```

Remove the `endpoints {}` block and dummy credentials from `main.tf` before pointing at real AWS.

## Project structure

```
terraform-local-stack/
├── docker-compose.yml          # LocalStack + Terraform runner + frontend
├── run.sh                      # One-click start
├── terraform/
│   ├── main.tf                 # ECR, IAM, Lambda, API Gateway
│   ├── variables.tf            # php_image_uri variable
│   └── outputs.tf              # api_url, ecr_repository_url
├── services/
│   └── php-service/
│       ├── Dockerfile          # bref/php-83-fpm base image
│       └── index.php           # Returns {"message": "Hello, World!"}
└── frontend/
    ├── Dockerfile              # nginx with runtime config injection
    ├── nginx.conf
    ├── docker-entrypoint.sh    # Writes window.ENV.apiUrl at container start
    ├── index.html
    ├── package.json
    ├── vite.config.js
    └── src/
        ├── main.jsx
        └── App.jsx             # Fetches from API and displays message
```
