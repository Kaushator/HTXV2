import 'dotenv/config';
import fetch from 'node-fetch';
import { z } from 'zod';
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema
} from '@modelcontextprotocol/sdk/types.js';
import fs from 'node:fs';
import path from 'node:path';

const BACKEND_BASE = process.env.BACKEND_BASE || 'http://localhost:8000';
const FINGPT_BASE = process.env.FINGPT_BASE || 'http://localhost:8055';
const AI_PROVIDER = (process.env.AI_PROVIDER || 'local').toLowerCase();
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || '';
const GCP_PROJECT = process.env.GCP_PROJECT || '';
const DEV_JOURNAL_PATH = process.env.DEV_JOURNAL_PATH || '../docs/dev-journal.md';
const REQUEST_TIMEOUT_MS = +(process.env.REQUEST_TIMEOUT_MS || '120000');

const server = new Server(
  {
    name: 'htx-mcp',
    version: '0.1.0',
  },
  {
    capabilities: {
      tools: {},
      resources: {},
    },
  }
);

function timeout(ms: number) {
  return new Promise((res) => setTimeout(res, ms));
}

async function safeFetch(url: string, opts: any = {}) {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const resp = await fetch(url, { signal: controller.signal, ...opts });
    return resp;
  } finally {
    clearTimeout(id);
  }
}

// ---------- Resource: dev journal (readable)
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  const p = path.resolve(process.cwd(), DEV_JOURNAL_PATH);
  return {
    resources: [{
      uri: `file://${p}`,
      mimeType: 'text/markdown',
      name: 'dev-journal',
      description: 'Журнал разработчика (read-only через MCP resources)'
    }]
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (req) => {
  const uri = req.params.uri;
  if (!uri.startsWith('file://')) {
    throw new Error('Only file:// resources are supported');
  }
  const filePath = uri.slice('file://'.length);
  const content = fs.readFileSync(filePath, 'utf-8');
  return { contents: [{ uri, mimeType: 'text/markdown', text: content }] };
});

// ---------- Tools
const tools = [
  {
    name: 'health',
    description: 'Проверяет связность с backend и FinGPT',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'list_assets',
    description: 'Получить список активов/монет из backend',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'add_asset',
    description: 'Добавить монету вручную',
    inputSchema: { type: 'object', properties: { symbol: { type: 'string' } }, required: ['symbol'] }
  },
  {
    name: 'delete_asset',
    description: 'Удалить монету вручную',
    inputSchema: { type: 'object', properties: { symbol: { type: 'string' } }, required: ['symbol'] }
  },
  {
    name: 'analysis',
    description: 'Сгенерировать AI-обзор по символу',
    inputSchema: { type: 'object', properties: { symbol: { type: 'string' } }, required: ['symbol'] }
  },
  {
    name: 'upload_csv',
    description: 'Загрузить CSV/XLSX в backend (base64)',
    inputSchema: {
      type: 'object',
      properties: { filename: { type: 'string' }, data_base64: { type: 'string' } },
      required: ['filename', 'data_base64']
    }
  },
  {
    name: 'journal_log',
    description: 'Добавить запись в журнал разработчика',
    inputSchema: { type: 'object', properties: { text: { type: 'string' } }, required: ['text'] }
  },
  {
    name: 'llm_generate',
    description: 'Единая точка генерации (local/openai/vertex в зависимости от AI_PROVIDER)',
    inputSchema: { type: 'object', properties: { prompt: { type: 'string' } }, required: ['prompt'] }
  },
  {
    name: 'get_secret',
    description: 'Прочитать секрет из env (GSM заглушка)',
    inputSchema: { type: 'object', properties: { name: { type: 'string' } }, required: ['name'] }
  },
  {
    name: 'trigger_finetune',
    description: 'Запустить процедуру обучения/дообучения (заглушка)',
    inputSchema: { type: 'object', properties: { dataset: { type: 'string' } }, required: ['dataset'] }
  },
  {
    name: 'pnl_summary',
    description: 'Получить сводку PnL из backend',
    inputSchema: { type: 'object', properties: { symbol: { type: 'string' } } }
  }
];

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools
}));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args } = req.params;

  async function ok(text: string, data?: any) {
    return { content: [{ type: 'text', text }], isError: false, data };
  }
  async function err(text: string) {
    return { content: [{ type: 'text', text }], isError: true };
  }

  try {
    switch (name) {
      case 'health': {
        const [a, b] = await Promise.all([
          safeFetch(`${BACKEND_BASE}/healthz`).then(r => r.ok ? r.json() : { ok: false }).catch(() => ({ ok: false })),
          safeFetch(`${FINGPT_BASE}/predict`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ text: 'ping' }) })
            .then(r => r.ok ? r.json() : { ok: false }).catch(() => ({ ok: false }))
        ]);
        return ok(`Backend: ${(a as any).ok ? 'ok' : 'fail'}, FinGPT: ${(b as any).score ? 'ok' : 'fail'}`, { backend: a, fingpt: b });
      }

      case 'list_assets': {
        // ожидается, что backend реализует GET /assets/list
        const r = await safeFetch(`${BACKEND_BASE}/assets/list`).catch(() => null);
        if (!r || !r.ok) return err('Не удалось получить список активов');
        const data = await r.json();
        return ok(`Всего активов: ${Array.isArray(data) ? data.length : 'n/a'}`, data);
      }

      case 'add_asset': {
        const symbol = (args as any)?.symbol || '';
        if (!symbol) return err('symbol is required');
        const r = await safeFetch(`${BACKEND_BASE}/assets/add?symbol=${encodeURIComponent(symbol)}`);
        if (!r.ok) return err('Ошибка добавления актива');
        const data = await r.json();
        return ok(`Добавлено: ${symbol}`, data);
      }

      case 'delete_asset': {
        const symbol = (args as any)?.symbol || '';
        if (!symbol) return err('symbol is required');
        const r = await safeFetch(`${BACKEND_BASE}/assets/delete?symbol=${encodeURIComponent(symbol)}`);
        if (!r.ok) return err('Ошибка удаления актива');
        const data = await r.json();
        return ok(`Удалено: ${symbol}`, data);
      }

      case 'analysis': {
        const symbol = (args as any)?.symbol || 'BTC';
        const r = await safeFetch(`${BACKEND_BASE}/analysis?symbol=${encodeURIComponent(symbol)}`);
        if (!r.ok) return err('Ошибка генерации анализа');
        const data = await r.json();
        return ok(`Аналитика для ${symbol}: ${(data as any).analysis?.slice(0,120) ?? ''}...`, data);
      }

      case 'upload_csv': {
        const filename = (args as any)?.filename || 'data.csv';
        const data64 = (args as any)?.data_base64 || '';
        if (!data64) return err('data_base64 is required');
        const boundary = '----mcpBoundary' + Date.now();
        const body = `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${filename}"\r\nContent-Type: application/octet-stream\r\n\r\n${Buffer.from(data64,'base64').toString('binary')}\r\n--${boundary}--\r\n`;
        const r = await safeFetch(`${BACKEND_BASE}/ingest/upload`, {
          method: 'POST',
          headers: { 'Content-Type': 'multipart/form-data; boundary=' + boundary },
          body
        });
        if (!r.ok) return err('Ошибка загрузки файла');
        const data = await r.json();
        return ok(`Загружен файл: ${filename}`, data);
      }

      case 'journal_log': {
        const text = (args as any)?.text || '';
        if (!text) return err('text is required');
        const p = path.resolve(process.cwd(), DEV_JOURNAL_PATH);
        const line = `- [x] ${text} — MCP (${new Date().toISOString()})\n`;
        fs.appendFileSync(p, line, 'utf-8');
        return ok('Запись добавлена в журнал', { path: p });
      }

      case 'llm_generate': {
        const prompt = (args as any)?.prompt || '';
        if (!prompt) return err('prompt is required');
        if (AI_PROVIDER === 'local') {
          const r = await safeFetch(`${FINGPT_BASE}/predict`, {
            method: 'POST', headers: { 'content-type': 'application/json' },
            body: JSON.stringify({ text: prompt })
          });
          if (!r.ok) return err('FinGPT недоступен');
          const data = await r.json();
          return ok(`local: score=${(data as any).score}`, data);
        } else if (AI_PROVIDER === 'openai') {
          if (!OPENAI_API_KEY) return err('OPENAI_API_KEY не задан');
          // Заглушка без сетевого вызова — экономим токены и избегаем внешних запросов в dev
          return ok('openai (stub): возвращаю эхо-результат', { prompt });
        } else if (AI_PROVIDER === 'vertex') {
          return ok(`vertex (stub): проект ${GCP_PROJECT}`, { prompt, project: GCP_PROJECT });
        } else {
          return err('Неизвестный AI_PROVIDER');
        }
      }

      case 'get_secret': {
        const name = (args as any)?.name || '';
        if (!name) return err('name is required');
        const val = process.env[name];
        if (!val) return err('секрет не найден (env)');
        return ok(`секрет ${name}: найден`, { name, length: val.length });
      }

      case 'trigger_finetune': {
        const dataset = (args as any)?.dataset || 'default';
        // Ожидается, что backend реализует endpoint обучения, например /ml/finetune
        const r = await safeFetch(`${BACKEND_BASE}/ml/finetune?dataset=${encodeURIComponent(dataset)}`)
          .catch(() => null);
        if (!r || !r.ok) return err('Ошибка запуска обучения (или endpoint не реализован)');
        const data = await r.json();
        return ok('Файнтьюн запущен', data);
      }

      case 'pnl_summary': {
        const symbol = (args as any)?.symbol;
        const q = symbol ? `?symbol=${encodeURIComponent(symbol)}` : '';
        const r = await safeFetch(`${BACKEND_BASE}/pnl/summary${q}`).catch(() => null);
        if (!r || !r.ok) return err('Не удалось получить PnL summary');
        const data = await r.json();
        return ok(`PNL summary${symbol? ' for '+symbol: ''}`, data);
      }

      default:
        return err(`Unknown tool: ${name}`);
    }
  } catch (e: any) {
    return err(`Error: ${e?.message || String(e)}`);
  }
});

// Start
const transport = new StdioServerTransport();
await server.connect(transport);
