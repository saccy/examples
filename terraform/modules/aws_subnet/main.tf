locals {
  flattened_subnets = flatten([
    for vpc, data in var.subnets : [
      for az, subnets in data : [
        for subnet_name, subnet in subnets : {
          vpc         = vpc
          az          = az
          subnet_name = subnet_name
          subnet_cidr = subnet["cidr"]
          route_table = {
            name   = subnet["route_table"]["name"]
            routes = subnet["route_table"]["routes"]
          }
        }
      ]
    ]
  ])
}

resource "aws_subnet" "subnets" {
  for_each = { for s in local.flattened_subnets : s.subnet_name => s }

  vpc_id            = var.vpcs[each.value.vpc]
  cidr_block        = each.value.subnet_cidr
  availability_zone = each.value.az
  tags              = merge(var.tags_common, tomap({ "Name" = each.value.subnet_name }))
}

resource "aws_route_table" "route_tables" {
  for_each = { for s in local.flattened_subnets : s.subnet_name => s }

  vpc_id = var.vpcs[each.value.vpc]

  dynamic "route" {
    for_each = each.value.route_table.routes
    
    content {
      cidr_block           = can(route.value.cidr_block) ? route.value.cidr_block : null
      gateway_id           = can(route.value.gateway_id) ? var.igws[each.value.vpc] : null
      transit_gateway_id   = can(route.value.transit_gateway_id) ? var.tgw : null
      nat_gateway_id       = can(route.value.nat_gateway_id) ? var.natgw[each.value.subnet_name] : null
      network_interface_id = can(route.value.network_interface_id) ? var.eni : null
      vpc_endpoint_id      = can(route.value.vpc_endpoint_id) ? var.vpce[each.value.vpc].endpoints[each.value.az].id : null
    }
  }

  tags = merge(var.tags_common, tomap({ "Name" = each.value.route_table.name }))
}

resource "aws_route_table_association" "rt_associations" {
  for_each = { for s in local.flattened_subnets : s.subnet_name => s }

  subnet_id      = aws_subnet.subnets[each.value.subnet_name].id
  route_table_id = aws_route_table.route_tables[each.value.subnet_name].id
}
