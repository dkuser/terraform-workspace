locals {
  user = "ec2-user"
  users = [for u in var.users : join("", regexall("[[:alnum:]]+", u))]
  users_key = join(" ", local.users)
}


data "aws_route53_zone" "zone" {
  name = var.domain
}

data "aws_acm_certificate" "cert" {
  domain   = var.domain
  statuses = ["ISSUED"]
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.vpn_domain
  type    = "A"
  ttl = "60"
  records = [aws_eip.openvpn_eip.public_ip]
}

resource "tls_private_key" "openvpn" {
  algorithm   = "RSA"
}

resource "local_file" "private_key" {
  content         = tls_private_key.openvpn.private_key_pem
  filename        = var.vpn_pem_file
  file_permission = "0600"
}

resource "aws_key_pair" "openvpn" {
  key_name   = "openvpn"
  public_key = tls_private_key.openvpn.public_key_openssh
  tags       = {
    Name = "openvpn key pair"
  }
}

resource "aws_network_interface" "openvpn" {
  subnet_id   = var.subnet_id
  source_dest_check = false
  security_groups = [
    var.security_groups.openvpn,
    var.security_groups.ssh
  ]
}

resource "aws_instance" "openvpn" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.openvpn.key_name

  network_interface {
    network_interface_id = aws_network_interface.openvpn.id
    device_index         = 0
  }

  tags       = {
    Name = "open_vpn instance"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 10
    delete_on_termination = true
  }
}

resource "aws_eip" "openvpn_eip" {
  vpc      = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.openvpn.id
  allocation_id = aws_eip.openvpn_eip.id
  network_interface_id = aws_network_interface.openvpn.id
}

resource "null_resource" "openvpn_bootstrap" {
  triggers = {
    id = aws_instance.openvpn.id
  }

  connection {
    type        = "ssh"
    host        = aws_eip.openvpn_eip.public_ip
    user        = local.user
    port        = "22"
    private_key = tls_private_key.openvpn.private_key_pem
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "curl -O ${var.openvpn_install_script_location}",
      "chmod +x openvpn-install.sh",
      <<EOT
      sudo AUTO_INSTALL=y \
           APPROVE_IP=${aws_eip.openvpn_eip.public_ip} \
           ENDPOINT=${var.vpn_domain} \
           ./openvpn-install.sh
      EOT
      ,
    ]
  }
}

# resource "null_resource" "openvpn_update_users_script" {
#   depends_on = [null_resource.openvpn_bootstrap]

#   triggers = {
#     users = local.users_key
#   }

#   connection {
#     type        = "ssh"
#     host        = aws_eip.openvpn_eip.public_ip
#     user        = local.user
#     port        = "22"
#     private_key = tls_private_key.openvpn.private_key_pem
#     agent       = false
#   }

#   provisioner "file" {
#     source      = "${path.module}/scripts/update_users.sh"
#     destination = "/home/${local.user}/update_users.sh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "chmod +x ~${local.user}/update_users.sh",
#       "sudo ~${local.user}/update_users.sh ${local.users_key}",
#     ]
#   }
# }

# resource "null_resource" "openvpn_download_configurations" {
#   depends_on = [null_resource.openvpn_update_users_script]

#   triggers = {
#     users = local.users_key
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#     mkdir -p ${var.ovpn_config_directory};
#     scp -o StrictHostKeyChecking=no \
#         -o UserKnownHostsFile=/dev/null \
#         -i ${var.vpn_pem_file} ${local.user}@${aws_eip.openvpn_eip.public_ip}:/home/${local.user}/*.ovpn ${var.ovpn_config_directory}/
#     EOT
#   }
# }