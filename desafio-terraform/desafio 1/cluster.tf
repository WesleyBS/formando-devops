resource "kind_cluster" "default" {
    name           = var.cluster_name
    node_image     = var.kubernetes_version
    wait_for_ready = true
    

    kind_config  {
        kind        = "Cluster"
        api_version = "kind.x-k8s.io/v1alpha4"
        
        node {
            role    = "control-plane"
        }
        node {
            role       =  "infra"
            /*taints = [
            {
                effect = "NoSchedule"
                key    = "dedicated"
                value  = "infra"
            }
            ]*/
        }
        node {
            role       =  "app"
        }
    }
}