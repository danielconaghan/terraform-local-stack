# terraform-local-stack


```
local-dev/
├── docker-compose.yml               # Orchestrates services + LocalStack
├── terraform/
│   ├── main.tf                      # AWS resources (API Gateway, Lambda, etc.)
│   ├── variables.tf
│   └── service-outputs.tf          # Outputs (e.g., API endpoints)
├── services/
│   ├── survey/
│   │   ├── Dockerfile
│   │   ├── index.php
│   │   └── ...
│   ├── analysis/
│   │   └── ...
│   ├── crm/
│   │   └── ...
│   ├── docgen/
│   │   └── ...
│   └── auth/
│       └── ...
├── lambdas/
│   ├── router/
│   │   ├── index.py
│   │   └── lambda.zip
│   └── ...
└── .env                             # Shared config (e.g., AWS creds, ports)
```


Useful commands:


docker exec -it terraform /bin/bash
docker exec -it localstack /bin/bash

set dummy credentials
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test


awslocal --region eu-west-2 lambda list-functions

awslocal --region eu-west-2 lambda invoke \
  --function-name demo_lambda \
  --payload '{}' \
  response.json

cat response.json