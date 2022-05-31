output "services" {
  value = [for k, v in aws_ecs_service.this : v.id]
}
