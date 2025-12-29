resource "oci_identity_compartment" "compartment" {
  name          = var.name
  description   = "Compartment for the Oracle Cloud Always Free."
  compartment_id = var.tenancy_id
  enable_delete = true
}

resource "oci_ons_notification_topic" "alert_queue" {
  compartment_id = oci_identity_compartment.compartment.id
  name   = "Fila de Alertas"
}

resource "oci_ons_subscription" "email" {
  compartment_id = oci_identity_compartment.compartment.id
  endpoint       = var.emails
  protocol       = "EMAIL"
  topic_id       = oci_ons_notification_topic.alert_queue.id
}

resource "oci_budget_budget" "budget" {
  compartment_id = oci_identity_compartment.compartment.id
  display_name   = "Limite de Gastos"
  description    = "Limite Mensal Máximo Previsto"
  target_type    = "COMPARTMENT"
  amount         = var.budget
  reset_period   = "MONTHLY"
}

resource "oci_budget_alert_rule" "warn_alert" {
  budget_id        = oci_budget_budget.budget.id 
  display_name     = "Gasto-75%-do-Limite"
  description      = "75% do limite de Budget já foi consumido"
  message          = "Warning: Seu Compartment ${var.name} já gastou 75% do budget (${var.budget} reais)."
  recipients       = var.emails
  threshold        = 0.75 
  threshold_type   = "FORECASTED"
  type             = "FORECAST"
}

resource "oci_budget_alert_rule" "crit_alert" {
  budget_id        = oci_budget_budget.budget.id 
  display_name     = "Gasto-90%-do-Limite"
  description      = "90% do limite de Budget já foi consumido"
  message          = "Critical: Seu Compartment ${var.name} já gastou 90% do budget (${var.budget} reais)."
  recipients       = var.emails
  threshold        = 0.90 
  threshold_type   = "FORECASTED"
  type             = "FORECAST"
}
