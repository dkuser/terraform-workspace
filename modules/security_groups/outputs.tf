output "alb" {
  value = aws_security_group.alb.id
}

output "ecs_tasks" {
  value = aws_security_group.ecs_tasks.id
}
output "openvpn" {
  value = aws_security_group.openvpn.id
}
output "ssh" {
  value = aws_security_group.ssh.id
}