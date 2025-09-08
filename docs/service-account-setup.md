# Service Account Setup — github-actions-deployer

## Результат (выполнено)
- Создан сервисный аккаунт `github-actions-deployer` с ролями:
  - Artifact Registry Writer
  - Cloud Run Developer
  - Service Account User
  - Storage Admin
- Сгенерирован JSON‑ключ, сохранён локально как `github-actions-key.json` (не коммитить; добавлен в `.gitignore`).
- Ключ загружен в GitHub Secrets как `GCP_SA_KEY`.
- Копия ключа сохранена в Google Secret Manager (для безопасного хранения/ротации).

## Верификация
- Описание сервисного аккаунта: "Service account for GitHub Actions CI/CD pipeline" — установлено
- Роли подтверждены: Artifact Registry Writer, Cloud Run Developer, Service Account User, Storage Admin
- Файл ключа: `github-actions-key.json`
  - Формат: корректный JSON, размер ~2412 байт
  - Поля проверены: `client_email` и `project_id` соответствуют проекту
- Secret Manager:
  - Секрет: `github-actions-sa-key` создан
  - Версии: 2 версии (активная + резерв)
  - Репликация: регион `us-central1`

## Шаги создания
1. Console → IAM & Admin → Service Accounts → Create Service Account
2. Название: `github-actions-deployer`, описание по желанию
3. Назначить роли (минимально):
   - Artifact Registry Writer
   - Cloud Run Developer
   - Service Account User
   - Storage Admin
4. Открыть созданный аккаунт → вкладка Keys → Add Key → Create new key (JSON)
5. Сохранить `github-actions-key.json` локально (не добавлять в репозиторий)
6. Добавить ключ в GitHub:
   - Repo → Settings → Secrets and variables → Actions → New repository secret
   - Name: `GCP_SA_KEY`
   - Value: полное содержимое `github-actions-key.json`
7. (Опционально) Сохранить ключ в Secret Manager:
   - `gcloud secrets create github-actions-key --data-file=github-actions-key.json`

## Ротация ключей
- Создать новый ключ (Keys → Add Key) → обновить GitHub Secret `GCP_SA_KEY` содержимым нового ключа.
- Удалить старый ключ (Keys → Delete) и обновить Secret Manager: `gcloud secrets versions add github-actions-key --data-file=new-key.json`.
- Проверить пайплайн с новым ключом, затем удалить старую версию из Secret Manager при необходимости.

## Использование в GitHub Actions
- В workflow используется аутентификация:
```yaml
- uses: google-github-actions/auth@v2
  with:
    credentials_json: ${{ secrets.GCP_SA_KEY }}
```
- Настройка Docker для Artifact Registry:
```yaml
- run: gcloud auth configure-docker us-central1-docker.pkg.dev
```
