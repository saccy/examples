output "subnets" {
  value = {
    for name, subnet in aws_subnet.subnets : name => subnet.id
  }
}
