output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "s3_bucket_name" {
  description = "Application S3 bucket name"
  value       = aws_s3_bucket.app.bucket
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}