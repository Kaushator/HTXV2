# Скрипты для управления проектом HTXV2

В этой директории находятся скрипты для управления проектом HTXV2, включая:

- `test-containers.ps1` - скрипт для тестирования контейнеров
- `update-containers.ps1` - скрипт для обновления контейнеров
- `backup-data.ps1` - скрипт для создания резервных копий данных

Эти скрипты предназначены для использования как в локальной среде Windows, так и в dev-контейнере.

## Как использовать скрипты в dev-контейнере

В dev-контейнере установлен PowerShell Core (pwsh), поэтому скрипты могут выполняться без изменений:

```bash
# Тестирование контейнеров
pwsh /workspace/.devcontainer/scripts/powershell/test-containers.ps1

# Обновление контейнеров
pwsh /workspace/.devcontainer/scripts/powershell/update-containers.ps1

# Создание резервных копий данных
pwsh /workspace/.devcontainer/scripts/powershell/backup-data.ps1
```

## Примечание

Скрипты автоматически настроены для работы как в Windows, так и в Linux среде.
