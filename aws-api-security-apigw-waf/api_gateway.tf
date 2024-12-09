resource "aws_api_gateway_rest_api" "apigw_rest_api" {
  name        = "crapi-api"
  description = "API for crAPI application"
}

resource "aws_api_gateway_resource" "apigw_resource" {
  rest_api_id = aws_api_gateway_rest_api.apigw_rest_api.id
  parent_id   = aws_api_gateway_rest_api.apigw_rest_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id   = aws_api_gateway_resource.apigw_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id   = aws_api_gateway_resource.apigw_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "put_method" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id   = aws_api_gateway_resource.apigw_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "delete_method" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id   = aws_api_gateway_resource.apigw_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id   = aws_api_gateway_resource.apigw_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "GET"
  type                    = "HTTP"
  uri                     = "http://${aws_eip.eip.public_ip}:8888" # Adjust the port as needed
  depends_on              = [aws_api_gateway_method.get_method]
}

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id   = aws_api_gateway_resource.apigw_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "HTTP"
  uri                     = "http://${aws_eip.eip.public_ip}:8888" # Adjust the port as needed
  depends_on              = [aws_api_gateway_method.post_method]
}

resource "aws_api_gateway_integration" "put_integration" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id   = aws_api_gateway_resource.apigw_resource.id
  http_method             = aws_api_gateway_method.put_method.http_method
  integration_http_method = "PUT"
  type                    = "HTTP"
  uri                     = "http://${aws_eip.eip.public_ip}:8888" # Adjust the port as needed
  depends_on              = [aws_api_gateway_method.put_method]
}

resource "aws_api_gateway_integration" "delete_integration" {
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  resource_id   = aws_api_gateway_resource.apigw_resource.id
  http_method             = aws_api_gateway_method.delete_method.http_method
  integration_http_method = "DELETE"
  type                    = "HTTP"
  uri                     = "http://${aws_eip.eip.public_ip}:8888" # Adjust the port as needed
  depends_on              = [aws_api_gateway_method.delete_method]
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  deployment_id = aws_api_gateway_deployment.apigw_deployment.id
}

resource "aws_api_gateway_deployment" "apigw_deployment" {
  depends_on  = [
    aws_api_gateway_integration.get_integration,
    aws_api_gateway_integration.post_integration,
    aws_api_gateway_integration.put_integration,
    aws_api_gateway_integration.delete_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.apigw_rest_api.id
}
