output "node_pool_id" {
  value = oci_containerengine_node_pool.k8s_node_pool.id
}

output "node_pool_list" {
  description = "The list of private IP addresses for the nodes in the node pool"
  value = [for node in oci_containerengine_node_pool.k8s_node_pool.nodes : node.private_ip]
}

output "cluster_id" {
  value = oci_containerengine_cluster.k8s_cluster.id
}
