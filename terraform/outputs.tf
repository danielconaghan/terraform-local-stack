output "ecr_repository_url" {
  description = "ECR repository URL for the PHP service image"
  value       = aws_ecr_repository.php_service.repository_url
}

output "api_url" {
  description = "API Gateway endpoint for the /hello route"
  value       = "${aws_apigatewayv2_stage.live.invoke_url}/hello"
}
