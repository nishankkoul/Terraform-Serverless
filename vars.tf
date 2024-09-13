variable "aws_region" {
  description = "AWS region for resources"
  default     = "ap-south-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  default     = "hello_world_function"
}
