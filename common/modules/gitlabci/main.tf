resource "tls_private_key" "ci" {
  algorithm   = "RSA"
}

resource "local_file" "private_key" {
  content         = tls_private_key.ci.private_key_pem
  filename        = "ssh_keys/${var.environmemnt}.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "ci" {
  key_name   = "ci"
  public_key = tls_private_key.ci.public_key_openssh
  tags       = {
    Name = "gitlab runner key pair"
  }
}

module "gitlab-runner" {
  source  = "npalm/gitlab-runner/aws"
  version = "4.25.0"

  aws_region     = var.region
  environment    = var.environmemnt
  ssh_key_pair = aws_key_pair.ci.key_name

  vpc_id                   = var.vpc_id
  subnet_ids_gitlab_runner = var.subnet_ids_gitlab_runner
  subnet_id_runners        = var.subnet_id_runners

  runners_name       = "CI/CD runner"
  runners_gitlab_url = "https://gitlab.com/"

  gitlab_runner_registration_config = {
    registration_token = var.gitlab_runner_registration_token
    tag_list           = var.ci_prefix
    description        = "CI/CD runners"
    locked_to_project  = var.locked_to_project
    run_untagged       = var.run_untagged
    maximum_timeout    = var.maximum_timeout
  }

  runners_off_peak_timezone   = "Europe/Amsterdam"
  runners_off_peak_idle_count = 0
  runners_off_peak_idle_time  = 60
  runners_off_peak_periods    = "[\"* * 0-9,17-23 * * mon-fri *\", \"* * * * * sat,sun *\"]"

  gitlab_runner_version        = var.gitlab_runner_version
  docker_machine_instance_type = var.docker_machine_instance_type
  instance_type                = var.instance_type
  runners_use_private_address  = "false"
}