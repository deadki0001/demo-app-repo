# ============================================================================
# VPC Configuration - COMPLETE VERSION
# ============================================================================

# -----------------------------------------------------------------------------
# VPC Resource (THIS WAS MISSING!)
# -----------------------------------------------------------------------------
resource "aws_vpc" "demo_application_vpc" {
  cidr_block = "10.0.0.0/16" // = 65,536 usable IP addresses

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "demo-application-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Restrict the default security group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.demo_application_vpc.id

  tags = {
    Name        = "demo-vpc-default-sg-restricted"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
// Think of an Internet gateway like your Router - giving Internet Access to Your VPC
// A Internet Gateway can be attached to the VPC, this enables internet access.
// Much like before to create the resource, the boolean value must be set to true.

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.demo_application_vpc.id

  tags = {
    Name        = "demo-igw"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------
// A public subnet will always have direct access to the internet
// Subnets are associated to a specific route, for an example a route out to the internet or local connectivity.
// These routes are managed by what we refer to as a Route Table.

resource "aws_subnet" "demo_public_subnet_1" {
  vpc_id            = aws_vpc.demo_application_vpc.id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.0/24"

  map_public_ip_on_launch = true

  tags = {
    Name                                     = "demo_public_subnet_1"
    Environment                              = var.environment
    "kubernetes.io/role/elb"                 = "1"
    "kubernetes.io/cluster/demo-eks-cluster" = "shared"
  }
}

// Availability zones are similar to Data Centers, we house our applications
// further availability zones can be added to the above list using the following expressions ["us-east-2b", "us-east-2c"]
// In this demo we will only be deploying one availability zone.

resource "aws_subnet" "demo_private_subnet_1" {
  vpc_id            = aws_vpc.demo_application_vpc.id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name                                          = "demo_private_subnet_1"
    Environment                                   = var.environment
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/demo-eks-cluster"      = "shared"
  }
}

resource "aws_subnet" "demo_private_subnet_2" {
  vpc_id            = aws_vpc.demo_application_vpc.id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.3.0/24"

  tags = {
    Name                                          = "demo_private_subnet_2"
    Environment                                   = var.environment
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/demo-eks-cluster"      = "shared"
  }
}

# -----------------------------------------------------------------------------
# NAT Gateway Resources
# -----------------------------------------------------------------------------
// Private subnets are used to communicate locally within a given network, they have various use cases.
// A subnet characteristics is simply defined on where it has direct access to the internet using an Internet Gateway.
// More on Internet Gateways below

resource "aws_eip" "nat_gw_eip" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name        = "eip-reserved-for-nat-gw"
    Environment = var.environment
  }
}

// Our NAT Gateway will ensure that we can provide internet access to our apps or Databases if need be.
// The NAT Gateway is a fully managed service by AWS.

resource "aws_nat_gateway" "demo_nat_gw" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.demo_public_subnet_1.id

  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name        = "demo-nat-gateway"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------
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
    Name        = "demo-public-route-table"
    Environment = var.environment
  }
}

resource "aws_route_table" "demo_private_route_table" {
  vpc_id = aws_vpc.demo_application_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"                    // This is where we declare what CIDR Range can traverse in the route table
    nat_gateway_id = aws_nat_gateway.demo_nat_gw.id // Take note of the difference, for the Private Route Table, we adding the Managed NAT Gateway
  }                                                 // Should you see this in a given configuration you know this has to be a private subnet!

  tags = {
    Name        = "demo-private-route-table"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Route Table Associations
# -----------------------------------------------------------------------------
// Ok Perfect we have alot of the building blocks together to form a fully functional VPC.
// Now that we have created the Route Tables, we must actually ASSOCIATE our newly created subnets to each respective Route Table.
// We achieve this using the Terraform Resource called aws_route_table_association

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

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.demo_application_vpc.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.demo_public_subnet_1.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value = [
    aws_subnet.demo_private_subnet_1.id,
    aws_subnet.demo_private_subnet_2.id
  ]
}
