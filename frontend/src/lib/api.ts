const BASE = process.env.NEXT_PUBLIC_BACKEND_URL || process.env.BACKEND_BASE || 'http://localhost:8000'

export async function getHealth(): Promise<Response> {
  return fetch('/health', { cache: 'no-store' })
}

export async function getCoins() {
  const res = await fetch('/api/coins', { cache: 'no-store' })
  if (!res.ok) throw new Error('Failed to load coins')
  return res.json()
}

export async function getAnalysis(symbol: string) {
  const res = await fetch(`/api/analysis/${symbol}`, { cache: 'no-store' })
  if (!res.ok) throw new Error('Failed to load analysis')
  return res.json()
}

export const endpoints = {
  backendBase: BASE,
}

