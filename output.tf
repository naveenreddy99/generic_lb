locals {
  lb_name_id = {for i in aws_lb.lb: i.name => i.id}
  tg_name_id = {for i in aws_lb_target_group.tg: i.name => i.id}
  lstn_name_id = {for i in aws_lb_listener.lstn: i.tags_all.Name => i.id}
}

output "lb_name_id" {
  value = local.lb_name_id
}

output "tg_name_id" {
  value = local.tg_name_id
}

output "lstn_name_id" {
  value = local.lstn_name_id
}
