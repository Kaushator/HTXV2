module "apis"      { source = "../../modules/apis" }
module "iam"       { source = "../../modules/iam",       project_id = var.project_id }
module "gcs"       { source = "../../modules/gcs",       project_id = var.project_id }
module "artifact"  { source = "../../modules/artifact",  project_id = var.project_id, region = var.region }
module "bq"        { source = "../../modules/bq",        project_id = var.project_id, bq_location = var.bq_location }
module "sql"       {
  source      = "../../modules/sql"
  project_id  = var.project_id
  region      = var.region
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
}
module "redis"     { source = "../../modules/redis",     project_id = var.project_id, region = var.region }
module "pubsub"    { source = "../../modules/pubsub",    project_id = var.project_id }
module "scheduler" { source = "../../modules/scheduler", project_id = var.project_id, region = var.region, topics = module.pubsub.topics }
module "secrets"   { source = "../../modules/secrets",   project_id = var.project_id }
module "runjobs"   { source = "../../modules/runjobs",   project_id = var.project_id, region = var.region, repo_id = module.artifact.repo_id }
module "cicd"      {
  source     = "../../modules/cicd"
  project_id = var.project_id
  region     = var.region
  repo_id    = module.artifact.repo_id
}
