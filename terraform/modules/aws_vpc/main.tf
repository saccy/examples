terraform {
  required_version = ">= 0.15"
}

resource "aws_vpc" "vpcs" {
  for_each = var.vpcs

  cidr_block           = each.value.cidr
  enable_dns_hostnames = true
  tags                 = merge(var.tags_common, tomap({ "Name" = each.key }))
}

resource "aws_internet_gateway" "igws" {
  for_each = { for vpc_key, vpc_value in var.vpcs : vpc_key => vpc_value if vpc_value.igw }

  vpc_id = aws_vpc.vpcs[each.key].id
  tags   = merge(var.tags_common, tomap({ "Name" = "${each.key}-IGW" }))
}
