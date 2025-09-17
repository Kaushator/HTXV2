/**
 * Сервис для работы с Redis
 */

import { createClient, RedisClientType } from "redis";

let redisClient: RedisClientType | null = null;

/**
 * Инициализация клиента Redis
 */
export async function initRedisClient(
  url: string = "redis://localhost:6379"
): Promise<RedisClientType | null> {
  try {
    if (redisClient) {
      return redisClient;
    }

    redisClient = createClient({
      url,
    }) as RedisClientType;

    redisClient.on("error", (err: Error) => {
      console.error("🔴 Redis клиент ошибка:", err);
    });

    redisClient.on("ready", () => {
      console.log("🟢 Redis клиент готов");
    });

    await redisClient.connect();
    return redisClient;
  } catch (err) {
    console.error("🔴 Ошибка инициализации Redis:", err);
    return null;
  }
}

/**
 * Получить клиент Redis
 */
export function getRedisClient(): RedisClientType | null {
  return redisClient;
}

/**
 * Сохранить данные в Redis
 */
export async function setRedisData(
  key: string,
  data: any,
  ttlSeconds?: number
): Promise<void> {
  if (!redisClient) {
    throw new Error("Redis клиент не инициализирован");
  }

  try {
    const serialized = JSON.stringify(data);
    if (ttlSeconds) {
      await redisClient.setEx(key, ttlSeconds, serialized);
    } else {
      await redisClient.set(key, serialized);
    }
  } catch (err) {
    console.error(`🔴 Ошибка сохранения данных в Redis для ключа ${key}:`, err);
    throw err;
  }
}

/**
 * Получить данные из Redis
 */
export async function getRedisData<T>(key: string): Promise<T | null> {
  if (!redisClient) {
    throw new Error("Redis клиент не инициализирован");
  }

  try {
    const data = await redisClient.get(key);
    if (!data) return null;
    return JSON.parse(data) as T;
  } catch (err) {
    console.error(`🔴 Ошибка получения данных из Redis для ключа ${key}:`, err);
    return null;
  }
}

/**
 * Удалить данные из Redis
 */
export async function deleteRedisData(key: string): Promise<void> {
  if (!redisClient) {
    throw new Error("Redis клиент не инициализирован");
  }

  try {
    await redisClient.del(key);
  } catch (err) {
    console.error(`🔴 Ошибка удаления данных из Redis для ключа ${key}:`, err);
    throw err;
  }
}

/**
 * Закрыть соединение с Redis
 */
export async function closeRedisConnection(): Promise<void> {
  if (redisClient) {
    await redisClient.quit();
    redisClient = null;
    console.log("🟢 Redis соединение закрыто");
  }
}
