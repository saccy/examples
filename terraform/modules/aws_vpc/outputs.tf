output "vpcs" {
  value = {
    for name, vpc in aws_vpc.vpcs : name => vpc.id
  }
}

output "igws" {
  value = {
    for name, igw in aws_internet_gateway.igws : name => igw.id
  }
}
