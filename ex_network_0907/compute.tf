resource "aws_instance" "std09-ex-instance" {
  # ami
  ami = "ami-02f1c1b3f3eedbd0d"
  # 인스턴스 타입
  instance_type = "t3.nano"
  # 키페어
  key_name = "std09-keypair"
  # 볼륨
  root_block_device {
    volume_size           = 20    # 단위 GB
    volume_type           = "gp3" # 볼륨 타입(최신 가성비 타입인 gp3 권장)
    delete_on_termination = true  # 인스턴스 삭제시 볼륨 삭제
    tags = {
      Name = "${local.tag_header}ex-volume"
    }
  }
  # 서브넷
  subnet_id = aws_subnet.std09_public_subnet["ca-central-1a"].id
  # 보안그룹
  vpc_security_group_ids = [
    aws_security_group.std09_ssh_sg.id,
    aws_security_group.std09_ext_alb_sg.id
  ]
  # user data
  user_data = <<-EOF
    #!/bin/bash
    apt update
    apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "<h1>Hello from EC2 First Nginx</h1>" > /var/www/html/index.html
    EOF

  tags = {
    Name = "${local.tag_header}ex-instance"
  }
}

output "instance_public_ip" {
  value = aws_instance.std09-ex-instance.public_ip
}

# ===================================================
# AMI 이미지 생성
resource "aws_ami_from_instance" "std09_ex_nginx_ami" {
  name               = "std09-ex-nginx-ami"
  source_instance_id = aws_instance.std09-ex-instance.id

  # 재부팅하여 이미지 생성(권장): false
  snapshot_without_reboot = false

  tags = {
    Name = "${local.tag_header}ex-nginx-ami"
  }

}

# ======================================================
# Key Pair 생성
resource "aws_key_pair" "std09_lab_key" {
  key_name = "std09-lab-key"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = {
    Name = "${local.tag_header}lab-key"
  }
}