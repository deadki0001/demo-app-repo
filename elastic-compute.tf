// VPC Module reterived from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources
// For a complete list of configuration items you are welcome to visit the above link.




// Now that we have created a security group to protect our EC2 from Bad Actors
// We can create the EC2 Resource. 
// Utilizing a role, to securely give the instance access to login into ECR. 

resource "aws_iam_role" "demo_app_role" {
  name = "demo-app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

// Inline policy attached to EC2 IAM role
resource "aws_iam_role_policy" "demo_app_policy" {
  name = "demo-app-policy"
  role = aws_iam_role.demo_app_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "rds:DescribeDBInstances",
          "secretsmanager:GetSecretValue",
          "sts:GetCallerIdentity"
        ],
        Resource = "*"
      }
    ]
  })
}

// IAM Instance Profile (needed to attach role to EC2)
resource "aws_iam_instance_profile" "demo_app_instance_profile" {
  name = "demo-app-instance-profile"
  role = aws_iam_role.demo_app_role.name
}

resource "aws_instance" "demo_app_server" {
  ami                         = "ami-04b4f1a9cf54c11d0"                            // an AMI, otherwise known as an Amazon Machine Image, This is pre-built software, such as Ubuntu, Windows and EC2. 
  instance_type               = "t2.micro"                                         // Instance Types typically refer too the Machine Specifications, better put Compute Resources, there are a number of Instance Types, which vary depending on your Use case or Workload needs. 
  subnet_id                   = aws_subnet.demo_public_subnet_1.id                 // Here we are referencing Instance placement, this is important, should you be launching a webserver that needs to be public facing as in this example.
  vpc_security_group_ids      = [aws_security_group.application_security_group.id] // Here we are associating the above security group to the actual EC2 Instance to protect the server from bad actors.
  associate_public_ip_address = true                                               // We need our server to be accessible from the Internet, so we are using a boolean of true as to get AWS to provide us with a Public IP We can source the server from. 
  iam_instance_profile        = aws_iam_instance_profile.demo_app_instance_profile.name  // Associating Role with Instance

  // User data scrippt to ensure our image pushed via ECR is utlized on our EC2 Instance
user_data = templatefile("${path.module}/user_data.sh", {
    DB_HOST = aws_db_instance.mysql.address
    DB_NAME = aws_db_instance.mysql.db_name
    DB_USER = "admin"
})


  tags = {
    Name = "demo_app_server"
  }
}

