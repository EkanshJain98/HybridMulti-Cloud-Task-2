// aws provider
provider "aws" {
  region     = "ap-southeast-1"
  access_key = "AKIAYLP2XLQTUWWOCVUIU" // I provides wrong key for my safety 
  secret_key = "FMy/90LWT8Rzok0EFEO963U/Z3SUK9dDPjLZP1234"  // I provides wrong key for my safety 
}
//key_pair generator
variable "enter_your_key" {
type=string
} 	
resource "aws_key_pair" "deployer" {
 key_name   = var.enter_your_key
 public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0vcZBbTrbl26/M0tXIcQqSv/Z2APwr595NQuZXVsC3RrnTJPRrvJMXfJ6uBYiWwKN4Wl0V+uAm+Gyon63MDoVMw8SSK/nRb9tH2XCVEApH1oLlzTWrdkar/KcuTKsAqIytMyT6JV+gwH/63np+hGbO1ZM/8Hs5Z+OJn+4Ilc+NlM3hKPLivWtwIenKOxI19UcNBcaby5Ynty9mEDUQxH3VJYp+U8E4ojoyU+rEUnP/dEMr0vgnQ3VD+8A7Sw5IFaSYabeWpU3OWocNrxgbNGN/Uc744avpynOf3tYKc9VYnTuWV4kPuFdvQYkzAVrBFYlzntipGL2+0FqeCJ5HCwL"
}
// aws insatance deploying
resource "aws_instance" "myterraform" {
ami           = "ami-0cd31be676780afa7"
instance_type = "t2.micro"
key_name   = var.enter_your_key
security_groups=["${aws_security_group.ingress_all_test.name}"]
//subnet_id = aws_subnet.main.id
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key= file("C:/Users/Admin/Downloads/mykey12.pem")
    host     = aws_instance.myterraform.public_ip
  }
//remote provisioner
  provisioner "remote-exec" {
    inline = [
     "sudo yum install git -y",
     "sudo yum install httpd php -y",
     "sudo systemctl restart httpd",
     "sudo systemctl enable httpd" 
    ]
  }
  tags = {
    Name = "ekansh_jain_instance"
  }
}

resource "aws_efs_file_system" "efs" {
  creation_token = "my-product"
  tags = {
    Name = "efs_file_system"
  }
}
resource "aws_efs_mount_target" "alpha" {
depends_on=[ 
            aws_instance.myterraform, aws_efs_file_system.efs,aws_security_group.ingress_all_test]

  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = aws_instance.myterraform.subnet_id
  security_groups=["${aws_security_group.ingress_all_test.id}"]
}
//showing some outputs
output "myoutput1"{
value=aws_instance.myterraform.availability_zone
}
output "myoutput2"{
value=aws_instance.myterraform.id 
}

//output "myoutput3"{
//value=aws_ebs_volume.ebs_vol.id
//}
output "myoutput4"{
value=aws_instance.myterraform.security_groups
}
output "myoutput5"{
value=aws_instance.myterraform.vpc_security_group_ids
}
output "myoutput6"{
value=aws_s3_bucket.b.bucket_regional_domain_name
}
output "myoutput7"{
value=aws_s3_bucket.b.bucket
}
output "myoutput8"{
value=aws_cloudfront_distribution.prod_distribution.domain_name
}
//adding rule 
resource "aws_security_group" "ingress_all_test" {
name = "allow-all-sg"

ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 0
    to_port = 22
    protocol = "tcp"
  }
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 0
    to_port = 80
    protocol = "tcp"
  }
// Terraform removes the default rule
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
   
 }
}
//formatting,mounting,import (Clone),restart the httpd service
resource "null_resource"  "myresource"{
depends_on=[ 
aws_efs_mount_target.alpha
]
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key= file("C:/Users/Admin/Downloads/mykey12.pem")
    host     = aws_instance.myterraform.public_ip
  }
 provisioner "remote-exec" {
    inline = [
     "sudo mkfs.ext4 /dev/xvdh",
     "sudo  mount -t nfs4 ${aws_efs_mount_target.alpha.id} /var/www/html",
     "sudo rm -rf /var/www/html/*",
     "sudo git clone https://github.com/technicalej/mytestingfile.git /var/www/html/", 
      "sudo su <<EOF",
      "echo \"${aws_cloudfront_distribution.prod_distribution.domain_name}\" >> /var/www/html/mydesti.txt",
      "EOF",
      "sudo systemctl restart httpd"
    ]
  }
}
// creating s3 bucket
resource "aws_s3_bucket" "b" {
  bucket = "my-bucket-ekushdguk-457989"
  acl    = "public-read"

  tags = {
    Name  = "My-bucky-dgsjkh"
    Environment = "Dev"
  }
}
//importing github file to local directory
resource "null_resource" "cloning" {
depends_on=[ aws_s3_bucket.b]
  provisioner "local-exec" {
    command = "git clone https://github.com/technicalej/mytestingfile.git myimage123"
  }
}
//creating s3-bucket-object 
resource "aws_s3_bucket_object" "object" {
  bucket = "my-bucket-ekushdguk-457989"
  key    = "spider_man.jpg"
  source = "myimages/spider_man.jpg"
  acl="public-read"
depends_on= [aws_s3_bucket.b,null_resource.cloning]
}
//creating cloudfront distribution
resource "aws_cloudfront_distribution" "prod_distribution" {
    origin {
         domain_name = "${aws_s3_bucket.b.bucket_regional_domain_name}"
         origin_id   = "${aws_s3_bucket.b.bucket}"
 
        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }
    # By default, show index.html file
    default_root_object = "index.php"
    enabled = true
    # If there is a 404, return index.html with a HTTP 200 Response
    custom_error_response {
        error_caching_min_ttl = 3000
        error_code = 404
        response_code = 200
        response_page_path = "/index.php"
    }

default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.b.bucket}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE","IN"]
    }
  }

    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}
resource  "null_resource"  "myresource1"{
depends_on=[
            null_resource.myresource,
            aws_cloudfront_distribution.prod_distribution

]
provisioner "local-exec" {
    command = "start chrome ${aws_instance.myterraform.public_ip}"
  }
}