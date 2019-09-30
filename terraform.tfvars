aws_profile       = "default"
aws_region        = "us-east-1"

db_instance_class = "db.t2.micro"
dbname		        = "my_db"
dbuser		        = "my_db_user"
dbpassword	      = "my_db_pass"
db_port           = "9043"

key_name          = "id_rsa"
public_key_path   = "C:/Users/Sergio_Deras/.ssh/id_rsa.pub"
dev_instance_type = "t2.micro"
dev_ami		        = "ami-b73b63a0"
ssh_port          = "22"
http_port         = "8080"

cidrs             = {
  vpc         = "10.1.0.0/16"
  web_subnet	= "10.1.1.0/24"
  app_subnet  = "10.1.2.0/24"
  rds1		    = "10.1.3.0/24"
  rds2		    = "10.1.4.0/24"
}
