# terraform-local-stack

Project Structure
terraform-localstack-demo/
├── main.tf

├── variables.tf

├── outputs.tf

└── terraform.tfvars

We'll use this to create:
- An S3 bucket
- A Lambda function

(Optionally) an EC2 instance

Step 1: Start LocalStack

Option 1: With Docker CLI
```docker run --rm -it -p 4566:4566 -p 4571:4571 localstack/localstack```

Option 2: With localstack CLI
```pip install localstack```
```localstack start```


Step 2: Set Up Terraform Config
main.tf
```
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  s3_force_path_style         = true

  endpoints {
    s3     = "http://localstack:4566"
    lambda = "http://localstack:4566"
    iam    = "http://localstack:4566"
  }
}

resource "aws_s3_bucket" "demo_bucket" {
  bucket = var.bucket_name
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_lambda_function" "demo_lambda" {
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = "lambda.zip"
}
```

variables.tf
```
variable "bucket_name" {
  type    = string
  default = "my-local-bucket"
}

variable "lambda_name" {
  type    = string
  default = "my-local-lambda"
}
```

outputs.tf
```
output "bucket_name" {
  value = aws_s3_bucket.demo_bucket.bucket
}

output "lambda_function" {
  value = aws_lambda_function.demo_lambda.function_name
}
```

terraform.tfvars (optional)
```
bucket_name = "my-demo-local-bucket"
lambda_name = "demo-local-lambda"
```

Step 3: Create a Simple Lambda Function
Create a file lambda_function.py:
```
def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': 'Hello from LocalStack Lambda!'
    }
```
Zip it:
```
zip lambda.zip lambda_function.py
```
Step 4: Run Terraform
```
terraform init
terraform plan
terraform apply
```
You should see output like:
```
bucket_name = "my-demo-local-bucket"
lambda_function = "demo-local-lambda"
```
Your S3 bucket and Lambda function now exist in LocalStack!

Step 5: Test It
Use awslocal to list the bucket:
```
awslocal s3 ls
```

Invoke the Lambda:
```
awslocal lambda invoke \
  --function-name demo-local-lambda \
  out.json && cat out.json
```

Clean Up
```
terraform destroy
```

Bonus: EC2 Instance (Optional)
LocalStack supports EC2 but with limited networking. Here's a sample:

```
resource "aws_instance" "demo_ec2" {
  ami           = "ami-12345678" # LocalStack accepts any value
  instance_type = "t2.micro"
}
Add ec2 = "http://localhost:4566" to endpoints in the provider.
```
