// Terraform code referenced from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources
// For a complete list of configuration items you are welcome to visit the above link.
// For a more ind depth read on Amazon RDS, I have included a readme.txt with the AWS Whitepaper which will provide you with any additional context.



// Here we can now generate our Database using the Free Tier MySQL option 
resource "aws_db_instance" "mysql" {
  identifier                      = "demo-database"
  engine                          = "mysql"
  engine_version                  = "8.0"
  instance_class                  = "db.t3.micro"
  allocated_storage               = 20
  max_allocated_storage           = 30
  multi_az                        = false
  storage_encrypted               = true
  db_subnet_group_name            = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.database_security_group.id]
  apply_immediately               = true
  db_name                         = "demodb"
  username                        = "admin"
  manage_master_user_password     = true
  deletion_protection             = true
  final_snapshot_identifier       = true
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_enhanced_monitoring.arn
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
}

// Retrieve the password from AWS Secrets Manager
data "aws_secretsmanager_secret" "db_secret" {
  name = aws_db_instance.mysql.master_user_secret[0].secret_arn

  // Ensure Terraform waits for the RDS instance to be created first
  depends_on = [aws_db_instance.mysql]  
}

// Because we are letting AWS Generate our Password for us - we are fetching the password in the below data block.
// Data blocks are typically used to fetch resources from AWS that are commonly not generated in Terraform
// This is why we have created the necessary depends on blocks to ensure the secret is created prior to performing any further actions.
data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id

  // Ensures Terraform waits for the secret to be created first
  depends_on = [data.aws_secretsmanager_secret.db_secret]
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "demo-db-subnet-group"
  subnet_ids = [aws_subnet.demo_private_subnet_1.id, aws_subnet.demo_private_subnet_2.id] // Associating RDS with the Private Subnet
  tags = {
    Name = "Demo DB Subnet Group"
  }
}


// Generating the Policy to Allow AWS to assume the RDS Monitoring Role service.
data "aws_iam_policy_document" "monitoring_rds_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

// Generate the role to associate to the database for the Enhanced Monitoring Feature (This is for system level metrics)
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "rds-enhanced-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_rds_assume_role.json
}


// Associating the Managed AWS Permission set to the IAM role we generated
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

