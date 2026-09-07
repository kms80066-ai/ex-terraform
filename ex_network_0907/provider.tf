# 1. 테라폼 실행 환경 설정 블록
terraform {
  required_providers {
    aws = {
      # 프로바이터 라이브러리 다운로드 경로
      source = "hashicorp/aws"
      # 사용할 버전 정의
      version = "~> 6.0" # 6.0 ~ 7.0 (6.0 이상 7.0 미만의 최신 버전)
    }
  }

  # 협업을 위한 상태 값 공유 저장소 설정
  backend "s3" {
    bucket         = "bipa17-std09-terraform-state-bucket"             # S3 버킷
    key            = "TerraformState/Lab/ex-network/terraform.tfstate" # 버킷 내 저장 경로
    region         = "ca-central-1"                                    # 리전
    dynamodb_table = "std09-lab-lock-table"                            #DynamoDB 테이블
    encrypt        = true
  }
}


provider "aws" {
  region = "ca-central-1"
  default_tags {
    tags = {
      Name  = "std09-vpc"
      Class = "bipa17"
      Owner = "std09"
    }
  }

}
