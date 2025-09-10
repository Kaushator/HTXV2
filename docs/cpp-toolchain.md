# C/C++ Toolchain Setup

Цель: обеспечить сборку нативных зависимостей (например, psycopg/uvloop и др.) и нестандартных пакетов, требующих C/C++ компилятор и build tools.

## Windows

Вариант A — MSVC Build Tools (рекомендуется для Node/Next/SWC и Python wheels):
- Установить Visual Studio Build Tools 2022:
  - winget: `winget install --id Microsoft.VisualStudio.2022.BuildTools -e`
  - Либо скачать с сайта Microsoft (в установщике выбрать C++ build tools)
- Перезапустить терминал (PATH), проверить:
  - `cl.exe /?`
  - `nmake /?`

Вариант B — MSYS2 (UCRT64) с MinGW-w64:
- Установка MSYS2:
  - winget: `winget install -e --id MSYS2.MSYS2`
- Открыть MSYS2 UCRT64 shell и установить toolchain:
  - `pacman -Syu --noconfirm`
  - `pacman -S --noconfirm mingw-w64-ucrt-x86_64-toolchain`
- Проверка:
  - `gcc --version`
  - `g++ --version`

Примечания:
- Для Python-пакетов предпочтительнее готовые wheels. При сборке из исходников убедитесь, что активирована нужная среда (MSVC vs MinGW).
- Node-экосистема на Windows чаще ориентирована на MSVC (prebuilt бинарники `*-msvc`).

## Linux

Debian/Ubuntu:
- `sudo apt-get update`
- `sudo apt-get install -y build-essential`

RHEL/Fedora/CentOS:
- `sudo dnf groupinstall -y 'Development Tools'`

Alpine:
- `apk add --no-cache build-base`

Проверка:
- `gcc --version`
- `make --version`

## macOS

Command Line Tools:
- `xcode-select --install`

Или LLVM/Clang через Homebrew:
- `brew install llvm`
- Добавить в PATH при необходимости: `export PATH="/opt/homebrew/opt/llvm/bin:$PATH"`

Проверка:
- `clang --version`
- `make --version`

## Верификация в проекте

- Python (backend):
  - `pip install -r backend/requirements.txt` — зависимости собираются без ошибок
- Node (frontend):
  - `npm ci` в `frontend/` — пакеты ставятся, `next dev` работает
- Docker:
  - В контейнерах уже ставится `build-essential`/`gcc` (см. `backend/Dockerfile`, `HTXV2/docker/*.Dockerfile`)

