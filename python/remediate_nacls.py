#!/usr/bin/env python

"""
Applies CIS 1.5 compliant ingress/egress rules to all current Network ACL's in an AWS account.
"""

import boto3

ec2 = boto3.client('ec2')

def error_handler(status_code):
    if status_code != 200:
        raise Exception('Error detected during API request to AWS, status code returned: ' + str(status_code))

class nacl_rule:
    def __init__(self, cidr, egress, protocol, action, number, icmp_type_code=None, port_range=None, nacl_id=None, mark_delete=False, mark_create=False):
        self.cidr = cidr
        self.egress = egress
        self.protocol = protocol
        self.action = action
        self.number = number
        self.icmp_type_code = icmp_type_code
        self.port_range = port_range
        self.nacl_id = nacl_id
        self.mark_delete = mark_delete
        self.mark_create = mark_create

    def __eq__(self, other):
        return (
            self.cidr == other.cidr
            and self.egress == other.egress
            and self.protocol == other.protocol
            and self.action == other.action
            and self.number == other.number
            and self.icmp_type_code == other.icmp_type_code
            and self.port_range == other.port_range
            and self.nacl_id == other.nacl_id
        )

    def delete(self):
        print(f"deleting {self.number}")
        r = ec2.delete_network_acl_entry(
            Egress=self.egress,
            NetworkAclId=self.nacl_id,
            RuleNumber=self.number,
        )
        error_handler(r["ResponseMetadata"]["HTTPStatusCode"])
        return r
    
    def create(self):
        print(f"creating {self.number}")

        if self.icmp_type_code is not None:
            r = ec2.create_network_acl_entry(
                CidrBlock=self.cidr,
                Egress=self.egress,
                NetworkAclId=self.nacl_id,
                IcmpTypeCode=self.icmp_type_code,
                Protocol=self.protocol,
                RuleAction=self.action,
                RuleNumber=self.number
            )

        elif self.port_range is not None:
            r = ec2.create_network_acl_entry(
                CidrBlock=self.cidr,
                Egress=self.egress,
                NetworkAclId=self.nacl_id,
                PortRange=self.port_range,
                Protocol=self.protocol,
                RuleAction=self.action,
                RuleNumber=self.number
            )

        else:
            r = ec2.create_network_acl_entry(
                CidrBlock=self.cidr,
                Egress=self.egress,
                NetworkAclId=self.nacl_id,
                Protocol=self.protocol,
                RuleAction=self.action,
                RuleNumber=self.number
            )

        error_handler(r["ResponseMetadata"]["HTTPStatusCode"])
        return r
    
def main():

    current_nacls = ec2.describe_network_acls()
    error_handler(current_nacls["ResponseMetadata"]["HTTPStatusCode"])

    # Define desired state
    icmp = nacl_rule('10.0.0.0/8', False, '1', 'allow', 10, icmp_type_code={"Code": -1, "Type": -1})
    pre_ssh_tcp = nacl_rule('0.0.0.0/0', False, '6', 'allow', 20, port_range={"From": 0, "To": 21})
    pre_ssh_udp = nacl_rule('0.0.0.0/0', False, '17', 'allow', 30, port_range={"From": 0, "To": 21})
    ssh = nacl_rule('10.0.0.0/8', False, '6', 'allow', 40, port_range={"From": 22, "To": 22})
    pre_rdp_tcp = nacl_rule('0.0.0.0/0', False, '6', 'allow', 50, port_range={"From": 23, "To": 3388})
    pre_rdp_udp = nacl_rule('0.0.0.0/0', False, '17', 'allow', 60, port_range={"From": 23, "To": 3388})
    rdp = nacl_rule('10.0.0.0/8', False, '6', 'allow', 70, port_range={"From": 3389, "To": 3389})
    post_rdp_tcp = nacl_rule('0.0.0.0/0', False, '6', 'allow', 80, port_range={"From": 3390, "To": 65535})
    post_rdp_udp = nacl_rule('0.0.0.0/0', False, '17', 'allow', 90, port_range={"From": 3390, "To": 65535})
    all_out = nacl_rule('0.0.0.0/0', True, '-1', 'allow', 100)

    desired_nacl_rules = [icmp, pre_ssh_tcp, pre_ssh_udp, ssh, pre_rdp_tcp, pre_rdp_udp, rdp, post_rdp_tcp, post_rdp_udp, all_out]

    for current_nacl in current_nacls["NetworkAcls"]:
        current_rules = []
        delete_rules = []
        create_rules = []

        for current_rule in current_nacl["Entries"]:
            
            for desired_rule in desired_nacl_rules:
                desired_rule.nacl_id = current_nacl["NetworkAclId"]
            
            if current_rule["RuleNumber"] != 32767:
                current_rule_obj = nacl_rule(current_rule["CidrBlock"], current_rule["Egress"], current_rule["Protocol"], current_rule["RuleAction"], current_rule["RuleNumber"], nacl_id=current_nacl["NetworkAclId"])
                if "IcmpTypeCode" in current_rule:
                    current_rule_obj.icmp_type_code = current_rule["IcmpTypeCode"]
                elif "PortRange" in current_rule:
                    current_rule_obj.port_range = current_rule["PortRange"]

                current_rules.append(current_rule_obj)

                if current_rule_obj not in desired_nacl_rules:
                    delete_rules.append(current_rule_obj)
                
        for rule in desired_nacl_rules:
            if rule not in current_rules:
                create_rules.append(rule)

        if len(delete_rules) != 0:
            print("Deployed NACL rule drift detected:")
            for rule in delete_rules:
                print(f"Deleting rule number {rule.number} on {rule.nacl_id}")
                rule.delete()
        else:
            print("No deployed NACL rule drift detected.")

        if len(create_rules) != 0:
            for rule in create_rules:
                rule.create()
        else:
            print("No new NACL rules to create.")

main()
