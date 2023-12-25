resource "aws_security_group" "sg" {
  name        = "monitoring-server-sg"
  description = "Allow 9090 and 3000 ports"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow 9090 port"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow 3000 port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "All traffic"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "web" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_pair
  vpc_security_group_ids = [aws_security_group.sg.id]

  root_block_device {
    volume_size = 25
    volume_type = "gp3"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/users/ag/Downloads/monitoring-server-key.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "prometheus.service"
    destination = "/tmp/prometheus.service"
  }

  provisioner "file" {
    source      = "grafana.repo"
    destination = "/tmp/grafana.repo"
  }

  provisioner "file" {
    source      = "node_exporter.service"
    destination = "/tmp/node_exporter.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo useradd --no-create-home --shell /bin/false prometheus",
      "sudo mkdir -p /data /etc/prometheus",
      "sudo mkdir /var/lib/prometheus",
      "sudo chown prometheus:prometheus /var/lib/prometheus",
      "cd /tmp/",
      "wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz",
      "tar -xvf prometheus-2.47.1.linux-amd64.tar.gz",
      "cd prometheus-2.47.1.linux-amd64",
      "sudo mv console* /etc/prometheus",
      "sudo mv prometheus.yml /etc/prometheus",
      "sudo chown -R prometheus:prometheus /etc/prometheus/ /data/",
      "sudo mv prometheus promtool /usr/local/bin/",
      "sudo chown prometheus:prometheus /usr/local/bin/prometheus",
      "sudo mv /tmp/prometheus.service /etc/systemd/system/",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable prometheus",
      "sudo systemctl start prometheus",
      "sudo mv /tmp/grafana.repo /etc/yum.repos.d/",
      "sudo yum install grafana -y",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable grafana-server",
      "sudo systemctl start grafana-server",
      "sudo useradd --no-create-home --shell /bin/false node_exporter",
      "wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz",
      "tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz",
      "sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/",
      "rm -rf node_exporter*",
      "sudo mv /tmp/node_exporter.service /etc/systemd/system/",
      "sudo systemctl enable node_exporter",
      "sudo systemctl start node_exporter"
    ]
  }

  tags = {
    Name = "Monitoring-Server"
  }
}

resource "aws_eip" "eip" {
  instance = aws_instance.web.id
  domain   = "vpc"

  tags = {
    "Name" = "eip-monitoring-server"
  }
}