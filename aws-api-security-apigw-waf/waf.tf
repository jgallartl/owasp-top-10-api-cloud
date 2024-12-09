resource "aws_wafv2_web_acl" "web_acl" {
  name        = "web-acl"
  scope       = "REGIONAL"  # Use "CLOUDFRONT" for CloudFront distributions
  description = "Web ACL for crAPI application"
  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled    = true
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesCommonRuleSet"
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled    = true
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesSQLiRuleSet"
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled    = true
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesKnownBadInputsRuleSet"
    }
  }

  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 4
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled    = true
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesLinuxRuleSet"
    }
  }

  rule {
    name     = "AWSManagedRulesUnixRuleSet"
    priority = 5
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesUnixRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled    = true
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesUnixRuleSet"
    }
  }

  rule {
    name     = "AWSManagedRulesWindowsRuleSet"
    priority = 6
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesWindowsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled    = true
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesWindowsRuleSet"
    }
  }

  rule {
    name     = "AWSManagedRulesAdminProtectionRuleSet"
    priority = 7
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled    = true
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesAdminProtectionRuleSet"
    }
  }

  rule {
    name     = "AWSManagedRulesBotControlRuleSet"
    priority = 8
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      sampled_requests_enabled    = true
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesBotControlRuleSet"
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "webACL"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "waf_log_group" {
  name = "aws-waf-logs-cloudwatch"
}

resource "aws_wafv2_web_acl_logging_configuration" "web_acl_logging" {
  resource_arn = aws_wafv2_web_acl.web_acl.arn
  log_destination_configs = [
    aws_cloudwatch_log_group.waf_log_group.arn
  ]
  depends_on = [ aws_cloudwatch_log_group.waf_log_group ]
}

resource "aws_wafv2_web_acl_association" "waf_association" {
  resource_arn = "arn:aws:apigateway:eu-west-3::/restapis/${aws_api_gateway_rest_api.apigw_rest_api.id}/stages/${aws_api_gateway_stage.stage.stage_name}"
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
}


