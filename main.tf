module "cluster-az1" {
    source = "./modules/bigip_cluster"
    awsVpcName              = "lipowsky-vpc"
    awsSubnetSuffix         = "az1"
    awsNamePrefix           = "lipowsky-tf"
    awsClusterName          = "ltm-east"
    awsSshKeyName           = "lipowsky-aws"
    awsRegion               = "us-east-2"
    awsAmiId                = "ami-0917a22a0995b3f87"
    awsInstanceType         = "m5.2xlarge"
    awsSecondaryIpCount     = 0
    awsVipCidrBlock         = "192.168.10.0/24"
}

module "cluster-az2" {
    source = "./modules/bigip_cluster"
    awsVpcName              = "lipowsky-vpc"
    awsSubnetSuffix         = "az2"
    awsNamePrefix           = "lipowsky-tf"
    awsClusterName          = "ltm-west"
    awsSshKeyName           = "lipowsky-aws"
    awsRegion               = "us-east-2"
    awsAmiId                = "ami-0917a22a0995b3f87"
    awsInstanceType         = "m5.2xlarge"
    awsSecondaryIpCount     = 0
    awsVipCidrBlock         = "192.168.11.0/24"
}

module "standalone-az1" {
    source = "./modules/bigip_standalone"
    awsVpcName              = "lipowsky-vpc"
    awsSubnetSuffix         = "az1"
    awsNamePrefix           = "lipowsky-tf"
    awsBigipName            = "gslb-east"
    awsSshKeyName           = "lipowsky-aws"
    awsRegion               = "us-east-2"
    awsAmiId                = "ami-0917a22a0995b3f87"
    awsInstanceType         = "m5.2xlarge"
    awsSecondaryIpCount     = 0
    awsVipCidrBlock         = "192.168.12.0/24"
}

module "standalone-az2" {
    source = "./modules/bigip_standalone"
    awsVpcName              = "lipowsky-vpc"
    awsSubnetSuffix         = "az2"
    awsNamePrefix           = "lipowsky-tf"
    awsBigipName            = "gslb-west"
    awsSshKeyName           = "lipowsky-aws"
    awsRegion               = "us-east-2"
    awsAmiId                = "ami-0917a22a0995b3f87"
    awsInstanceType         = "m5.2xlarge"
    awsSecondaryIpCount     = 0
    awsVipCidrBlock         = "192.168.13.0/24"
}
