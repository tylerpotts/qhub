resource "keycloak_authentication_flow" "flow" {
  realm_id    = keycloak_realm.main.id
  alias       = "detect-existing"
  provider_id = "basic-flow"
}

resource "keycloak_authentication_execution" "idp-detect-existing-broker-user" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_flow.flow.alias
  authenticator     = "idp-detect-existing-broker-user"
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_execution" "idp-auto-link" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_flow.flow.alias
  authenticator     = "idp-auto-link"
  requirement       = "REQUIRED"

  # This is the only way to encourage Keycloak Provider to set the
  # auth execution priority order:
  # https://github.com/mrparkers/terraform-provider-keycloak/pull/138
  depends_on = [
    keycloak_authentication_execution.idp-detect-existing-broker-user
  ]
}


{% if cookiecutter.security.authentication.type == "GitHub" -%}
resource "keycloak_oidc_identity_provider" "github_identity_provider" {
  count = var.github_client_id == "" || var.github_client_secret == "" ? 0 : 1

  realm             = keycloak_realm.main.id
  alias             = "github"
  provider_id       = "github"
  authorization_url = ""
  client_id         = var.github_client_id
  client_secret     = var.github_client_secret
  token_url         = ""
  default_scopes    = "user:email"
  store_token       = false
  sync_mode         = "IMPORT"
  trust_email       = true

  first_broker_login_flow_alias = keycloak_authentication_flow.flow.alias

  extra_config = {
    "clientAuthMethod" = "client_secret_post"
  }
}
{% elif cookiecutter.security.authentication.type == "Auth0" -%}
resource "keycloak_oidc_identity_provider" "auth0_identity_provider" {
  realm             = keycloak_realm.main.id
  alias             = "auth0"
  provider_id       = "oidc"
  authorization_url = "https://{{ cookiecutter.security.authentication.config.auth0_subdomain }}.auth0.com/authorize"
  client_id         = "{{ cookiecutter.security.authentication.config.client_id }}"
  client_secret     = "{{ cookiecutter.security.authentication.config.client_secret }}"
  token_url         = "https://{{ cookiecutter.security.authentication.config.auth0_subdomain }}.auth0.com/oauth/token"
  user_info_url     = "https://{{ cookiecutter.security.authentication.config.auth0_subdomain }}.auth0.com/userinfo"
  default_scopes    = "openid email profile"
  store_token       = false
  sync_mode         = "IMPORT"
  trust_email       = true

  first_broker_login_flow_alias = keycloak_authentication_flow.flow.alias

  extra_config = {
    "clientAuthMethod" = "client_secret_post"
  }
}
{% endif %}
