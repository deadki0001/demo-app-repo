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


  // The above is a simple user data script, we use this to automate the process of installing Nginx and enable Nginx's services.
  user_data = <<-EOF
                #!/bin/bash
                apt-get update -y
                apt-get install -y nginx
                echo "<h1>Welcome to my demo application</h1>" > /var/www/html/index.nginx-debian.html
                systemctl enable nginx
                systemctl start nginx
                EOF

  tags = {
    Name = "demo_app_server"
          }
}


