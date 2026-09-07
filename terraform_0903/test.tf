# resource "aws_instance" "this" {
#   ami           = "ami-02f1c1b3f3eedbd0d"
#   instance_type = "t3.nano"
#   subnet_id     = "subnet-0177679fdeec8513c"
#   count         = 2
#   tags = {
#     Name = "test${count.index + 1}-instance"
#   }
# }

# resource "aws_instance" "this" {
#   ami           = "ami-02f1c1b3f3eedbd0d"
#   instance_type = "t3.nano"
#   subnet_id     = "subnet-0177679fdeec8513c"
#   for_each      = toset(["logs", "media", "backups"])
#   tags = {
#     Name = "test-${each.key}-instance"
#   }
# }

# resource "aws_instance" "this" {
#   ami           = "ami-02f1c1b3f3eedbd0d"
#   instance_type = "t3.nano"
#   subnet_id     = "subnet-0177679fdeec8513c"
#   for_each = {
#     "a" = "logs"
#     "b" = "media"
#     "c" = "backups"
#   }
#   tags = {
#     Name = "test-${each.value}-instance"
#   }
# }


# output "prt_instance" {
#   value = aws_instance.this["c"].tags
# }

