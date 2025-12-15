// Terraform code referenced from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources
// For a complete list of configuration items you are welcome to visit the above link.
// For a more ind depth read on VPC's, I have included a readme.txt with the AWS Whitepaper which will provide you with any additional context.

# checkov:skip=CKV2_AWS_11:VPC flow logging disabled for demo environment to reduce costs
# checkov:skip=CKV2_AWS_12:Default security group restrictions handled separately
resource "aws_vpc" "demo_application_vpc" {
  cidr_block = "10.0.0.0/16" // = 65, 536 usable addresses within this given network

  tags = {
    Name       = "demo-application-vpc"
    Managed_by = "Terraform"
  }
}

// Restrict the default security group - fixes CKV2_AWS_12
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.demo_application_vpc.id

  # No ingress or egress rules - all traffic blocked
  tags = {
    Name = "demo-vpc-default-sg-restricted"
  }
}

// Optional: Enable VPC Flow Logs (uncomment for production)
// This addresses CKV2_AWS_11 but adds cost, so keeping it commented for demo
# resource "aws_flow_log" "demo_vpc_flow_log" {
#   vpc_id          = aws_vpc.demo_application_vpc.id
#   traffic_type    = "ALL"
#   iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
#   log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
# }

# resource "aws_cloudwatch_log_group" "vpc_flow_log" {
#   name              = "/aws/vpc/demo-application-vpc"
#   retention_in_days = 7
# }

# resource "aws_iam_role" "vpc_flow_log_role" {
#   name = "vpc-flow-log-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = {
#         Service = "vpc-flow-logs.amazonaws.com"
#       }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy" "vpc_flow_log_policy" {
#   role = aws_iam_role.vpc_flow_log_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "logs:CreateLogGroup",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents",
#         "logs:DescribeLogGroups",
#         "logs:DescribeLogStreams"
#       ]
#       Resource = "*"
#     }]
#   })
# }

// Think of an Internet gateway like your Router - giving Internet Access to Your VPC
// A Internet Gateway can be attached to the VPC, this enables internet access.
// Much like before to create the resource, the boolean value must be set to true.

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.demo_application_vpc.id

  tags = {
    Name = "demo-igw"
  }
}

// A public subnet will always have direct access to the internet
// Subnets are associated to a specific route, for an example a route out to the internet or local connectivity.
// These routes are managed by what we refer to as a Route Table.

resource "aws_subnet" "demo_public_subnet_1" {
  vpc_id            = aws_vpc.demo_application_vpc.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "demo_public_subnet_1"
  }
}

// Availability zones are similar to Data Centers, we haouse our applications
// further availibility zones can be added to the above list using the following expressions ["us-east-1b", "us-east-1c"]
// In this demo we will only be deploying one availability zone. 

resource "aws_subnet" "demo_private_subnet_1" {
  vpc_id            = aws_vpc.demo_application_vpc.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "demo_private_subnet_1"
  }
}

resource "aws_subnet" "demo_private_subnet_2" {
  vpc_id            = aws_vpc.demo_application_vpc.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.3.0/24"

  tags = {
    Name = "demo_private_subnet_2"
  }
}

// Private subnets are used to communicate locally within a given network, they have various use cases.
// A subnet characteristics is simply defined on where it has direct access to the internet using an Internet Gateway.
// More on Internet Gateways below

resource "aws_eip" "nat_gw_eip" {
  domain = "vpc"

  tags = {
    Name = "eip-reserved-for-nat-gw"
  }
}

// Our NAT Gateway will ensure that we can provide internet access to our apps or Databases if need be.
// The NAT Gateway is a fully managed service by AWS. 

resource "aws_nat_gateway" "demo_nat_gw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.demo_public_subnet_1.id

  tags = {
    Name = "demo-nat-gateway"
  }
}

// As mentioned above - Route Tables are used to direct network traffic around your VPC. 
// This is the fun part - for example we can now create a Public Route Table (This would be for Public Connectivity - In terms of the Internet)
// We can also create the Private Route Table in terms of Local Network Traffic and not forgetting our NAT gateway!

resource "aws_route_table" "demo_public_route_table" {
  vpc_id = aws_vpc.demo_application_vpc.id

  route {
    cidr_block = "0.0.0.0/0"                              // this is where we declare what CIDR Range traverse in the route table
    gateway_id = aws_internet_gateway.internet_gateway.id // This is how we actually declare the public route table and provide direct internet access to our subnet.
  }

  tags = {
    Name = "demo-public-route-table"
  }
}

resource "aws_route_table" "demo_private_route_table" {
  vpc_id = aws_vpc.demo_application_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"                    // This is where we declare what CIDR Range can traverse in the route table
    nat_gateway_id = aws_nat_gateway.demo_nat_gw.id // Take note of the difference, for the Private Route Table, we adding the Managed NAT Gateway
  }                                                 // Should you see this in a given configuration you know this has to be a private subnet!

  tags = {
    Name = "demo-private-route-table"
  }
}

// Ok Perfect we have alot of the building blocks together to form a fully functional VPC.
// Now that we have created the Route Tables, we must actually ASSOCIATE our newly created subnets to each respective Route Table.
// We achive this using the Terrform Resource called aws_route_table_association

resource "aws_route_table_association" "demo_public_subnet_association" {
  subnet_id      = aws_subnet.demo_public_subnet_1.id
  route_table_id = aws_route_table.demo_public_route_table.id
}

// Just like that we associated the above public subnet to the public route-table - easy peasy japanesy :) 
// Lastly we are going to associate our private subnet to our private route table

resource "aws_route_table_association" "demo_private_subnet_association" {
  subnet_id      = aws_subnet.demo_private_subnet_1.id
  route_table_id = aws_route_table.demo_private_route_table.id
}

resource "aws_route_table_association" "demo_private_subnet_2_association" {
  subnet_id      = aws_subnet.demo_private_subnet_2.id
  route_table_id = aws_route_table.demo_private_route_table.id
}