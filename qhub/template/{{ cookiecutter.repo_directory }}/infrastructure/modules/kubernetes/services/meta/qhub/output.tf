output "jupyterhub_api_token" {
  description = "API token to enable in jupyterhub server"
  value       = random_password.jupyterhub_api_token.result
}

output "jupyterhub_api_token_prefect" {
  description = "API token to enable in jupyterhub server for prefect"
  value       = random_password.jupyterhub_api_token_prefect[0].result
}

output "tls" {
  description = "TLS configuration"
  value       = local.tls
}
