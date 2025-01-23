resource "aws_wafv2_web_acl" "web_acl" {
  name        = "api-gateway-waf"
  description = "Managed rule WAF"
  scope       = "REGIONAL"

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

        dynamic "rule_action_override" {
          for_each = toset(var.core_rule_action_override_names)
          content {
            action_to_use {
              block {}
            }
            name = rule_action_override.value
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled    = true
    }
  }

  rule {
    name     = "AWSManagedRulesAdminProtectionRuleSet"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"

        dynamic "rule_action_override" {
          for_each = toset(var.admin_protection_rule_group_override_names)
          content {
            action_to_use {
              block {}
            }
            name = rule_action_override.value
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesAdminProtectionRuleSet"
      sampled_requests_enabled    = true
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

        dynamic "rule_action_override" {
          for_each = toset(var.bad_inputs_rule_group_override_names)
          content {
            action_to_use {
              block {}
            }
            name = rule_action_override.value
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled    = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 4
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"

        dynamic "rule_action_override" {
          for_each = toset(var.sqli_rule_group_override_names)
          content {
            action_to_use {
              block {}
            }
            name = rule_action_override.value
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled    = true
    }
  }
    
 rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 5
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"

        dynamic "rule_action_override" {
          for_each = toset(var.linux_rule_group_override_names)
          content {
            action_to_use {
              block {}
            }
            name = rule_action_override.value
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled    = true
    }
  }

 rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 6
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"

        dynamic "rule_action_override" {
          for_each = toset(var.amazon_ip_reputation_rule_group_override_names)
          content {
            action_to_use {
              block {}
            }
            name = rule_action_override.value
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled    = true
    }
  }

 rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 7
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"

        dynamic "rule_action_override" {
          for_each = toset(var.anonymous_ip_rule_group_override_names)
          content {
            action_to_use {
              block {}
            }
            name = rule_action_override.value
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled    = true
    }
  }

  #  rule {
  #   name     = "AWSManagedRulesACFPRuleSet"
  #   priority = 8
  #   override_action {
  #     none {}
  #   }
  #   statement {
  #     managed_rule_group_statement {
  #       name        = "AWSManagedRulesACFPRuleSet"
  #       vendor_name = "AWS"

  #       dynamic "rule_action_override" {
  #         for_each = toset(var.acfp_rule_group_override_names)
  #         content {
  #           action_to_use {
  #             block {}
  #           }
  #           name = rule_action_override.value
  #         }
  #       }
  #     }
  #   }
  #   visibility_config {
  #     cloudwatch_metrics_enabled  = true
  #     metric_name                 = "AWSManagedRulesACFPRuleSet"
  #     sampled_requests_enabled    = true
  #   }
  # }

#    rule {
#     name     = "AWSManagedRulesATPRuleSet"
#     priority = 9
#     override_action {
#       none {}
#     }
#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesATPRuleSet"
#         vendor_name = "AWS"

#         dynamic "rule_action_override" {
#           for_each = toset(var.atp_rule_group_override_names)
#           content {
#             action_to_use {
#               block {}
#             }
#             name = rule_action_override.value
#           }
#         }
#       }
#     }
#     visibility_config {
#       cloudwatch_metrics_enabled  = true
#       metric_name                 = "AWSManagedRulesATPRuleSet"
#       sampled_requests_enabled    = true
#     }
#   }

   rule {
    name     = "AWSManagedRulesBotControlRuleSet"
    priority = 10
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        dynamic "rule_action_override" {
          for_each = toset(var.bot_control_rule_group_override_names)
          content {
            action_to_use {
              block {}
            }
            name = rule_action_override.value
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled  = true
      metric_name                 = "AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled    = true
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "apiGatewayWafMetrics"
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
  depends_on = [aws_cloudwatch_log_group.waf_log_group]
}

resource "aws_wafv2_web_acl_association" "waf_association" {
  resource_arn = "arn:aws:apigateway:eu-west-3::/restapis/${aws_api_gateway_rest_api.apigw_rest_api.id}/stages/${aws_api_gateway_stage.stage.stage_name}"
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
}