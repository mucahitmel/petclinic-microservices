provider "aws" {
  region  = "us-east-1"
}

variable "muco-sec-gr-mutual" {
  default = "muco-petclinic-k8s-mutual-sec-group"
}

variable "muco-sec-gr-k8s-master" {
  default = "muco-petclinic-k8s-master-sec-group"
}

variable "muco-sec-gr-k8s-worker" {
  default = "muco-petclinic-k8s-worker-sec-group"
}

data "aws_vpc" "name" {
  default = true
}

resource "aws_security_group" "muco-petclinic-mutual-sg" {
  name = var.muco-sec-gr-mutual
  vpc_id = data.aws_vpc.name.id

  ingress {
    protocol = "tcp"
    from_port = 10250
    to_port = 10250
    self = true
  }

    ingress {
    protocol = "udp"
    from_port = 8472
    to_port = 8472
    self = true
  }

    ingress {
    protocol = "tcp"
    from_port = 2379
    to_port = 2380
    self = true
  }

}

resource "aws_security_group" "muco-petclinic-kube-worker-sg" {
  name = var.muco-sec-gr-k8s-worker
  vpc_id = data.aws_vpc.name.id


  ingress {
    protocol = "tcp"
    from_port = 30000
    to_port = 32767
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "muco-kube-worker-secgroup"
  }
}

resource "aws_security_group" "muco-petclinic-kube-master-sg" {
  name = var.sec-gr-k8s-master
  vpc_id = data.aws_vpc.name.id

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 6443
    to_port = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 10257
    to_port = 10257
    self = true
  }

  ingress {
    protocol = "tcp"
    from_port = 10259
    to_port = 10259
    self = true
  }

  ingress {
    protocol = "tcp"
    from_port = 30000
    to_port = 32767
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "kube-master-secgroup"
  }
}

resource "aws_iam_role" "muco-petclinic-master-server-s3-role" {
  name               = "muco-petclinic-master-server-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
}

resource "aws_iam_instance_profile" "muco-petclinic-master-server-profile" {
  name = "muco-petclinic-master-server-profile"
  role = aws_iam_role.muco-petclinic-master-server-s3-role.name
}

resource "aws_instance" "muco-kube-master" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t3a.medium"
    iam_instance_profile = aws_iam_instance_profile.muco-petclinic-master-server-profile.name
    vpc_security_group_ids = [aws_security_group.muco-petclinic-kube-master-sg.id, aws_security_group.muco-petclinic-mutual-sg.id]
    key_name = "clarus"
    subnet_id = "subnet-063ee0e7b3f39d12f"  # select own subnet_id of us-east-1a
    availability_zone = "us-east-1a"
    tags = {
        Name = "muco-kube-master"
        Project = "tera-kube-ans"
        Role = "master"
        Id = "1"
        environment = "dev"
    }
}

resource "aws_instance" "muco-worker-1" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t3a.medium"
    vpc_security_group_ids = [aws_security_group.muco-petclinic-kube-worker-sg.id, aws_security_group.muco-petclinic-mutual-sg.id]
    key_name = "clarus"
    subnet_id = "subnet-063ee0e7b3f39d12f"  # select own subnet_id of us-east-1a
    availability_zone = "us-east-1a"
    tags = {
        Name = "worker-1"
        Project = "tera-kube-ans"
        Role = "worker"
        Id = "1"
        environment = "dev"
    }
}

resource "aws_instance" "muco-worker-2" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t3a.medium"
    vpc_security_group_ids = [aws_security_group.muco-petclinic-kube-worker-sg.id, aws_security_group.muco-petclinic-mutual-sg.id]
    key_name = "clarus"
    subnet_id = "subnet-063ee0e7b3f39d12f"  # select own subnet_id of us-east-1a
    availability_zone = "us-east-1a"
    tags = {
        Name = "worker-2"
        Project = "tera-kube-ans"
        Role = "worker"
        Id = "2"
        environment = "dev"
    }
}

output kube-master-ip {
  value       = aws_instance.muco-kube-master.public_ip
  sensitive   = false
  description = "public ip of the kube-master"
}

output worker-1-ip {
  value       = aws_instance.muco-worker-1.public_ip
  sensitive   = false
  description = "public ip of the worker-1"
}

output worker-2-ip {
  value       = aws_instance.muco-worker-2.public_ip
  sensitive   = false
  description = "public ip of the worker-2"
}