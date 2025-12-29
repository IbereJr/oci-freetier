# oci-freetier
Automação para provisionar Cluster OKE em duas instâncias ARM (2 cpu x 12 gb) e mais duas VMs micro, e uma VPN IPSec para conectar com FreeSwan

## Diretórios:

* inicial
Scripts básicos, para gerar o compartment que será utilizado (assim não será necessário recriar sempre), e demais atividades que devem ser executadas apenas uma vez.

* inventario-oci
Scripts para tirar backup completo de uma estrutura (e poder compará-los)

* meow-oci
Terraform para gerar todas as configurações.

* util
Utilitários diversos (ex: SuperDelete)
