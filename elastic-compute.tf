// VPC Module reterived from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources
// For a complete list of configuration items you are welcome to visit the above link.




// Now that we have created a security group to protect our EC2 from Bad Actors
// We can create the EC2 Resource. 

resource "aws_instance" "demo_app_server" {
  ami                         = "ami-04b4f1a9cf54c11d0"                            // an AMI, otherwise known as an Amazon Machine Image, This is pre-built software, such as Ubuntu, Windows and EC2. 
  instance_type               = "t2.micro"                                         // Instance Types typically refer too the Machine Specifications, better put Compute Resources, there are a number of Instance Types, which vary depending on your Use case or Workload needs. 
  subnet_id                   = aws_subnet.demo_public_subnet_1.id                 // Here we are referencing Instance placement, this is important, should you be launching a webserver that needs to be public facing as in this example.
  vpc_security_group_ids      = [aws_security_group.application_security_group.id] // Here we are associating the above security group to the actual EC2 Instance to protect the server from bad actors.
  associate_public_ip_address = true                                               // We need our server to be accessible from the Internet, so we are using a boolean of true as to get AWS to provide us with a Public IP We can source the server from. 


  // User data scrippt to ensure our image pushed via ECR is utlized on our EC2 Instance
  user_data = <<-EOF
      #!/bin/bash
      apt-get update -y
      apt-get install -y awscli docker.io
      systemctl enable docker
      systemctl start docker

      # Get AWS account ID for ECR repository URL
      AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
      AWS_REGION=${aws_db_instance.mysql.region}

      # Get RDS endpoint and credentials
      DB_HOST="${aws_db_instance.mysql.address}"
      DB_NAME="${aws_db_instance.mysql.db_name}"
      DB_USER="admin" # Default master username
      DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ${aws_db_instance.mysql.master_user_secret[0].secret_arn} --query SecretString --output text | jq -r '.password')

      # Login to ECR and pull the latest image
      aws ecr get-login-password --region ${aws_db_instance.mysql.region} | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.${aws_db_instance.mysql.region}.amazonaws.com

      # Run the container with environment variables for database connection
      docker run -d -p 80:80 \
        -e DB_HOST=$DB_HOST \
        -e DB_NAME=$DB_NAME \
        -e DB_USER=$DB_USER \
        -e DB_PASSWORD=$DB_PASSWORD \
        $AWS_ACCOUNT_ID.dkr.ecr.${aws_db_instance.mysql.region}.amazonaws.com/demo-app-images:latest
      EOF

  tags = {
    Name = "demo_app_server"
          }
}


