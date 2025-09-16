import { describe, expect, test } from "@jest/globals";
import fetch from "node-fetch";

const API_URL = "http://localhost:3000"; // Измените на ваш URL API

describe("API Tests", () => {
  test("API should be accessible", async () => {
    try {
      const response = await fetch(API_URL);
      expect(response.status).toBe(200);
    } catch (error) {
      // Тест упадет, если API недоступен
      throw error;
    }
  });

  // Добавьте здесь больше тестов для конкретных endpoint'ов
});
