AWS White Papers / Documentation
======================
1.) https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html (More on the AWS VPC)

2.) https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html (Further Reading on AWS's Elastic Cmopute Service)

3.) https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html (More reading on AWS Security Groups)

4.) https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Welcome.html (What is Amazon RDS?)

5.) https://docs.aws.amazon.com/ecr/ (What is Amazon Elastic Container Registery?)

Terraform Resources Documentation
=================================
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources
https://developer.hashicorp.com/terraform/language/backend/s3

The above reference links, will help you better understand how VPC's operate within AWS.
The Terraform documentation will assist you in constructing your Infrastructure as code.

Please note the pre-quisite to this Demo, will require you to have the following:
=================================================================================

--> A AWS Account, with Free Tier Services
--> A S3 Bucket for the Terraform State
--> A DynamoDB Table to manage Terraform State Locking