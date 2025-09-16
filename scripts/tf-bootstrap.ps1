Param(
  [Parameter(Mandatory = $true)] [string] $ProjectId,
  [Parameter(Mandatory = $false)] [string] $Region = "us-central1",
  [Parameter(Mandatory = $false)] [string] $BucketName = "htxv2-terraform-state",
  [Parameter(Mandatory = $false)] [string] $Prefix = "terraform/state",
  [Parameter(Mandatory = $false)] [string] $CredentialsPath
)

function Write-Info($msg) {
  Write-Host "[INFO] $msg" -ForegroundColor Cyan
}
function Write-Ok($msg) {
  Write-Host "[ OK ] $msg" -ForegroundColor Green
}
function Write-Warn($msg) {
  Write-Host "[WARN] $msg" -ForegroundColor Yellow
}
function Write-Err($msg) {
  Write-Host "[ERR ] $msg" -ForegroundColor Red
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Info "Project: $ProjectId | Region: $Region"
Write-Info "State bucket: gs://$BucketName | Prefix: $Prefix"

# Ensure required CLIs exist
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
  Write-Err "Terraform CLI not found in PATH. Please install Terraform >= 1.5"
  exit 1
}
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
  Write-Err "gcloud CLI not found in PATH. Please install Google Cloud SDK"
  exit 1
}

# Configure gcloud project
Write-Info "Setting gcloud project to $ProjectId"
& gcloud config set project $ProjectId | Out-Null

# Handle credentials if provided
if ($CredentialsPath) {
  if (-not (Test-Path $CredentialsPath)) {
    Write-Err "Credentials file not found: $CredentialsPath"
    exit 1
  }
  $fullCredPath = (Resolve-Path $CredentialsPath).Path
  Write-Info "Using service account JSON: $fullCredPath"
  $env:GOOGLE_APPLICATION_CREDENTIALS = $fullCredPath
} else {
  Write-Info "No credentials file provided. Checking ADC (Application Default Credentials)."
  try {
    & gcloud auth application-default print-access-token | Out-Null
    Write-Ok "ADC available."
  } catch {
    Write-Warn "ADC not configured. Launching 'gcloud auth application-default login'..."
    & gcloud auth application-default login
  }
}

# Create state bucket if it does not exist
Write-Info "Ensuring state bucket exists: gs://$BucketName"
$bucketExists = $false
try {
  & gcloud storage buckets describe "gs://$BucketName" | Out-Null
  $bucketExists = $true
} catch {
  $bucketExists = $false
}
if (-not $bucketExists) {
  Write-Info "Creating bucket gs://$BucketName in $Region"
  & gcloud storage buckets create "gs://$BucketName" --project $ProjectId --location $Region | Out-Null
  Write-Ok "Bucket created."
} else {
  Write-Ok "Bucket already exists."
}

# Generate backend.hcl
$backendPath = Join-Path (Resolve-Path "infrastructure").Path "backend.hcl"
Write-Info "Writing backend config: $backendPath"
$backendLines = @()
$backendLines += ('bucket = "{0}"' -f $BucketName)
$backendLines += ('prefix = "{0}"' -f $Prefix)
if ($CredentialsPath) {
  $backendLines += ('credentials = "{0}"' -f $fullCredPath)
}
Set-Content -Path $backendPath -Value $backendLines -Encoding UTF8
Write-Ok "backend.hcl generated."

# Prepare terraform.tfvars if missing
$tfvars = Join-Path (Resolve-Path "infrastructure").Path "terraform.tfvars"
$tfvarsExample = Join-Path (Resolve-Path "infrastructure").Path "terraform.tfvars.example"
if (-not (Test-Path $tfvars) -and (Test-Path $tfvarsExample)) {
  Write-Info "Creating terraform.tfvars from example"
  Copy-Item $tfvarsExample $tfvars
  # Replace common placeholders
  (Get-Content $tfvars) |
    ForEach-Object { $_ -replace 'your-gcp-project-id', $ProjectId } |
    Set-Content $tfvars
  Write-Ok "terraform.tfvars created. Please review values (region/zone/etc.)."
}

# Terraform init with backend config
Write-Info "Initializing Terraform backend"
& terraform -chdir=infrastructure init -backend-config="$backendPath"
Write-Ok "Terraform initialized. Next: 'make tf-plan' or 'make tf-apply'"
