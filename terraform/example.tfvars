variable "tags_common" {
  type = map(string)
  default = {
    "my_tag"   = "foo"
    "your_tag" = "bar"
  }
}

variable "vpcs" {
  default = {
    "my_vpc" = {
      cidr = "10.104.2.0/23",
      igw  = true
    }
    "your_vpc" = {
      cidr = "10.104.4.0/24",
      igw  = true
    }
  }
}

variable "subnets" {
    default = {
        "my_vpc" = {
            "ap-southeast-2a" = {
                "public-sub-2a" = {
                    "cidr" = "10.104.2.128/25",
                    "route_table" = {
                        "name" = "public-rt-2a",
                        "routes" = [
                            {
                                "cidr_block"         = "10.104.0.0/14"
                                "transit_gateway_id" = true
                            },
                            {
                                "cidr_block"      = "0.0.0.0/0"
                                "vpc_endpoint_id" = true
                            },
                        ]
                    }
                },
            },

            "ap-southeast-2b" = {
                "public-sub-2b" = {
                    "cidr" = "10.104.3.0/25"
                    "route_table" = {
                        "name" = "public-rt-2b",
                        "routes" = [
                            {
                                "cidr_block"         = "10.104.0.0/14"
                                "transit_gateway_id" = true
                            },
                            {
                                "cidr_block"      = "0.0.0.0/0"
                                "vpc_endpoint_id" = true
                            },
                        ]
                    }
                },
            },

            "ap-southeast-2c" = {
                "public-sub-2c" = {
                    "cidr" = "10.104.3.128/25"
                    "route_table" = {
                        "name" = "public-rt-2c",
                        "routes" = [
                            {
                                "cidr_block"         = "10.104.0.0/14"
                                "transit_gateway_id" = true
                            }
                        ]
                    }
                },
            }
        },
    
    #"your_vpc" = {
    #    add subnet and route table details here, as in the above "my_vpc" map
    # }

    }
}

# NAT Gateways and EIP attachments
# NOTE: the below list must be made up of legitimate subnet names as defined in the 'subnet' variable above.
#  A NAT Gateway will be created and attached to each of the values (subnet name) of the 'attached' key.
#  An EIP will be created and associated with each of the NAT Gateways that are created.
#  The 'routes_from' key is used to identify which subnet needs a route to the nat gateway.
variable "nat_gateways" {
  default = {
    "egress-ngw-2a" : {
      "attached"    = "public-sub-2a",
      "routes_from" = "egress-sub-2a"
    },
    "egress-ngw-2b" : {
      "attached"    = "public-sub-2b",
      "routes_from" = "egress-sub-2b"
    }
  }
}
