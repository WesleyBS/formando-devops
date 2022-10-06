resource "shell_script" "manage_packages" {
  lifecycle_commands {
    create = file("${path.module}/scripts/create.sh")
    read   = file("${path.module}/scripts/read.sh")
    update = file("${path.module}/scripts/update.sh")
    delete = file("${path.module}/scripts/delete.sh")
  }

  environment = {
    install_pkgs: var.install
    uninstall_pkgs: var.uninstall
    new_versao = var.versao
    old_pkgs = var.old
    list_pkgs = var.list
  }

  interpreter = ["/bin/bash", "-c"]



  triggers = {
    when_value_changed = var.install
    when_value_changed = var.uninstall
    new_versao = var.versao
    old_pkgs = var.old
    list_pkgs = var.list

    }

}