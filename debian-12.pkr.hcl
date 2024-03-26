
packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}


variable "kubernetes_major" {
  type = string
  default = "1"
}

variable "kubernetes_minor" {
   type = string
   default = "28"
}

variable "boot_wait" {
  type    = string
  default = "10s"
}

variable "disk_size" {
  type    = string
  default = "400G"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "image_name" {
  type   = string
  default = "debian-12-genericcloud-amd64-daily.qcow2"
}

variable "iso_base_url" {
  type    = string
  default = "https://cdimage.debian.org/cdimage/cloud/bookworm/daily/latest"
}

variable "numvcpus" {
  type    = string
  default = "4"
}

source "qemu" "debian" {
  accelerator      = "kvm"
  boot_wait        = "${var.boot_wait}"
  disk_compression = true
  disk_image       = true
  disk_interface   = "virtio"
  disk_size        = "${var.disk_size}"
  format           = "qcow2"
  headless         = "${var.headless}"
  http_content     = {
     "/cloud-init/user-data" = templatefile("${path.root}/http/cloud-init/user-data", { kubernetes_major = "${var.kubernetes_major}", kubernetes_minor = "${var.kubernetes_minor}" } )
     "/cloud-init/meta-data" = file("http/cloud-init/meta-data")
  }
  iso_checksum     = "file:${var.iso_base_url}/SHA512SUMS"
  iso_url          = "${var.iso_base_url}/${var.image_name}"
  net_device       = "virtio-net"
  qemuargs         = [["-smbios", "type=1,serial=ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/cloud-init/"]]
  shutdown_command = "echo 'packer'|sudo systemctl poweroff "
  ssh_password     = "packer"
  ssh_port         = 22
  ssh_timeout      = "5m"
  ssh_username     = "debian"
  vm_name          = "proxmox-k8s-${var.kubernetes_major}.${var.kubernetes_minor}.qcow2"
}

build {
  sources = ["source.qemu.debian"]

  provisioner "shell" {
    execute_command = "echo 'packer'|{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    scripts         = ["scripts/cleanup.sh"]
  }

}
