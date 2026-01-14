output "node_sg_id" {
  value = aws_security_group.nodes.id
}

output "fsx_sg_id" {
  value = aws_security_group.fsx.id
}
