import { test, expect } from '@playwright/test';

test.describe('Critical User Journeys', () => {
  test('Homepage loads and displays key elements', async ({ page }) => {
    await page.goto('/');
    
    // Check critical elements load
    await expect(page.locator('h1')).toBeVisible();
    await expect(page.locator('[data-testid="price-ticker"]')).toBeVisible({ timeout: 10000 });
    
    // Performance check
    const navigationTiming = await page.evaluate(() => performance.getEntriesByType('navigation')[0]);
    expect(navigationTiming.loadEventEnd - navigationTiming.loadEventStart).toBeLessThan(3000);
  });

  test('WebSocket connection establishes', async ({ page }) => {
    let wsConnected = false;
    
    page.on('websocket', ws => {
      wsConnected = true;
      ws.on('framesent', event => console.log('WS Frame sent:', event.payload));
      ws.on('framereceived', event => console.log('WS Frame received:', event.payload));
    });
    
    await page.goto('/');
    await page.waitForTimeout(5000); // Wait for WS connection
    
    expect(wsConnected).toBe(true);
  });

  test('API health endpoints respond', async ({ request }) => {
    const healthResponse = await request.get('/health');
    expect(healthResponse.status()).toBe(200);
    
    const healthzResponse = await request.get('/healthz');
    expect(healthzResponse.status()).toBe(200);
  });

  test('Price data loads within SLA', async ({ page }) => {
    const startTime = Date.now();
    
    await page.goto('/');
    
    // Wait for price data to load
    await expect(page.locator('[data-testid="btc-price"]')).toBeVisible({ timeout: 15000 });
    
    const loadTime = Date.now() - startTime;
    expect(loadTime).toBeLessThan(15000); // 15s SLA
  });

  test('Error boundaries work correctly', async ({ page }) => {
    // Simulate network failure
    await page.route('**/api/**', route => route.abort());
    
    await page.goto('/');
    
    // Should show error state, not crash
    await expect(page.locator('[data-testid="error-boundary"]')).toBeVisible({ timeout: 10000 });
  });
});
