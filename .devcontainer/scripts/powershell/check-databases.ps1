# Скрипт для проверки и создания необходимых баз данных PostgreSQL
# Используется для инициализации среды разработки HTXV2

# Параметры
param (
    [string]$PostgresContainer = "htxenterface_v2-postgres-1",
    [string]$PostgresUser = "htx",
    [string]$PostgresDefaultDb = "htxdb",
    [string[]]$RequiredDatabases = @("htx", "htxdb")
)

# Функции для цветного вывода
function Write-ColorOutput {
    param (
        [string]$Message,
        [string]$Status,
        [string]$Color
    )

    $statusText = "[$Status]"
    if ($Color -eq "Green") {
        Write-Host $statusText -ForegroundColor Green -NoNewline
    } elseif ($Color -eq "Red") {
        Write-Host $statusText -ForegroundColor Red -NoNewline
    } elseif ($Color -eq "Cyan") {
        Write-Host $statusText -ForegroundColor Cyan -NoNewline
    } elseif ($Color -eq "Yellow") {
        Write-Host $statusText -ForegroundColor Yellow -NoNewline
    }

    Write-Host " $Message"
}

# Определение команды Docker в зависимости от ОС
$dockerCommand = if ($IsWindows) { "docker.exe" } else { "docker" }

# Функция для проверки состояния контейнера
function Test-ContainerStatus {
    param (
        [string]$ContainerName
    )

    try {
        $containerStatus = & $dockerCommand inspect --format="{{.State.Status}}" $ContainerName 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $containerStatus
        } else {
            return $null
        }
    } catch {
        return $null
    }
}

# Функция для выполнения команды в контейнере PostgreSQL
function Invoke-PostgresCommand {
    param (
        [string]$ContainerName,
        [string]$User,
        [string]$Database,
        [string]$Command
    )

    try {
        $result = & $dockerCommand exec $ContainerName psql -U $User -d $Database -c $Command 2>&1
        return $result
    } catch {
        Write-ColorOutput -Message "Ошибка выполнения команды в PostgreSQL: $_" -Status "ОШИБКА" -Color "Red"
        return $null
    }
}

# Проверка наличия контейнера PostgreSQL
Write-Host "Проверка наличия контейнера PostgreSQL ($PostgresContainer)..."
$containerStatus = Test-ContainerStatus -ContainerName $PostgresContainer

if ($null -eq $containerStatus) {
    Write-ColorOutput -Message "Контейнер PostgreSQL не запущен!" -Status "ОШИБКА" -Color "Red"
    Write-Host "Запустите контейнеры с помощью 'docker compose up -d' перед выполнением этого скрипта."
    exit 1
} elseif ($containerStatus -ne "running") {
    Write-ColorOutput -Message "Контейнер PostgreSQL имеет статус: $containerStatus" -Status "ОШИБКА" -Color "Red"
    Write-Host "Запустите контейнеры с помощью 'docker compose up -d' перед выполнением этого скрипта."
    exit 1
} else {
    Write-ColorOutput -Message "Контейнер PostgreSQL запущен и работает" -Status "УСПЕХ" -Color "Green"
}

# Даем PostgreSQL время на запуск и инициализацию
Write-Host "Даем PostgreSQL время на инициализацию..."
Start-Sleep -Seconds 3

# Проверка и создание всех необходимых баз данных
Write-Host "`nПроверка наличия необходимых баз данных..."
foreach ($db in $RequiredDatabases) {
    Write-Host "Проверка базы данных '$db'..." -NoNewline

    # Проверяем существование базы данных
    $checkDbCmd = "SELECT 1 FROM pg_database WHERE datname = '$db'"
    $dbExists = Invoke-PostgresCommand -ContainerName $PostgresContainer -User $PostgresUser -Database $PostgresDefaultDb -Command $checkDbCmd

    if ($dbExists -match "1 row") {
        Write-Host " существует!" -ForegroundColor Green
    } else {
        Write-Host " не существует." -ForegroundColor Yellow
        Write-Host "  Создание базы данных '$db'..." -NoNewline

        # База данных не существует, создаем ее
        $createDbCmd = "CREATE DATABASE $db;"
        $result = Invoke-PostgresCommand -ContainerName $PostgresContainer -User $PostgresUser -Database $PostgresDefaultDb -Command $createDbCmd

        if ($LASTEXITCODE -eq 0) {
            Write-Host " создана!" -ForegroundColor Green
        } else {
            Write-Host " ошибка создания!" -ForegroundColor Red
            Write-Host "  $result" -ForegroundColor Red
        }
    }
}

# Вывод информации о базах данных
Write-Host "`nСписок всех баз данных в PostgreSQL:"
$listDbCmd = "\l"
$dbList = Invoke-PostgresCommand -ContainerName $PostgresContainer -User $PostgresUser -Database $PostgresDefaultDb -Command $listDbCmd
$dbList | ForEach-Object { Write-Host $_ }

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-ColorOutput -Message "Проверка баз данных завершена" -Status "УСПЕХ" -Color "Green"
Write-Host "===============================================" -ForegroundColor Cyan
