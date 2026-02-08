packer {
  required_plugins {
    git = {
      version = ">=v0.3.2"
      source  = "github.com/ethanmdavidson/git"
    }
  }
}

source "cross" "arch" {
  file_urls             = ["http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz"]
  file_checksum_url     = "http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz.md5"
  file_checksum_type    = "md5"
  file_target_extension = "tar.gz"
  file_unarchive_cmd    = ["bsdtar", "-xpf", "$ARCHIVE_PATH", "-C", "$MOUNTPOINT"]
  image_build_method    = "new"
  image_partitions {
    filesystem   = "vfat"
    mountpoint   = "/boot"
    name         = "boot"
    size         = "256M"
    start_sector = "2048"
    type         = "c"
  }
  image_partitions {
    filesystem   = "ext4"
    mountpoint   = "/"
    name         = "root"
    size         = "0"
    start_sector = "526336"
    type         = "83"
  }
  image_path                   = "raspberry-pi-4.img"
  image_size                   = "4G"
  image_type                   = "dos"
  qemu_binary_destination_path = "/usr/bin/qemu-aarch64-static"
  qemu_binary_source_path      = "/usr/bin/qemu-aarch64-static"
}

build {
  sources = ["source.cross.arch"]

  provisioner "shell" {
    inline = [
      "mv /etc/resolv.conf /etc/resolv.conf.bk",
      "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
      "pacman-key --init",
      "pacman-key --populate archlinuxarm",
      "pacman -Sy --noconfirm --needed",
      "pacman -S parted --noconfirm --needed",
      "sed -i 's/mmcblk0/mmcblk1/g' /etc/fstab"
    ]
  }

  provisioner "shell" {
    inline = [
      "pacman -Sy --noconfirm --needed ansible bat base base-devel curl docker docker-compose git github-cli glibc lsd neovim openssh openssl rsync sudo zsh",
      "curl -L -o /tmp/install-dotfiles.sh https://raw.githubusercontent.com/ConnerWill/dotfiles/refs/heads/main/.config/zsh/install-dotfiles.sh",
      "curl -L -o /etc/issue.net https://gist.githubusercontent.com/ConnerWill/46ec96bc5eb1bca8225e2aaadcde107d/raw/c34b34d1e7cf9c375289653a5a6339a60a3d9fd1/issue.net",
      "curl -L -o /etc/issue https://gist.githubusercontent.com/ConnerWill/15d28359e4338159affdd9de249f7786/raw/591681b4badf4d965b20973f6c18d29f5f4e87bb/issue-rainbow",
      "curl -L -o /etc/ssh/hardened-sshd_config https://gist.githubusercontent.com/ConnerWill/f5bffffbdd12a38fa9cc9b617dc3c25b/raw/f4c141d48a5d0fd79497ed19eb6ee328831b6c70/hardened-sshd_config",
      "mkdir -p /home/alarm/.ssh",
      "chown --recursive alarm:alarm /home/alarm/.ssh",
      "chmod 700 /home/alarm/.ssh",
      "echo '# ENTER_SSH_PUB_KEY_HERE' >> /home/alarm/.ssh/authorized_keys",
      "echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC9MwWXoxIDai1BtOgbP6sBLUhgp+/yv3juZveWxuGiv work-laptop-key' >> /home/alarm/.ssh/authorized_keys",
      "chown alarm:alarm /home/alarm/.ssh/authorized_keys",
      "chmod 600 /home/alarm/.ssh/authorized_keys",
      "systemctl enable sshd",
      "if command -v zsh chsh >/dev/null 2>&1; then chsh --shell=$(command -v zsh) alarm; fi",
      "mv -f /etc/resolv.conf.bk /etc/resolv.conf"
    ]
  }

  provisioner "file" {
    destination = "/tmp"
    source      = "scripts/resizerootfs"
  }

  provisioner "shell" {
    script = "scripts/bootstrap_resizerootfs.sh"
  }
}
