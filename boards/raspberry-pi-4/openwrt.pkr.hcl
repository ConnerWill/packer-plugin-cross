packer {
  required_plugins {
    git = {
      version = ">=v0.3.2"
      source  = "github.com/ethanmdavidson/git"
    }
  }
}

source "cross" "openwrt" {
  file_checksum         = "c3f2033c6f116c4646bf6b5d47c45a4080c11ac1a9c520d8aa99ef235da3a935"
  file_checksum_type    = "sha256"
  file_target_extension = "gz"
  file_unarchive_cmd    = ["gzip", "-d", "$ARCHIVE_PATH"]
  file_urls             = ["https://downloads.openwrt.org/releases/24.10.0/targets/bcm27xx/bcm2711/openwrt-24.10.0-bcm27xx-bcm2711-rpi-4-ext4-factory.img.gz"]
  image_build_method    = "reuse"
  image_path            = "openwrt-24.10.0.img"
  image_size            = "2G"
  image_type            = "dos"
  image_partitions {
    filesystem   = "fat"
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
  image_chroot_env             = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
  qemu_binary_destination_path = "/usr/bin/qemu-aarch64-static"
  qemu_binary_source_path      = "/usr/bin/qemu-aarch64-static"
}

build {
  sources = ["source.cross.openwrt"]

  provisioner "shell" {
    inline = [
      "mv /etc/resolv.conf /etc/resolv.conf.bk",
      "echo 'nameserver 8.8.8.8' > /etc/resolv.conf",
      "/etc/init.d/dnsmasq restart",
      "mkdir -p /var/lock/",
      "opkg update",
      "opkg install --force-install bash",
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
