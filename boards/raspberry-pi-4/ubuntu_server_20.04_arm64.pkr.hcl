packer {
  required_plugins {
    git = {
      version = ">=v0.3.2"
      source  = "github.com/ethanmdavidson/git"
    }
  }
}

data "git-commit" "cwd-head" {}

locals {
  git_sha = data.git-commit.cwd-head.hash
}

source "cross" "ubuntu" {
  file_urls             = ["http://cdimage.ubuntu.com/releases/20.04.2/release/ubuntu-20.04.2-preinstalled-server-arm64+raspi.img.xz"]
  file_checksum_url     = "http://cdimage.ubuntu.com/releases/20.04.2/release/SHA256SUMS"
  file_checksum_type    = "sha256"
  file_target_extension = "xz"
  file_unarchive_cmd    = ["xz", "--decompress", "$ARCHIVE_PATH"]
  image_build_method    = "reuse"
  image_path            = "ubuntu-20.04.img"
  image_size            = "3.1G"
  image_type            = "dos"
  image_partitions {
    filesystem   = "fat"
    mountpoint   = "/boot/firmware"
    name         = "boot"
    size         = "256M"
    start_sector = "2048"
    type         = "c"
  }
  image_partitions {
    filesystem   = "ext4"
    mountpoint   = "/"
    name         = "root"
    size         = "2.8G"
    start_sector = "526336"
    type         = "83"
  }
  image_chroot_env             = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
  qemu_binary_source_path      = "/usr/bin/qemu-aarch64-static"
  qemu_binary_destination_path = "/usr/bin/qemu-aarch64-static"
}

build {
  sources = ["source.cross.ubuntu"]

  provisioner "shell" {
    inline = [
      "touch /tmp/test",
      "echo git_sha: ${local.git_sha}"
    ]
  }
}
