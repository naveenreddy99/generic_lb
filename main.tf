provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_lb" "lb" {
  for_each                         = var.lb

  name                             = each.value.lb_name
  internal                         = try(each.value.is_internal, true)
  subnets                          = each.value.subnets 
  load_balancer_type               = try(each.value.lb_type, "application")
  ip_address_type                  = try(each.value.ip_address_type, "ipv4")
  security_groups                  = try(each.value.security_groups, [])
  idle_timeout                     = try(each.value.idle_timeout, 60)
  enable_deletion_protection       = try(each.value.enable_deletion_protection, true)
  drop_invalid_header_fields       = try(each.value.drop_invalid_header_fields, true)
  enable_cross_zone_load_balancing = try(each.value.enable_cross_zone_load_balancing, true)
  enable_http2                     = try(each.value.enable_http2, true)

  tags = each.value.tags

  dynamic "access_logs" {
    for_each = length(each.value.access_logs) > 0 ? [each.value.access_logs] : []
    content {
      bucket  = try(access_logs.value.access_logs_bucket, null)
      enabled = try(access_logs.value.access_logs_enabled, null)
      prefix  = try(access_logs.value.access_logs_prefix, "")
    }
  }
}

resource "aws_lb_listener" "lstn" {
  for_each          = var.listener

  load_balancer_arn = local.lb_name_id[each.value.lb_name]
  port              = each.value.port
  protocol          = each.value.protocol
  certificate_arn   = try(each.value.certificate_arn, null)
  ssl_policy        = try(each.value.ssl_policy, null)

  dynamic "default_action" {
    for_each = length(each.value.fixed_response) > 0 ? [each.value.fixed_response]: length(each.value.redirect) > 0 ? [each.value.redirect] : []
    content {
      
      type        = try(each.value.type, "fixed-response")

      dynamic "fixed_response" {
        for_each = length(each.value.fixed_response) > 0 ? [each.value.fixed_response] : []
        content {
          status_code  = try(fixed_response.value.status_code, 200)
          content_type = try(fixed_response.value.content_type, "text/plain")
          message_body = try(fixed_response.value.message_body, "Hello, World!")
        }
      }

      dynamic "redirect" {
        for_each = length(each.value.redirect) > 0 ? [each.value.redirect] : []
        content {
          protocol = "HTTPS"
          port     = "443"
          host     = "example.com"
          path     = "/${redirect.value.redirect_path}"
          query    = "var=${redirect.value.redirect_query}"
          status_code = try(redirect.value.status_code, "HTTP_301")
        }
      }
    }
  }

  dynamic "default_action" {
    for_each = length(each.value.forward) > 0 ? [each.value.forward] : []

    content {
      target_group_arn = local.tg_name_id[each.value.forward.target_group_name]
      type             = "forward"
    }
  }

  tags = merge({"Name" = each.value.listener_name} , each.value.tags)

  lifecycle {
    ignore_changes = [
      default_action,
    ]
  }
}


resource "aws_lb_target_group" "tg" {
  for_each = var.target_group

  name     = each.value.target_group_name
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = each.value.vpc_id

  health_check {
    healthy_threshold   = each.value.health_check.healthy_threshold
    protocol            = "HTTP"
    interval            = 30
    port                = "8080"
    path                = "/"
    matcher             = "200-399"
  }
  
  tags = each.value.tags
}

resource "aws_lb_listener_rule" "lstn_rule" {
  for_each = var.listener_rules

  listener_arn =  local.lstn_name_id[each.value.listener_name]
  priority     = each.value.priority

  dynamic "action" {
    for_each = length(each.value.action) > 0 ? [each.value.action] : []
    content {
      type             = try(action.value.type, "forward")
      target_group_arn = local.tg_name_id[action.value.target_group_name]
    }
  }

  condition {
    path_pattern {
      values = ["/api/v1/*"]
    }
  }
  condition {
    host_header {
      values = ["int-webforward-api.markmonitor"]
    }
  }
}
