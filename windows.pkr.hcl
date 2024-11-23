packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-proxmox
    proxmox = {
      version = "1.2.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "source_template" {
  type    = string
  default = "template-windows-2022-uefi"
}

variable "proxmox_node" {
  type    = string
  default = env("PROXMOX_NODE")
}

source "proxmox-clone" "windows" {
  clone_vm                 = var.source_template
  template_name            = "template-packer-windows-2022-uefi"
  template_description     = "See https://github.com/rgl/packer-proxmox-windows-example"
  tags                     = "packer-windows-2022-uefi;template"
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node
  cpu_type                 = "host"
  cores                    = 2
  memory                   = 4 * 1024
  scsi_controller          = "virtio-scsi-single"
  task_timeout             = "10m"
  os                       = "win11"
  communicator             = "ssh"
  ssh_username             = "vagrant"
  ssh_password             = "vagrant"
  ssh_timeout              = "60m"
}

build {
  sources = [
    "source.proxmox-clone.windows",
  ]

  provisioner "powershell" {
    use_pwsh = true
    script   = "provision-chocolatey.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "provision-generalize.ps1"
  }
}
