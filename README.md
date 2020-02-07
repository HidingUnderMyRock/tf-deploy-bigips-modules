# tf-deploy-bigips-modules

## Description

This Terraform module is used to deploy multiple BIG-IPs in an AWS VPC.

The module ./modules/bigip_cluster/main.tf will create a pair of BIG-IPs, with each instance residing in the same availability zone.

The module ./modules/bigip_standalone/main.tf will create a single BIG-IP in the designated availability zone.

Variables are used within each child module to allow flexible naming, etc.  Check the README for each child module for a description of the variables.

In addition, the script uses cloud-init to download and install both the [F5 Declarative Onboarding](https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/) and [F5 Cloud Failover](https://clouddocs.f5networks.net/products/extensions/f5-cloud-failover/latest/) extensions on every BIG-IP instance created.

A wildcard device certificate and key are installed on the device, along with a CA certificate to simplify establishing iQuery device trusts for GSLB.
