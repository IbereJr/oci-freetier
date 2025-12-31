resource "null_resource" "create_kubeconfig" {
  provisioner "local-exec" {
    command = "oci ce cluster create-kubeconfig --cluster-id ${var.cluster_id} --file ~/.kube/config --token-version 2.0.0 --profile ${var.oci_profile}"
  }
}

resource "null_resource" "remove_taints" {
  provisioner "local-exec" {
    command = "kubectl taint node --all=true  node.cloudprovider.kubernetes.io/uninitialized- "
  }
}
