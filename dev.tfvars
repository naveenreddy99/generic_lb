lb = { "lb1" =  {lb_name                            = "alb-whitelist-access-newfold-dev"
                is_internal                         = true
                subnets                             = ["subnet-00b08ec27514283dc", "subnet-0a7001618925370c7"]
                lb_type                             = "application"
                ip_address_type                     = "ipv4"
                security_groups                     = ["sg-04b28888ea4081aac"]
                idle_timeout                        = 300
                enable_deletion_protection          = false
                drop_invalid_header_fields          = false
                enable_cross_zone_load_balancing    = false 
                enable_http2                        = true
                tags                                = { "Name" = "alb_whitelist_access_newfold_dev"
                                                        "tr:appFamily" = "mm"
                                                        "tr:appName" = "mm-alb"
                                                        "tr:environment-type" = "blue-dev"
                                                        "tr:role" = "security"
                                                        "product" = "Mark Monitor"
                                                        "ca:owner" = "mm-devops"
                                                        "ca:contact" = "mm-ipg-stgops@clarivate.com"
                                                        }
                access_logs                         = { #access_logs_bucket = "stageinternalalblog"
                                                        #access_logs_enabled = true
                                                        #access_logs_prefix = ""
                                                        }
    }
}

listener = {"lstn1" = { lb_name                             = "alb-whitelist-access-newfold-dev"
                        listener_name                       = "alb-whitelist-lstn1"
                        port                                = 80
                        protocol                            = "HTTP"
                        type                                = "fixed-response"
                        fixed_response                      = {#status_code = 200
                                                              }
                        redirect                            = {}
                        forward                             = {target_group_name = "test"
                                                              }
                        listener_rules                      = {}
                        tags                                = {}
                        }
}

listener_rules = {"rule1" = {listener_name = "alb-whitelist-lstn1"
                             priority                   = 1
                             action   = {type = "forward"
                                         target_group_name = "test"
                                        }

                            }

}
target_group = {"tg1" = { target_group_name         = "test"
                          port                      = 8080
                          protocol                  = "HTTP"
                          vpc_id                    = "vpc-0565a34ea4d0a19d1"
                          health_check              = { healthy_threshold   = 2
                                                        protocol            = "HTTP"
                                                        interval            = 30
                                                        port                = "8080"
                                                        path                = "/"
                                                        matcher             = "200-399"
                                                        }
                          tags                      = {"Name" = "alb_whitelist_access_newfold_dev"
                                                        "tr:appFamily" = "mm"
                                                        "tr:appName" = "mm-alb"
                                                        "tr:environment-type" = "blue-dev"
                                                        "tr:role" = "security"
                                                        "product" = "Mark Monitor"
                                                        "ca:owner" = "mm-devops"
                                                        "ca:contact" = "mm-ipg-stgops@clarivate.com"}

                        }
}
