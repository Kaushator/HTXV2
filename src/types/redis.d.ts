/**
 * Интерфейс для расширений Redis для работы с TypeScript
 */
declare module "redis" {
  export interface RedisClientType {
    connect(): Promise<void>;
    quit(): Promise<void>;
    set(key: string, value: string): Promise<void>;
    setEx(key: string, ttl: number, value: string): Promise<void>;
    get(key: string): Promise<string | null>;
    del(key: string): Promise<void>;
    on(event: string, listener: (...args: any[]) => void): void;
  }

  export function createClient(options?: any): RedisClientType;
}
