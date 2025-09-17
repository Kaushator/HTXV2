Param(
  [string]$DbName = "htxv2",
  [string]$User = "htxv2_user",
  [string]$ComposeFile = "docker/docker-compose.yml"
)

# Creates a timestamped Postgres dump into W:\docker\backups via the bind mount /backups
$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dumpName = "${DbName}_$timestamp.dump"

Write-Host "Creating dump: $dumpName"

# Use docker compose exec (no TTY) to run pg_dump inside the postgres container
$execCmd = @(
  "docker", "compose", "-f", $ComposeFile,
  "exec", "-T", "postgres",
  "pg_dump", "-U", $User, "-d", $DbName, "-F", "c",
  "-f", "/backups/$dumpName"
)

$process = Start-Process -FilePath $execCmd[0] -ArgumentList $execCmd[1..($execCmd.Length-1)] -NoNewWindow -PassThru -Wait
if ($process.ExitCode -ne 0) {
  Write-Error "pg_dump failed with exit code $($process.ExitCode)"
  exit $process.ExitCode
}

Write-Host "Dump created at W:\docker\backups\$dumpName"
