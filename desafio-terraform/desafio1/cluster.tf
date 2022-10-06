resource "kind_cluster" "DesafioTerraform" {
    name           = var.cluster_name
    node_image     = var.kubernetes_version
    wait_for_ready = true
    

    kind_config  {
        kind        = "Cluster"
        api_version = "kind.x-k8s.io/v1alpha4"
        
        node {
          role = "control-plane"
        }

        node {
            role    = "worker"
            kubeadm_config_patches = [
                "kind: JoinConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"role=app\"\n"
            ]
        }
        node {
            role       =  "worker"
            kubeadm_config_patches = [
                "kind: JoinConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"role=infra\"\n"
            ]
        }
    }
    provisioner "local-exec" {
        command = "kubectl taint node ${var.cluster_name}-worker -l role=infra dedicated=infra:NoSchedule"
    }
}