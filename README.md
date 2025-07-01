# terraform-local-stack

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