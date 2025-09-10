import type { paths } from './api'

type ApiClient = {
  get<T extends keyof paths>(
    path: T,
    ...args: paths[T] extends { get: { parameters: any } }
      ? [params: paths[T]['get']['parameters']]
      : []
  ): Promise<
    paths[T] extends { get: { responses: { 200: { content: { 'application/json': infer R } } } } }
      ? R
      : unknown
  >
}

export const createApiClient = (baseUrl: string = '/api'): ApiClient => ({
  async get(path, params?) {
    const url = new URL(path as string, baseUrl)
    if (params?.query) {
      Object.entries(params.query).forEach(([k, v]) => {
        if (v !== undefined) url.searchParams.set(k, String(v))
      })
    }
    
    const res = await fetch(url.toString())
    if (!res.ok) throw new Error(`API error: ${res.status}`)
    return res.json()
  }
})

export type { paths } from './api'
