<#
.SYNOPSIS
    Устанавливает права на выполнение для bash-скриптов в Windows.

.DESCRIPTION
    Скрипт устанавливает права на выполнение для всех bash-скриптов (.sh) в указанной директории.
    Это полезно при работе на Windows с репозиторием, который содержит bash-скрипты для Linux/MacOS.
    Скрипт устанавливает атрибут ExecutionPolicy для указанных файлов, что эквивалентно chmod +x в Unix.

.PARAMETER Directory
    Путь к директории с bash-скриптами. По умолчанию - текущая директория.

.PARAMETER Recursive
    Если указан, скрипт будет искать файлы рекурсивно в поддиректориях.

.EXAMPLE
    .\set-executable.ps1 -Directory ".devcontainer\scripts\github" -Recursive
#>

param(
    [string]$Directory = ".",
    [switch]$Recursive
)

# Настройка поведения при ошибке
$ErrorActionPreference = 'Stop'

# Цветные сообщения для вывода
function Write-ColorOutput {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [string]$Color
    )

    $currentForeground = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $currentForeground
}

function Write-Info {
    param ([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Cyan"
}

function Write-Success {
    param ([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Warning {
    param ([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-ErrorMsg {
    param ([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
    throw $Message
}

# Проверка существования директории
if (-not (Test-Path $Directory -PathType Container)) {
    Write-ErrorMsg "Директория '$Directory' не существует."
}

# Определение параметров поиска
$searchParams = @{
    Path = $Directory
    Filter = "*.sh"
}

if ($Recursive) {
    $searchParams.Recurse = $true
}

# Поиск bash-скриптов
Write-Info "Поиск bash-скриптов в директории '$Directory'$(if ($Recursive) { ' (рекурсивно)' } else { '' })..."
$scripts = Get-ChildItem @searchParams

if ($scripts.Count -eq 0) {
    Write-Warning "Bash-скриптов (.sh) не найдено в указанной директории."
    exit 0
}

Write-Info "Найдено скриптов: $($scripts.Count)"

# Установка прав на выполнение
$count = 0
foreach ($script in $scripts) {
    try {
        Write-Info "Установка прав на выполнение для $($script.FullName)"

        # В PowerShell нет прямого эквивалента chmod +x,
        # но мы можем изменить разрешения файла через .NET
        $acl = Get-Acl $script.FullName
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        # Создание разрешения на исполнение
        $execRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $currentUser,
            "ReadAndExecute",
            "Allow"
        )

        # Добавление разрешения
        $acl.AddAccessRule($execRule)
        Set-Acl $script.FullName $acl

        # Также добавим специальную метку, которая поможет Git сохранить исполняемый бит
        git update-index --chmod=+x $script.FullName

        $count++
    }
    catch {
        Write-Warning "Не удалось установить права для $($script.FullName): $_"
    }
}

Write-Success "Права на выполнение установлены для $count из $($scripts.Count) скриптов."
Write-Info "Для использования этих скриптов в Linux/MacOS, рекомендуется также выполнить 'chmod +x' в соответствующей среде."
