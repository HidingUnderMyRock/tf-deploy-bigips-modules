# ./modules/bigip_standalone

## Description

This module is used to create a standalone BIG-IP within an availability zone.

## Variables

The variables listed below are passed to this module by the root ./main.tf module, not in a tfvars file like the other modules in this repository.  This allows the flexibility to reuse the module to create multiple BIG-IP devices, without increasing the the size of ./modules/bigip_standalone/main.tf.

| Variable | Description |
| -------- | ----------- |
| awsVpcName | The VPC name in AWS that the BIG-IPs will reside within |
| awsSubnetSuffix | The suffix the module will use to identify the availability zone subnets |
| awsNamePrefix | The prefix to all created objects name/tags within AWS |
| awsBigipName | The name assigned to the BIG-IP device, which will be prepended with awsNamePrefix |
| awsSshKeyName | The SSH key within the AWS region that the BIG-IPs will use to authenticate |
| awsRegion | The AWS region the VPC resides within |
| awsAmiId | The AMI ID for the BIG-IP image that will be used |
| awsInstanceType | The instance size/flavor of the BIG-IP instances |
| awsSecondaryIpCount | The number of secondary IP addresses to attach to external interface |
| awsVipCidrBlock | CIDR block for virtual addresses, which will be mapped to the external ENI of BIG-IP-1 |

