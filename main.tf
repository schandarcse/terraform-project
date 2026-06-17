# ==========================
# Configure the AWS provider
# ==========================
provider "aws" {
  # AWS region where resources will be created using variable 'aws_region' for value given in terraform.tvars
  region = var.aws_region
}


# ==========================
# VPC (Virtual Private Cloud)
# ==========================
resource "aws_vpc" "main" {

  # CIDR range for the VPC for given value of variable 'vpc_cidr' in terraform.tvars
  cidr_block = var.vpc_cidr

  # Enables DNS resolution within the VPC
  enable_dns_support = true

  # Assigns DNS hostnames to instances
  enable_dns_hostnames = true

  # Tags for resource identification for given value of string 'environment_name' in terraform.tvars
  tags = {
    Name = "${var.environment_name}-vpc"
  }
}


# ==========================
# Internet Gateway
# ==========================
resource "aws_internet_gateway" "igw" {

  # Attach Internet Gateway to the VPC
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment_name}-igw"
  }
}



# ========== To assign subnet and its availbility zone at same time ==========

# ==========================
# Public Subnet - AZ A
# ==========================
resource "aws_subnet" "subnet_a" {

  # Associate subnet with VPC above
  vpc_id = aws_vpc.main.id

  # CIDR block for subnet A with given value for variable 'public_subnet_a_cidr' in terraform.tvars
  cidr_block = var.public_subnet_a_cidr

  # assign subnet to Availability Zone (e.g. us-east-1a)
  availability_zone = "${var.aws_region}a"

  # Automatically assign public IPs to instances launched here which makes it as PUBLIC subnet
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name}-public-A"
  }
}

# ==========================
# Public Subnet - AZ B
# ==========================
resource "aws_subnet" "subnet_b" {

  # Associate subnet with VPC created above
  vpc_id = aws_vpc.main.id

  # CIDR block for subnet B with given value for variable 'public_subnet_b_cidr' in terraform.tvars
  cidr_block = var.public_subnet_b_cidr

  # assign subnet to Availability Zone (e.g. us-east-1b)
  availability_zone = "${var.aws_region}b"

  # Automatically assign public IPs to instances launched here which makes it as PUBLIC subnet
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name}-public-B"
  }
}


# ==========================
# Private Subnet - AZ C
# ==========================

resource "aws_subnet" "subnet_c" {

  # Associate subnet with VPC created above
  vpc_id = aws_vpc.main.id

  # CIDR block for private subnet with given value for variable 'private_subnet_c_cidr' in terraform.tvars
  cidr_block = var.private_subnet_c_cidr

  # assign subnet to Availability Zone (e.g. us-east-1c)
  availability_zone = "${var.aws_region}c"

  # Do NOT assign public IPs automatically to instances launched here which makes it as PRIVATE subnet
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment_name}-private-C"
  }
}



# ======= To specific AZ value first and then assign AZ to subnet =========

# ======= Public Subnet - AZ P ==========
resource "aws_subnet" "subnet_p" {

  # Associate subnet with VPC create above
  vpc_id = aws_vpc.main.id

  # CIDR block for public subnet with given value for variable 'public_subnet_p_cidr' in terraform.tvars
  cidr_block = var.public_subnet_p_cidr

  # assign to Availability Zone from input variable given to 'subnet_az_p' in terraform.tvars
  availability_zone = var.subnet_az_p

  # Automatically assign public IPs to instances launched here which makes it PUBLIC subnet
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name}-public-P"
  }
}

# ======= Private subnet - AZ Q ========
resource "aws_subnet" "subnet_q" {

  # Associate subnet with VPC create above
  vpc_id = aws_vpc.main.id

  # CIDR block for public subnet with given value for variable 'private_subnet_q_cidr' in terraform.tvars
  cidr_block = var.private_subnet_q_cidr

  # assign to Availability Zone from input variable given to 'subnet_az_q' in terraform.tvars
  availability_zone = var.subnet_az_q

  # Automatically assign public IPs to instances launched here which makes it PRIVATE subnet
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment_name}-private-Q"
  }
}




# ==========================
# Elastic IP for NAT Gateway
# ==========================

resource "aws_eip" "nat_eip" {

  domain = "vpc"

  tags = {
    Name = "${var.environment_name}-nat-eip"
  }
}



# ==========================
# NAT Gateway
# ==========================

resource "aws_nat_gateway" "nat" {

  # Elastic IP associated with NAT Gateway
  allocation_id = aws_eip.nat_eip.id

  # NAT Gateway must be deployed in any of the Public Subnet, in this case it is public subnet A
  subnet_id = aws_subnet.subnet_a.id

  tags = {
    Name = "${var.environment_name}-nat"
  }

  # Ensure Internet Gateway exists first
  depends_on = [
    aws_internet_gateway.igw
  ]
}



# ==========================
# Public Route Table
# ==========================
resource "aws_route_table" "public" {

  # Associate route table with VPC
  vpc_id = aws_vpc.main.id

  # Default route for internet traffic
  route {

    # Destination: Anywhere on the internet
    cidr_block = "0.0.0.0/0"

    # Route traffic through Internet Gateway
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.environment_name}-public-rt"
  }
}


# ==========================
# Private Route Table
# ==========================

resource "aws_route_table" "private" {

  # Associate route table with VPC
  vpc_id = aws_vpc.main.id

  # Default route for internet-bound traffic
  route {

    # Destination: Anywhere on the internet
    cidr_block = "0.0.0.0/0"

    # Route traffic through NAT Gateway
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.environment_name}-private-rt"
  }
}


# ==========================
# Route Table Associations
# ==========================

# Associate subnet A with public route table
resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public.id
}

# Associate subnet B with public route table
resource "aws_route_table_association" "subnet_b_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public.id
}

# Associate subnet C with private route table
resource "aws_route_table_association" "subnet_c_association" {
  subnet_id      = aws_subnet.subnet_c.id
  route_table_id = aws_route_table.private.id
}

# Associate subnet P with public route table
resource "aws_route_table_association" "subnet_p_association" {
  subnet_id      = aws_subnet.subnet_p.id
  route_table_id = aws_route_table.public.id
}

# Associate subnet Q with private route table
resource "aws_route_table_association" "subnet_q_association" {
  subnet_id      = aws_subnet.subnet_q.id
  route_table_id = aws_route_table.private.id
}


# ==========================
# Security Group for EC2
# ==========================
resource "aws_security_group" "ec2_sg" {

  # Security group name
  name = "${var.sg_name}-ec2-sg"

  # Description shown in AWS console
  description = "Security group for EC2 instances"

  # Attach SG to VPC
  vpc_id = aws_vpc.main.id

  # Allow HTTP traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow RDP access from anywhere
  # In production, restrict to your IP
  ingress {
    from_port   = 3389
    to_port     = 3380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from anywhere
  # In production, restrict to your IP
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Allow outbound traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"   # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.sg_name}-ec2-sg"
  }
}


# ==========================
# Security Group for ALB
# ==========================
resource "aws_security_group" "alb_sg" {

  name        = "${var.environment_name}-alb-sg"
  description = "Security group for Application Load Balancer"

  # Attach SG to VPC
  vpc_id = aws_vpc.main.id

  # Allow HTTP requests to ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS requests to ALB
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ALB outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment_name}-alb-sg"
  }
}

# ==========================
# Application Load Balancer
# ==========================
resource "aws_lb" "alb" {

  # Load balancer name
  name = "${var.environment_name}-alb"

  # Internet-facing ALB
  internal = false

  # Type of load balancer
  load_balancer_type = "application"

  # Attach ALB security group
  security_groups = [aws_security_group.alb_sg.id]

  # Deploy ALB across three subnets
  subnets = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id,
    aws_subnet.subnet_p.id
  ]

  tags = {
    Name = "${var.environment_name}-alb"
  }
}

# ==========================
# Target Group
# ==========================
resource "aws_lb_target_group" "target_group" {

  # Target group name
  name = "${var.environment_name}-tg"

  # Application listens on port 80
  port = 80

  # HTTP protocol
  protocol = "HTTP"

  # VPC where targets reside
  vpc_id = aws_vpc.main.id

  # Health check configuration
  health_check {

    # Endpoint to check
    path = "/"

    # Protocol used
    protocol = "HTTP"

    # Healthy response code
    matcher = "60"

    # Check every 5 seconds
    interval = 5

    # Timeout after 5 seconds
    timeout = 5

    # 3 successful checks = healthy
    healthy_threshold = 3

    # 5 failed checks = unhealthy
    unhealthy_threshold = 4
  }

  tags = {
    Name = "${var.environment_name}-tg"
  }
}

# ==========================
# ALB Listener
# ==========================
resource "aws_lb_listener" "alb_listener" {

  # ALB ARN
  load_balancer_arn = aws_lb.alb.arn

  # Listen on HTTP port 80
  port = 80

  protocol = "HTTP"

  # Forward requests to target group
  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.target_group.arn
  }
}



# ====== Create Launch Template only with below details ========
# ====== 1. AMI ID ========
# ====== 2. key pair =======
# ====== 3. User Data =======
# ====== remaining values will be default as input will be given during EC2 launch from template ========


# ==========================================
# Get Default VPC
# ==========================================

data "aws_vpc" "default" {
  default = true
}

# ==========================================
# Get Default Security Group
# ==========================================

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}


# ==========================================
# Launch Template
# ==========================================

resource "aws_launch_template" "launch_template" {

  # Template name
  name = "${var.OS_name}-template"

  # AMI ID
  image_id = var.ami_id

  # Key Pair
  key_name = var.key_name

  # Default instance type
  instance_type = var.instance_type

  network_interfaces {

    # Assign Public IP
    associate_public_ip_address = true

    # Default Security Group
    security_groups = [
      data.aws_security_group.default.id
    ]
  }

# ===== Windows User Data =====

  user_data = base64encode(<<-EOF
<powershell>

# Install IIS
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# Get IMDSv2 Token
$token = Invoke-RestMethod -Method PUT `
    -Uri "http://169.254.169.254/latest/api/token" `
    -Headers @{"X-aws-ec2-metadata-token-ttl-seconds"="21600"}

# Get EC2 Metadata
$instanceId = Invoke-RestMethod `
    -Uri "http://169.254.169.254/latest/meta-data/instance-id" `
    -Headers @{"X-aws-ec2-metadata-token"=$token}

$privateIp = Invoke-RestMethod `
    -Uri "http://169.254.169.254/latest/meta-data/local-ipv4" `
    -Headers @{"X-aws-ec2-metadata-token"=$token}

$publicDns = Invoke-RestMethod `
    -Uri "http://169.254.169.254/latest/meta-data/public-hostname" `
    -Headers @{"X-aws-ec2-metadata-token"=$token}

# Create HTML page
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>AWS EC2 IIS Server</title>
</head>
<body>
    <h1>Windows EC2 IIS Web Server</h1>

    <table border="1" cellpadding="10">
        <tr>
            <th>Parameter</th>
            <th>Value</th>
        </tr>
        <tr>
            <td>Instance ID</td>
            <td>$instanceId</td>
        </tr>
        <tr>
            <td>Private IP Address</td>
            <td>$privateIp</td>
        </tr>
        <tr>
            <td>Public DNS Name</td>
            <td>$publicDns</td>
        </tr>
    </table>

</body>
</html>
"@

# Save HTML page
$html | Out-File "C:\\inetpub\\wwwroot\\index.html" -Encoding UTF8

# Start IIS
Start-Service W3SVC
Set-Service W3SVC -StartupType Automatic

</powershell>
EOF
  )


  tags = {
    Name = "${var.OS_name}-template"
  }
}





# ==========================
# Auto Scaling Group (ASG)
# ==========================
resource "aws_autoscaling_group" "asg" {

  # ASG name
  name = "${var.environment_name}-asg"

  # Deploy instances across all three subnets
  vpc_zone_identifier = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id,
    aws_subnet.subnet_p.id
  ]

  # Desired number of instances
  desired_capacity = var.desired_capacity

  # Minimum instances
  min_size = var.min_size

  # Maximum instances
  max_size = var.max_size

  # Launch template used by ASG
  launch_template {
    id = aws_launch_template.launch_template.id

    # Use latest template version
    version = "$Latest"
  }

  # Register instances with ALB target group
  target_group_arns = [aws_lb_target_group.target_group.arn]

  # Use ELB health checks
  health_check_type = "ELB"

  # Wait 5 minutes before health evaluation
  health_check_grace_period = 300

  # Tag instances launched by ASG
  tag {
    key = "Name"

    value = "${var.environment_name}-asg-instance"

    propagate_at_launch = true
  }
}

# ==========================
# Auto Scaling Policy
# ==========================
resource "aws_autoscaling_policy" "cpu_scaling_policy" {

  # Scaling policy name
  name = "${var.environment_name}-cpu-scaling-policy"

  # Attach policy to ASG
  autoscaling_group_name = aws_autoscaling_group.asg.name

  # Target tracking policy
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {

    # Monitor average CPU utilization
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    # Maintain average CPU around 70%
    target_value = 70.0
  }
}