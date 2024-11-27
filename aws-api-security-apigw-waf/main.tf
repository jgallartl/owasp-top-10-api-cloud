provider "aws" {
  region = "eu-west-3"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "crapi-gw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.crapi-gw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  name        = "crapi-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8025
    to_port     = 8025
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "eni" {
  subnet_id       = aws_subnet.subnet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.sg.id]
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh_key"
  public_key = file("~/.ssh/id_rsa_crapi.pub")
}

data "cloudinit_config" "server_config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = templatefile("../resources/cloud-init.txt", {})
  }
}

resource "aws_instance" "vm" {
  ami           = "ami-006f2a24e73d7a5d8" # Ubuntu Server 22.04 LTS
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ssh_key.key_name

  subnet_id                   = aws_subnet.subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]

  user_data = data.cloudinit_config.server_config.rendered

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name = "crapi-vm"
  }

  depends_on = [aws_network_interface.eni] 
}

resource "aws_eip" "eip" {
  instance = aws_instance.vm.id
}

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

resource "aws_api_gateway_deployment" "apigw_deployment" {
  depends_on  = [
    aws_api_gateway_integration.get_integration,
    aws_api_gateway_integration.post_integration,
    aws_api_gateway_integration.put_integration,
    aws_api_gateway_integration.delete_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.apigw_rest_api.id
}

resource "aws_wafv2_web_acl" "web_acl" {
  name        = "web-acl"
  scope       = "REGIONAL"
  description = "Web ACL for crAPI application"
  default_action {
    allow {}
  }

  rule {
    name     = "BlockRule"
    priority = 1
    action {
      block {}
    }
    statement {
      byte_match_statement {
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
        positional_constraint = "CONTAINS"
        search_string         = "/block"
      }
    }
    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "BlockRule"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "webACL"
    sampled_requests_enabled   = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.apigw_rest_api.id
  deployment_id = aws_api_gateway_deployment.apigw_deployment.id
}

resource "aws_wafv2_web_acl_association" "waf_association" {
  resource_arn = "arn:aws:apigateway:eu-west-3::/restapis/${aws_api_gateway_rest_api.apigw_rest_api.id}/stages/${aws_api_gateway_stage.stage.stage_name}"
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
}

output "public_ip" {
  value = aws_instance.vm.public_ip
}
