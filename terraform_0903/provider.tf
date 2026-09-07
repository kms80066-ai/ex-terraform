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
  #   required_providers {
  #     google = {
  #       # 프로바이터 라이브러리 다운로드 경로
  #       source = "hashicorp/google"
  #       # 사용할 버전 정의
  #       version = "~> 5.0" # 5.0 ~ 6.0 (5.0 이상 6.0 미만의 최신 버전)
  #     }
  #   }
  # 협업을 위한 상태 값 공유 저장소 설정
  #   backend "s3" {
  #     bucket = "value"
  #     key = "value"
  #     region = "ca-central-1"
  #     dynamodb_table = "value"
  #     encrypt = true

  #   }
}


provider "aws" {
  region = "ca-central-1"
  default_tags {
    tags = {
      Name = "std09-vpc"
      Class = "bipa17"
      Owner = "std09"
    }
  }

}
