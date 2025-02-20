variable "awsVpcName" {}
variable "awsSubnetSuffix" {}
variable "awsNamePrefix" {}
variable "awsBigipName" {}
variable "awsSshKeyName" {}
variable "awsRegion" {}
variable "awsAmiId" {}
variable "awsInstanceType" {}
variable "awsSecondaryIpCount" {}
variable "awsVipCidrBlock" {}

terraform {
    required_version = ">= 0.12"
}

provider "aws" {
    region                      = var.awsRegion
#    access_key                  = var.awsAccessKey
#    secret_key                  = var.awsSecretKey
}

data "aws_vpc" "lipowsky-tf-vpc" {
    tags = {
        Name                    = var.awsVpcName
    }
}

# Retrieve subnet IDs from VPC, using subnet suffix as search criteria

data "aws_subnet_ids" "awsVpcMgmtSubnet" {
    vpc_id                      = data.aws_vpc.lipowsky-tf-vpc.id
    tags = {
        Name                    = "*mgmt*${var.awsSubnetSuffix}"
    }
}

data "aws_subnet_ids" "awsVpcExternalSubnet" {
    vpc_id                      = data.aws_vpc.lipowsky-tf-vpc.id
    tags = {
        Name                    = "*external*${var.awsSubnetSuffix}"
    }
}

data "aws_subnet_ids" "awsVpcInternalSubnet" {
    vpc_id                      = data.aws_vpc.lipowsky-tf-vpc.id
    tags = {
        Name                    = "*internal*${var.awsSubnetSuffix}"
    }
}

# Retrieve security group IDs from VPC

data "aws_security_groups" "awsVpcMgmtSecurityGroup" {
    filter {
        name                    = "vpc-id"
        values                  = ["${data.aws_vpc.lipowsky-tf-vpc.id}"]
    }
    tags = {
        Name                    = "*mgmt*"
    }
}

data "aws_security_groups" "awsVpcExternalSecurityGroup" {
    filter {
        name                    = "vpc-id"
        values                  = ["${data.aws_vpc.lipowsky-tf-vpc.id}"]
    }
    tags = {
        Name                    = "*external*"
    }
}

data "aws_security_groups" "awsVpcInternalSecurityGroup" {
    filter {
        name                    = "vpc-id"
        values                  = ["${data.aws_vpc.lipowsky-tf-vpc.id}"]
    }
    tags = {
        Name                    = "*internal*"
    }
}

# Retrieve route table ID from VPC for external VLAN

data "aws_route_table" "awsRouteTable" {
    vpc_id                      = "${data.aws_vpc.lipowsky-tf-vpc.id}"
}

# Create ENIs in each of the above subnets & assign security group

resource "aws_network_interface" "mgmt-enis" {
    subnet_id                   = tolist(data.aws_subnet_ids.awsVpcMgmtSubnet.ids)[0]
    security_groups             = data.aws_security_groups.awsVpcMgmtSecurityGroup.ids
    tags = {
        Name                    = "${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}-eth0"
    }
}

resource "aws_network_interface" "external-enis" {
    subnet_id                   = tolist(data.aws_subnet_ids.awsVpcExternalSubnet.ids)[0]
    security_groups             = data.aws_security_groups.awsVpcExternalSecurityGroup.ids
    tags = {
        Name                    = "${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}-eth1"
    }
    private_ips_count           = var.awsSecondaryIpCount
    
    # Write address info to file upon instance creation
    provisioner "local-exec" {
        command = "echo External: ${self.private_ip} >> ${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}.info"
    }
}

resource "aws_network_interface" "internal-enis" {
    subnet_id                   = tolist(data.aws_subnet_ids.awsVpcInternalSubnet.ids)[0]
    security_groups             = data.aws_security_groups.awsVpcInternalSecurityGroup.ids
    tags = {
        Name                    = "${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}-eth2"
    }
    
    # Write address info to file upon instance creation
    provisioner "local-exec" {
        command = "echo Internal: ${self.private_ip} >> ${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}.info"
    }
}

# Create EIPs for management ENIs

resource "aws_eip" "mgmt-eips" {
    network_interface           = aws_network_interface.mgmt-enis.id
    vpc                         = true
    tags = {
        Name                    = "${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}-eth0"
    }
}

# Create EIPs for external ENIs

resource "aws_eip" "external-eips" {
    network_interface           = aws_network_interface.external-enis.id
    vpc                         = true
    tags = {
        Name                    = "${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}-eth1"
    }
}

# Create route for virtual addresses in VPC route table

resource "aws_route" "awsVipRoute" {
    route_table_id              = data.aws_route_table.awsRouteTable.id
    destination_cidr_block      = var.awsVipCidrBlock
    network_interface_id        = aws_network_interface.external-enis.id
}

# Create F5 BIG-IP instances

resource "aws_instance" "f5_bigip" {
    instance_type               = var.awsInstanceType
    ami                         = var.awsAmiId
    key_name                    = var.awsSshKeyName
    network_interface {
        network_interface_id       = aws_network_interface.mgmt-enis.id
        device_index            = 0
    }
    network_interface {
        network_interface_id       = aws_network_interface.external-enis.id
        device_index            = 1
    }
    network_interface {
        network_interface_id       = aws_network_interface.internal-enis.id
        device_index            = 2
    }
    tags = {
        Name                    = "${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}"
    }
    user_data                   = file("cloud-init.yaml")
    
    # Write address info to file upon instance creation
    provisioner "local-exec" {
        command = "echo Mgmt-int: ${self.private_ip} >> ${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}.info"
    }
    provisioner "local-exec" {
        command = "echo Mgmt-ext: ${self.public_ip} >> ${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}.info"
    }
    provisioner "local-exec" {
        command = "echo Public-DNS: ${self.public_dns} >> ${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}.info"
    }
    
    # Delete address info file upon instance destruction - Windows syntax
    provisioner "local-exec" {
        when    = destroy
        command = "del ${var.awsNamePrefix}-${var.awsBigipName}-${var.awsSubnetSuffix}.info"
    }
}