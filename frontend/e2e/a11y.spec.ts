import { test, expect } from '@playwright/test'
import AxeBuilder from '@axe-core/playwright'

test('accessibility scan', async ({ page }) => {
  await page.goto('/')
  
  const accessibilityScanResults = await new AxeBuilder({ page }).analyze()
  
  expect(accessibilityScanResults.violations).toEqual([])
})
