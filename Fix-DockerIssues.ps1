<#
.SYNOPSIS
    Скрипт для очистки и решения проблем Docker в Windows

.DESCRIPTION
    Этот скрипт останавливает Docker Desktop, очищает временные файлы
    и перезапускает Docker, чтобы решить распространенные проблемы
    с ошибками ввода/вывода и освободить место.

.EXAMPLE
    .\Fix-DockerIssues.ps1
#>

# Вывод сообщений с цветами
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
}

function Write-Section {
    param ([string]$Title)
    Write-ColorOutput "========== $Title ==========" "DarkCyan"
}

# Основная функция для очистки Docker
function Repair-DockerEnvironment {
    Write-Section "Проверка Docker Desktop"
    $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue

    if ($null -eq $dockerProcess) {
        Write-Warning "Docker Desktop не запущен. Скрипт попробует запустить его позже."
    } else {
        Write-Info "Остановка Docker Desktop..."
        try {
            $dockerProcess | Stop-Process -Force
            Start-Sleep -Seconds 5
            Write-Success "Docker Desktop успешно остановлен."
        }
        catch {
            Write-ErrorMsg ("Не удалось остановить Docker Desktop: {0}" -f $_)
            Write-Info "Пожалуйста, закройте Docker Desktop вручную и запустите скрипт снова."
            exit 1
        }
    }

    Write-Section "Очистка Docker данных"

    # Пути к папкам Docker, которые можно безопасно очистить
    $dockerDataPaths = @(
        "$env:USERPROFILE\AppData\Local\Docker\wsl",
        "$env:USERPROFILE\AppData\Local\Docker\tmp",
        "$env:USERPROFILE\AppData\Local\Docker\log"
    )

    foreach ($path in $dockerDataPaths) {
        if (Test-Path $path) {
            Write-Info "Очистка $path..."
            try {
                Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                    Where-Object { $_ -is [System.IO.DirectoryInfo] } |
                    ForEach-Object {
                        try {
                            Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                        } catch {
                            # Игнорируем ошибки для файлов, которые нельзя удалить
                        }
                    }
                Write-Success "Путь $path очищен."
            }
            catch {
                Write-Warning ("Не удалось полностью очистить {0}: {1}" -f $path, $_)
            }
        }
        else {
            Write-Info "Путь $path не существует, пропускаем."
        }
    }

    Write-Section "Проверка и очистка WSL"
    try {
        # Проверяем наличие wsl.exe
        if (Get-Command wsl -ErrorAction SilentlyContinue) {
            Write-Info "Проверка состояния WSL..."
            wsl --status

            Write-Info "Остановка всех WSL дистрибутивов..."
            wsl --shutdown

            Write-Success "WSL остановлен."
        }
        else {
            Write-Info "WSL не установлен, пропускаем этот шаг."
        }
    }
    catch {
        Write-Warning ("Ошибка при работе с WSL: {0}" -f $_)
    }

    Write-Section "Запуск Docker Desktop"
    try {
        $dockerPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerPath) {
            Write-Info "Запуск Docker Desktop..."
            Start-Process $dockerPath
            Write-Info "Ожидание запуска Docker..."
            Start-Sleep -Seconds 30 # Даем Docker время для запуска
            Write-Success "Docker Desktop запущен."
        }
        else {
            Write-ErrorMsg "Docker Desktop не найден по пути: $dockerPath"
            Write-Info "Пожалуйста, запустите Docker Desktop вручную."
        }
    }
    catch {
        Write-ErrorMsg ("Не удалось запустить Docker Desktop: {0}" -f $_)
    }

    Write-Section "Проверка Docker после перезапуска"
    try {
        docker info > $null
        Write-Success "Docker успешно перезапущен и работает!"

        Write-Info "Очистка неиспользуемых ресурсов Docker..."
        docker system prune -af --volumes
        Write-Success "Очистка выполнена успешно."
    }
    catch {
        Write-ErrorMsg ("Docker не запустился или не отвечает: {0}" -f $_)
        Write-Info "Пожалуйста, перезапустите Docker Desktop вручную."
    }

    Write-Section "Рекомендации"
    Write-Info "1. Если проблемы с Docker сохраняются, попробуйте перезагрузить компьютер."
    Write-Info "2. Проверьте, что у вас достаточно свободного места на диске."
    Write-Info "3. Убедитесь, что порты, необходимые для Docker, не заняты другими приложениями."
    Write-Info "4. Для дальнейшей диагностики запустите: docker system info"
}

# Выполнение основной функции
Repair-DockerEnvironment
