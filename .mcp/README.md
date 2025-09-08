# GitHub Copilot Chat — MCP сервер (HTX)

Этот пакет добавляет проектные настройки VS Code, чтобы Copilot Chat увидел MCP-сервер `htx-mcp`.

## Как подключить
1) Помести папку MCP-сервера (из `mcp-htx-server.zip`) рядом с проектом или в любое место на диске.
2) Скопируй `.vscode/settings.json` из этого архива в свою папку проекта **HTX_interfacev2**.
3) Открой проект в VS Code. Убедись, что установлен **GitHub Copilot** и **GitHub Copilot Chat**.
4) Перезапусти окно VS Code (Command Palette → `Developer: Reload Window`).

## Проверка
Открой Copilot Chat и набери:
```
/tools
```
Должен появиться список тулов MCP: `health`, `list_assets`, `analysis`, `upload_csv`, и т.д.
Если инструменты не видны — обнови расширения Copilot до последней версии и проверь пути в settings.json.

## Примечания
- Переменные окружения для MCP берутся из блока `env` в настройке.
- Путь `cwd` использует `${workspaceFolder}` → MCP-сервер ожидается в подпапке `mcp-htx-server`.
  Если реальный путь другой — поправь `cwd` и `args`.
