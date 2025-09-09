import { test, expect } from '@playwright/test'

test('home page loads', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveTitle(/HTX Interface/)
})

test('ticker page shows WebSocket connection', async ({ page }) => {
  await page.goto('/ticker')
  
  // Wait for WebSocket connection status
  await expect(page.getByText(/connection/i)).toBeVisible({ timeout: 10000 })
  
  // Check for ticker controls
  await expect(page.getByRole('button')).toBeVisible()
})
