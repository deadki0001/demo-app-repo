// Terraform code referenced from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources
// For a complete list of configuration items you are welcome to visit the above link.

// For a more ind depth read on AWS's Security Groups, I have included a readme.txt with the AWS Whitepaper which will provide you with any additional context.

// One last note before we begin, you will notice this time around, we will be making use of String literals, Integers and lists. 
// This concept works similar to any other software engineering methodologies, where String literals are enclosed with quotes, Integers are classified for port numbers and list help us group an array of either both strings or integers. 


// The below is a Security Group Resource. 
// You can think of a security group as a Firewall. 
// It allows you to control all external traffic to Resources in AWS, including your EC2 Instance.
// Below we are allowing HTTP and HTTPS traffic

#checkov:skip=CKV2_AWS_5:Security groups defined for when EC2/RDS resources are uncommented
#checkov:skip=CKV_AWS_260:Demo environment requires public HTTP access for web application testing
resource "aws_security_group" "application_security_group" {
  name        = "application-security-group"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.demo_application_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #checkov:skip=CKV_AWS_382:Outbound internet access required for package updates and external API calls
  egress {
    description = "Allow all outbound connections"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application-security-group"
  }
}

#checkov:skip=CKV2_AWS_5:Security groups defined for when EC2/RDS resources are uncommented
resource "aws_security_group" "database_security_group" {
  name        = "database-security-group"
  description = "Allow MySQL traffic from Web Application Server"
  vpc_id      = aws_vpc.demo_application_vpc.id

  ingress {
    description     = "Allow MySQL Traffic from the above Web App Security Group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application_security_group.id]
  }

  #checkov:skip=CKV_AWS_382:Database needs outbound for AWS API calls and managed service communication
  egress {
    description = "Allow all outbound connections"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database-security-group"
  }
}