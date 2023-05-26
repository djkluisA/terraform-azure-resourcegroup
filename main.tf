
# Declaración de variables
variable "address_space" {}
variable "address_prefixes" {}
variable "private_ip_address" {}

# Configuración del proveedor de AWS
provider "aws" {
  region = "us-east-1"
  skip_provider_registration = true
}

# Creación de la red virtual
resource "aws_vpc" "vnet1" {
  cidr_block = var.address_space
}

# Creación de la subred virtual
resource "aws_subnet" "sbnet1" {
  vpc_id     = aws_vpc.vnet1.id
  cidr_block = var.address_prefixes
}

# Creación del grupo de seguridad
resource "aws_security_group" "sg1" {
  name_prefix = "sg1"
  vpc_id      = aws_vpc.vnet1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creación de la clave privada
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Creación del servicio de almacenamiento de claves
resource "aws_kms_key" "publicclave" {
  description = "Public key"
}

resource "aws_kms_key" "secretclave" {
  description = "Secret key"
}

# Configuración adicional del servicio de almacenamiento de claves
resource "aws_kms_alias" "publicclave_alias" {
  name          = "alias/publicclave"
  target_key_id = aws_kms_key.publicclave.key_id
}

resource "aws_kms_alias" "secretclave_alias" {
  name          = "alias/secretclave"
  target_key_id = aws_kms_key.secretclave.key_id
}

# Creación de la instancia EC2
resource "aws_instance" "vm1" {
  ami           = "ami-0ec021424fb596d6c"
  instance_type = "t2.micro"
  key_name      = aws_kms_key.publicclave_alias.target_key_id
  subnet_id     = aws_subnet.sbnet1.id
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
  }

  ebs_block_device {
    volume_type = "t2.micro"
  }

  tags = {
    Name = "vm1"
  }

  # Configuración del usuario
  connection {
    type        = "ssh"
    user        = "awsuser"
    private_key = tls_private_key.private_key.private_key_pem
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y apache2",
      "sudo systemctl start apache2",
      "sudo systemctl enable apache2"
    ]
  }
}
