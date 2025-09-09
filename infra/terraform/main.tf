module "cicd" {
  source = "./modules/cicd"
  
  project_id = var.project_id
  region     = var.region
  repo_id    = "htx-interface"
}

output "github_actions_sa_key" {
  value     = module.cicd.github_sa_key
  sensitive = true
  description = "GitHub Actions Service Account Key (base64 encoded)"
}

output "service_account_email" {
  value = module.cicd.service_account_email
  description = "Email сервисного аккаунта для GitHub Actions"
}

output "backend_url" {
  value = module.cicd.backend_url
  description = "URL сервиса backend"
}

output "frontend_url" {
  value = module.cicd.frontend_url
  description = "URL сервиса frontend"
}

output "fingpt_url" {
  value = module.cicd.fingpt_url
  description = "URL сервиса fingpt"
}
