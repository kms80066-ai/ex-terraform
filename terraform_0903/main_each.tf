resource "aws_vpc" "std09_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${local.tag_header}vpc"
  }
}

# Public Subnet 생성
resource "aws_subnet" "std09_public_subnet" {
  for_each          = toset(local.azs)
  vpc_id            = aws_vpc.std09_vpc.id
  cidr_block        = var.subnet_cidr[0][each.key]
  availability_zone = each.key
  # Public Subnet 설정
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "${local.tag_header}public-$split("-", each.key)[length(split("-", each.key))-1]"
  }
}


# Private Subnet 생성
resource "aws_subnet" "std09_private_subnet" {
  for_each          = toset(local.azs)
  vpc_id            = aws_vpc.std09_vpc.id
  cidr_block        = var.subnet_cidr[1][each.key]
  availability_zone = each.key
  tags = {
     Name = "${local.tag_header}private-$split("-", each.key)[length(split("-", each.key))-1]"
  }
}



# Internet Gateway 생성
resource "aws_internet_gateway" "std09_igw" {
  vpc_id = aws_vpc.std09_vpc.id

  tags = {
    Name = "${local.tag_header}igw"
  }
}

# NAT 생성을 위한 EIP 생성
resource "aws_eip" "std09_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${local.tag_header}nat-eip"
  }
}

# NAT Gateway 생성
resource "aws_nat_gateway" "std09_nat_gw" {
  allocation_id = aws_eip.std09_nat_eip.id
  subnet_id     = aws_subnet.std09_public_subnet[local.azs[0]].id
  depends_on    = [aws_internet_gateway.std09_igw]

  tags = {
    Name = "${local.tag_header}nat-gw"
  }
}

# Public Route Table 생성
resource "aws_route_table" "std09_public_rt" {
  vpc_id = aws_vpc.std09_vpc.id

  tags = {
    Name = "${local.tag_header}public-rt"
  }
}

# Public 서브넷 라우팅 테이블 연결 (간결한 for_each 적용)
resource "aws_route_table_association" "std09_public_rt_assoc" {
  for_each       = aws_subnet.std09_public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.std09_public_rt.id
}

# resource "aws_route_table_association" "std09_public_rt_assoc" {
#   subnet_id      = aws_subnet.std09_public1a_subnet.id
#   route_table_id = aws_route_table.std09_public_rt.id
# }

# Public과 IGW 라우팅
resource "aws_route" "std09_public_rt_route" {
  route_table_id         = aws_route_table.std09_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.std09_igw.id
}



# Private Route Table 생성 (AZ 개수만큼 자동 생성)
resource "aws_route_table" "std09_private_rt" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.std09_vpc.id

  tags = {
    Name = "${local.tag_header}private-${each.key}-rt"
  }
}


# Private 서브넷과 Private 라우팅 테이블 연결
resource "aws_route_table_association" "std09_private_rt_assoc" {
  for_each       = toset(local.azs)
  subnet_id      = aws_subnet.std09_private_subnet[each.key].id
  route_table_id = aws_route_table.std09_private_rt[each.key].id
}

# Private와 NAT GW 라우팅 규칙
resource "aws_route" "std09_private_rt_route" {
  for_each               = toset(local.azs)
  route_table_id         = aws_route_table.std09_private_rt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.std09_nat_gw.id
}

# security group 생성

# ssh 접속용 생성
resource "aws_security_group" "std09_ssh_sg" {
  name        = "${local.tag_header}ssh-sg"
  description = "Security group for SSH access"
  vpc_id      = aws_vpc.std09_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}ssh-sg"
  }
}

# MySQL 접속용 생성
resource "aws_security_group" "std09_mysql_sg" {
  name        = "${local.tag_header}mysql-sg"
  description = "Security group for MySQL access"
  vpc_id      = aws_vpc.std09_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.tag_header}mysql-sg"
  }
}

# Web 보안 그룹(ALB) 생성
resource "aws_security_group" "std09_ext_alb_sg" {
  name        = "${local.tag_header}ext-alb-sg"
  description = "Security group for ext-alb access"
  vpc_id      = aws_vpc.std09_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.tag_header}ext-alb-sg"
  }
}

# 프라이빗 웹 인스턴스용 보안그룹
resource "aws_security_group" "std09_int_alb_sg" {
  name        = "${local.tag_header}int-alb-sg"
  description = "Security group for int-alb access"
  vpc_id      = aws_vpc.std09_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.tag_header}int-alb-sg"
  }
}

# 보안그룹 규칙 추가: 외부 ALB에서 내부 ALB로의 트래픽 허용
resource "aws_security_group_rule" "std09_int_alb_rule" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  # 규칙을 추가할 보안 그룹의 아이디
  security_group_id = aws_security_group.std09_int_alb_sg.id
  # 소스로 어떤 보안 그룹을 추가할 지, 추가할 보안그룹의 아이디 지정
  source_security_group_id = aws_security_group.std09_ext_alb_sg.id
}

# EKS 워커 노드 그룹용 보안그룹 (필수)
# ==============================================================================
resource "aws_security_group" "std09_eks_node_sg" {
  name        = "${local.tag_header}eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.std09_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}eks-node-sg"
  }
}
# [노드 규칙] 외부 ALB에서 들어오는 트래픽 허용
# AWS Load Balancer Controller(Ingress) 사용 시: NodePort(30000-32767) 또는 특정 타깃 포트(예: 80, 8080) 허용
resource "aws_security_group_rule" "std09_node_from_alb_rule" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  security_group_id        = aws_security_group.std09_eks_node_sg.id
  source_security_group_id = aws_security_group.std09_ext_alb_sg.id
  description              = "Allow traffic from ALB to NodePort services"
}
# (Target Group이 인스턴스 IP 모드(Pod 직접 통신)인 경우 HTTP 포트도 허용
resource "aws_security_group_rule" "std09_node_from_alb_http_rule" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.std09_eks_node_sg.id
  source_security_group_id = aws_security_group.std09_ext_alb_sg.id
  description              = "Allow direct HTTP traffic from ALB to pods"
}

resource "aws_security_group_rule" "std09_cluster_from_alb_https_rule" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.std09_eks_node_sg.id
  source_security_group_id = aws_security_group.std09_ext_alb_sg.id
  description              = "Allow nodes to reach cluster API server"
}

# ============================================
# 테라폼은 선언형 언어, IF문이 없다.
# if문을 대체하는 3항 연산자를 통해 간단한 제어만 가능
# [일반 삼항 연산자] 조건 ? 조건이 참일때의 값 : 조건이 거짓일때의 값
# [다중 삼항 연산자] 조건1 ? 조건1이 참일때의 값 : (
#   조건2 ? 조건2이 참일때의 값 : 조건2이 거짓일때의 값)

resource "aws_instance" "std09-instance" {
  ami           = "ami-02f1c1b3f3eedbd0d"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.std09_public_subnet["ca-central-1a"].id
  count         = local.instance_chk ? 1 : 0

  tags = {
    Name = "std09-${count.index + 1}-instance"
  }
}

# 중첩 삼항
locals {
  instance_type = "default" # nano, micro, small
}

resource "aws_instance" "std09-ec2" {
  ami = "ami-02f1c1b3f3eedbd0d"
  instance_type = local.instance_type == "default" ? "t3.nano" : (
  local.instance_type == "micro" ? "t3.micro" : "t3.small")
  subnet_id = aws_subnet.std09_public_subnet["ca-central-1a"].id


  tags = {
    Name = "std09-2-instance"
  }
}

# =====================================================
# 문자열 함수
output "zfunc_string_upper" {
  value = upper("abcd")
}

output "zfunc_string_lower" {
  value = lower("AbCd")
}

output "zfunc_string_replace" {
  value = replace("abcdb", "b", "K")
}

# 문자열 나누기
# 전체 문자열에서 특정 문자를 기준으로 리스트로 변환
output "zfunc_string_split" {
  value = split("-", "ca-central-1")[length(split("-", "ca-central-1")) - 1]
}

# 문자열 연결
output "zfunc_string_join" {
  value = join("*", split("-", "ca-central-1a"))
}

# ===========================
# for 표현식
output "for" {
  value = [for name in ["ABC", "DeF", "HIj"] : upper(name)]
}

output "num" {
  value = [for num in [131, 4322, 18, 999] : num if num % 2 == 0]
}

