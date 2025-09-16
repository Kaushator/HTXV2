# HTXEnterface v2 — Spec Kit Report

This document consolidates project information for Copilot/Codex Spec Kit: services, run profiles, MCP, CI/CD, infrastructure, and scripts — all in one place.

## Overview
- Backend: FastAPI (`backend/`), Python 3.11
- Frontend: Next.js (`frontend/`), Node 20
- ML: FinGPT mock/serving (`fingpt/`), CUDA optional
- Data: PostgreSQL (pgvector), Redis
- Monitoring: Prometheus + Grafana
- Containers: Docker Compose with multiple profiles
- Dev: Devcontainers + VS Code tasks, MCP server for tooling

## Compose Stacks
- Base stack: `docker-compose.yml`
  - Services: `postgres:5432`, `redis:6379`, `backend:8000`, `frontend:3000`, `fingpt:8055` (GPU), `dev` (sleep)
- Optimized stack: `docker-compose.yml.optimized`
  - Adds resource limits, named volumes, network `htx-network`, Prometheus `9090`, Grafana `3001`
  - Redis host port mapped to `6389` to avoid conflicts
- Monitoring only: `infra/grafana/docker-compose.monitoring.yml`
  - `prometheus:9090`, `grafana:3000`, `node-exporter:9100`, `redis-exporter:9121`, `postgres-exporter:9187`, `alertmanager:9093`
- Local minimal: `docker-compose.local.yml`
  - Prebuilt images `htx-interface-app` (8000) and `htx-fingpt` (5000); host-mounted `~/htx`
- Legacy/Alt (HTX_V2): `HTX_V2/docker/docker-compose*.yml`
  - Includes `etl` and `ml`/`ml-gpu` services on `htxv2-network`

Quick commands:
- Base: `docker compose up -d`
- Optimized: `docker compose -f docker-compose.yml.optimized up -d`
- Monitoring: `docker compose -f infra/grafana/docker-compose.monitoring.yml up -d`

## Docker Images
- Backend: `backend/Dockerfile`, `backend/Dockerfile.optimized` (multi-stage, non-root, healthcheck)
- Frontend: `frontend/Dockerfile`, `frontend/Dockerfile.optimized` (builder + alpine runtime)
- FinGPT: `fingpt/Dockerfile`, `fingpt/Dockerfile.optimized` (CUDA 12.1 base, healthcheck)

GPU notes: FinGPT requires NVIDIA runtime. Use `.devcontainer/docker-compose.yml` `fingpt_mock:8080` for local dev if no GPU.

## Devcontainers
- Primary: `.devcontainer/docker-compose.yml` with `devcontainer`, `postgres`, `redis`, `mailhog`, `fingpt_mock`
- Alt: `.devcontainer/Codex-BackE/` and `.devcontainer/Copilot-FrontE/`
- Scripts: `.devcontainer/scripts/**` for init, checks, GitHub automation

VS Code tasks: `.vscode/tasks.json` includes targets for backend/frontend dev, tests, MCP dev/build/start, Docker compose, and GitHub helpers.

## MCP Server
- Implementation: `src/index.ts` (Node, TypeScript, `@modelcontextprotocol/sdk`)
- Reads `.env` via `dotenv`: `BACKEND_BASE`, `FINGPT_BASE`, `AI_PROVIDER`, `DEV_JOURNAL_PATH`, `REQUEST_TIMEOUT_MS`
- Tools: `health`, `list_assets`, `add_asset`, `delete_asset`, `analysis`, `upload_csv`, `journal_log`, `llm_generate`, `get_secret`, `trigger_finetune`

How to run:
- Dev: `npx tsx watch src/index.ts`
- Build/start: `npm run build && npm start`

Clients configuration examples:
- Claude Desktop (Windows) `claude_desktop_config.json`:
  ```json
  {
    "mcpServers": {
      "htx-mcp": { "command": "node", "args": ["dist/index.js"], "cwd": "E:\\HTXEnterface_v2", "env": {"NODE_ENV": "development"} }
    }
  }
  ```
- Copilot Chat (VS Code) `.vscode/settings.json`:
  ```json
  {
    "github.copilot.chat.mcp.enabled": true,
    "github.copilot.chat.mcpServers": {
      "htx-mcp": { "command": "node", "args": ["dist/index.js"], "cwd": "E:\\HTXEnterface_v2", "env": {"NODE_ENV": "development"} }
    }
  }
  ```
- Codex CLI tasks (user config example `~/.codex/config.toml`):
  ```toml
  [tasks.mcp_dev]
  description = "Run MCP server in dev (tsx watch)"
  command = ["npx","tsx","watch","src/index.ts"]
  cwd = "E:\\HTXEnterface_v2"
  env = { NODE_ENV = "development" }
  [tasks.mcp_start]
  description = "Run MCP server (built)"
  command = ["node","dist/index.js"]
  cwd = "E:\\HTXEnterface_v2"
  env = { NODE_ENV = "development" }
  ```

## CI/CD
- Workflows:
  - `.github/workflows/ci.yml`, `.github/workflows/ci-cd.yml`, `.github/workflows/release.yml`
  - Security: `.github/workflows/token-guard.yml`
  - Synthetic: `.github/workflows/synthetic.yml`
  - Status report: `.github/workflows/status-report.yml` (uses `.github/scripts/status_report.py`)

## Infrastructure (Terraform)
- Root: `infra/terraform/` (`main.tf`, `providers.tf`, `variables.tf`)
- Envs: `infra/terraform/envs/dev/`
- Modules: `infra/terraform/modules/{cicd,sql}/`
- Grafana/Prometheus config under `infra/grafana/`

## Testing
- Backend: `backend/tests/` (pytest), plus edge-case runners
- Frontend unit/UI: `frontend/src/**/__tests__`, `vitest`, `jest` config present
- Frontend e2e: `frontend/e2e/` (Playwright), synthetic tests `frontend/synthetic/`

## Helper Scripts (selection)
- Docker: `scripts/update-containers.ps1`, `.devcontainer/scripts/**` (init, checks, compose helpers)
- GitHub: `.devcontainer/scripts/github/**` and PowerShell equivalents (init repo, setup actions, auto PR, test actions)
- Security/Release: `scripts/release.js`, `.github/workflows/release.yml`, `scripts/docker/scan-security.ps1`

## Env Vars (key ones)
```
BACKEND_BASE=http://localhost:8000
FINGPT_BASE=http://localhost:8055 (or 8080 for mock)
AI_PROVIDER=local|openai|vertex
DATABASE_URL=postgresql://htx:htxpass@localhost:5432/htxdb
REDIS_URL=redis://localhost:6379
DEV_JOURNAL_PATH=./docs/dev-journal.md
REQUEST_TIMEOUT_MS=120000
```

## Quickstart
1) Optimized stack: `docker compose -f docker-compose.yml.optimized up -d`
2) Frontend at `http://localhost:3000`, Backend at `http://localhost:8000/healthz`
3) MCP (dev): `npx tsx watch src/index.ts` (reads `.env`)
4) Monitoring (optional): `docker compose -f infra/grafana/docker-compose.monitoring.yml up -d`

## Notes / Caveats
- FinGPT GPU requires NVIDIA container runtime; use `fingpt_mock:8080` otherwise
- Port conflicts: optimized stack maps Redis to host `6389`
- Multiple compose variants exist — avoid running overlapping stacks simultaneously

