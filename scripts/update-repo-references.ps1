# Скрипт для обновления ссылок на GitHub репозиторий
# Автор: GitHub Copilot
# Дата: 16.09.2025

param(
    [switch]$DryRun,  # Режим проверки без внесения изменений
    [switch]$Force     # Принудительное выполнение без запросов подтверждения
)

# Определяем цвета для вывода
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$RED = "`e[31m"
$BLUE = "`e[34m"
$RESET = "`e[0m"

# Выводим баннер
Write-Host "$BLUE"
Write-Host "  _____                     _____                  _____                   "
Write-Host " |  __ \                   |  __ \                |  __ \                  "
Write-Host " | |__) |___ _ __   ___    | |  | | ___ _ __   ___| |__) |___ _ __   ___  "
Write-Host " |  _  // _ \ '_ \ / _ \   | |  | |/ _ \ '_ \ / _ \  _  // _ \ '_ \ / _ \ "
Write-Host " | | \ \  __/ |_) | (_) |  | |__| |  __/ |_) | (_) | | \ \  __/ |_) | (_) |"
Write-Host " |_|  \_\___| .__/ \___/   |_____/ \___| .__/ \___/|_|  \_\___| .__/ \___/ "
Write-Host "            | |                        | |                    | |          "
Write-Host "            |_|                        |_|                    |_|          "
Write-Host "$RESET"
Write-Host "${YELLOW}Обновление ссылок на репозиторий GitHub в проекте${RESET}"
Write-Host ""

# Старый и новый репозитории
$OLD_REPO = "HTXV2"
$NEW_REPO = "HTXV2"

# Текущая директория проекта
$PROJECT_DIR = Get-Location

# Функция для поиска и замены в файле
function Update-FileContent {
    param(
        [string]$FilePath,
        [string]$OldString,
        [string]$NewString,
        [bool]$IsDryRun = $false
    )

    # Проверяем существование файла
    if (-not (Test-Path $FilePath)) {
        Write-Host "${RED}✗ Файл не найден: $FilePath${RESET}"
        return $false
    }

    # Читаем содержимое файла
    $content = Get-Content -Path $FilePath -Raw

    # Проверяем, содержит ли файл старую строку
    if ($content -match [regex]::Escape($OldString)) {
        # Заменяем строки
        $newContent = $content -replace [regex]::Escape($OldString), $NewString

        # В режиме проверки просто выводим информацию
        if ($IsDryRun) {
            Write-Host "${YELLOW}Найден файл с совпадением: $FilePath${RESET}"
            return $true
        }

        # Записываем изменения
        $newContent | Set-Content -Path $FilePath -NoNewline
        Write-Host "${GREEN}✓ Обновлен файл: $FilePath${RESET}"
        return $true
    }

    return $false
}

# Функция для поиска файлов рекурсивно
function Find-AndReplaceInFiles {
    param(
        [string]$Directory,
        [string]$OldString,
        [string]$NewString,
        [bool]$IsDryRun = $false,
        [array]$SkipDirs = @(".git", "node_modules", "venv", "__pycache__", ".vscode")
    )

    $totalChanged = 0
    $filesChanged = @()

    # Получаем все файлы в директории
    $allFiles = Get-ChildItem -Path $Directory -Recurse -File | Where-Object {
        $skip = $false
        foreach ($dir in $SkipDirs) {
            if ($_.FullName -like "*\$dir\*") {
                $skip = $true
                break
            }
        }
        return -not $skip
    }

    Write-Host "${BLUE}Поиск упоминаний '$OldString' в файлах...${RESET}"

    # Фильтруем только текстовые файлы
    $textExtensions = @(".md", ".txt", ".json", ".yml", ".yaml", ".xml", ".html", ".js", ".ts", ".jsx", ".tsx", ".py", ".sh", ".ps1", ".css", ".scss")
    $textFiles = $allFiles | Where-Object {
        $extension = [System.IO.Path]::GetExtension($_.FullName).ToLower()
        return ($extension -in $textExtensions) -or ($_.Length -lt 1MB) # Предполагаем, что файлы менее 1MB могут быть текстовыми
    }

    $totalFiles = $textFiles.Count
    $processedFiles = 0
    $spinner = @('|', '/', '-', '\')
    $spinnerIndex = 0

    foreach ($file in $textFiles) {
        # Обновление спиннера и прогресса
        $processedFiles++
        $spinnerChar = $spinner[$spinnerIndex % $spinner.Length]
        $progress = [math]::Round(($processedFiles / $totalFiles) * 100)
        Write-Host -NoNewline "`r$spinnerChar Обработка ($processedFiles из $totalFiles): $progress% $($file.Name)                     "
        $spinnerIndex++

        # Проверяем содержимое файла
        try {
            $result = Update-FileContent -FilePath $file.FullName -OldString $OldString -NewString $NewString -IsDryRun $IsDryRun
            if ($result) {
                $totalChanged++
                $filesChanged += $file.FullName
            }
        } catch {
            # Пропускаем файлы, которые нельзя прочитать как текст
            continue
        }
    }

    Write-Host "`r                                                                      "
    return @{
        Count = $totalChanged
        Files = $filesChanged
    }
}

# Функция для обновления .git/config
function Update-GitConfig {
    param(
        [string]$ConfigPath,
        [string]$OldString,
        [string]$NewString,
        [bool]$IsDryRun = $false
    )

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "${RED}✗ Файл .git/config не найден${RESET}"
        return $false
    }

    $configContent = Get-Content -Path $ConfigPath -Raw

    # Проверяем, содержит ли конфиг старый URL
    if ($configContent -match [regex]::Escape($OldString)) {
        if ($IsDryRun) {
            Write-Host "${YELLOW}Найдены ссылки на старый репозиторий в Git конфигурации${RESET}"
            return $true
        }

        $newConfigContent = $configContent -replace [regex]::Escape($OldString), $NewString
        $newConfigContent | Set-Content -Path $ConfigPath -NoNewline

        Write-Host "${GREEN}✓ Обновлена конфигурация Git (.git/config)${RESET}"
        return $true
    }

    Write-Host "${GREEN}✓ Конфигурация Git уже использует правильный репозиторий${RESET}"
    return $false
}

# Основной блок выполнения
Write-Host "${BLUE}=== Обновление репозитория из $OLD_REPO на $NEW_REPO ===${RESET}"

if (-not $DryRun -and -not $Force) {
    Write-Host "${YELLOW}Внимание: Будет выполнено обновление ссылок на репозиторий в файлах проекта.${RESET}"
    $confirmation = Read-Host "Продолжить? [y/N]"

    if ($confirmation -ne "y") {
        Write-Host "${RED}Операция отменена.${RESET}"
        exit 0
    }
}

# Проверяем наличие Git репозитория
if (-not (Test-Path ".git")) {
    Write-Host "${RED}✗ Текущая директория не является Git репозиторием${RESET}"
    exit 1
}

# Проверяем текущую конфигурацию Git
$gitConfigResult = Update-GitConfig -ConfigPath ".git/config" `
    -OldString "github.com:Kaushator/$OLD_REPO.git" `
    -NewString "github.com:Kaushator/$NEW_REPO.git" `
    -IsDryRun $DryRun

# Поиск и замена во всех файлах
$oldRepoFullUrl = "github.com/Kaushator/$OLD_REPO"
$newRepoFullUrl = "github.com/Kaushator/$NEW_REPO"

$result = Find-AndReplaceInFiles -Directory $PROJECT_DIR `
    -OldString $oldRepoFullUrl `
    -NewString $newRepoFullUrl `
    -IsDryRun $DryRun

# Поиск и замена имени проекта в документации
$result2 = Find-AndReplaceInFiles -Directory $PROJECT_DIR `
    -OldString $OLD_REPO `
    -NewString $NEW_REPO `
    -IsDryRun $DryRun

# Вывод итогов
Write-Host ""
Write-Host "${BLUE}=== Итоги операции ===${RESET}"

if ($DryRun) {
    Write-Host "${YELLOW}[РЕЖИМ ПРОВЕРКИ] Изменения не были применены${RESET}"
}

$totalChangedFiles = $result.Count + $result2.Count

if ($totalChangedFiles -gt 0 -or $gitConfigResult) {
    Write-Host "${GREEN}✓ Найдено упоминаний репозитория для обновления: $totalChangedFiles файлов${RESET}"

    if ($result.Files.Count -gt 0) {
        Write-Host "${BLUE}Файлы с полным URL ($($result.Files.Count)):${RESET}"
        foreach ($file in $result.Files | Select-Object -First 10) {
            Write-Host " - $file"
        }

        if ($result.Files.Count -gt 10) {
            Write-Host " ... и еще $($result.Files.Count - 10) файлов"
        }
    }

    if ($result2.Files.Count -gt 0) {
        Write-Host "${BLUE}Файлы с именем репозитория ($($result2.Files.Count)):${RESET}"
        foreach ($file in $result2.Files | Select-Object -First 10) {
            Write-Host " - $file"
        }

        if ($result2.Files.Count -gt 10) {
            Write-Host " ... и еще $($result2.Files.Count - 10) файлов"
        }
    }

    if (-not $DryRun) {
        Write-Host "${GREEN}✓ Все упоминания репозитория успешно обновлены${RESET}"
    }
} else {
    Write-Host "${YELLOW}Не найдено упоминаний старого репозитория в файлах проекта${RESET}"
}

# Рекомендации по дальнейшим действиям
if (-not $DryRun) {
    Write-Host ""
    Write-Host "${BLUE}=== Дальнейшие рекомендации ===${RESET}"
    Write-Host "1. Проверьте правильность работы проекта после обновления"
    Write-Host "2. Сделайте коммит с изменениями: git commit -am 'Обновлены ссылки на репозиторий: $OLD_REPO → $NEW_REPO'"
    Write-Host "3. Обновите удаленный репозиторий: git push origin main"
}
