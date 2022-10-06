resource "local_file" "desafio3" {

    content  = templatefile("${path.module}/alo_mundo.txt.tpl", { 
        nome = var.nome,
        data = formatdate("DD/MM/YYYY", timestamp()),
        div = var.div
        result = jsonencode([for res in range(0, 100) : res if res%var.div == 0]) 
        }
        )
    filename = "${path.module}/alo_mundo.txt"
  
}



