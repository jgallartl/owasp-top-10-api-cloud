resource "aws_cloudwatch_metric_alarm" "waf_requests_alarm" {
  alarm_name          = "WAFRequestsAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AllowedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "Alarm when WAF allowed requests exceed 1000 in 5 minutes"
  actions_enabled     = true

  dimensions = {
    WebACL = aws_wafv2_web_acl.web_acl.name
  }

  alarm_actions = [
    aws_sns_topic.waf_alarm_topic.arn
  ]
}

resource "aws_sns_topic" "waf_alarm_topic" {
  name = "waf-alarm-topic"
}

resource "aws_sns_topic_subscription" "waf_alarm_subscription" {
  topic_arn = aws_sns_topic.waf_alarm_topic.arn
  protocol  = "email"
  endpoint  = "your-email@example.com" # Replace with your email
}

resource "aws_cloudwatch_dashboard" "waf_dashboard" {
  dashboard_name = "WAFDashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 24,
        height = 6,
        properties = {
          metrics = [
            ["AWS/WAFV2", "AllowedRequests", "WebACL", aws_wafv2_web_acl.web_acl.name],
            ["AWS/WAFV2", "BlockedRequests", "WebACL", aws_wafv2_web_acl.web_acl.name]
          ],
          period = 300,
          stat   = "Sum",
          region = "eu-west-3",
          title  = "WAF Allowed and Blocked Requests"
        }
      }
    ]
  })
}