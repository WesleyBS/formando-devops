output "api_endpoint" {
    value = kind_cluster.DesafioTerraform.endpoint
}

output "kubeconfig" {
  value = kind_cluster.DesafioTerraform.kubeconfig
}

output "client_certificate" {
    value = kind_cluster.DesafioTerraform.client_certificate
}

output "client_key" {
    value = kind_cluster.DesafioTerraform.client_key
}

output "cluster_ca_certificate" {
    value = kind_cluster.DesafioTerraform.cluster_ca_certificate
}