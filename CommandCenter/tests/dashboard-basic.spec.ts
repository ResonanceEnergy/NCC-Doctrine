import { test, expect } from '@playwright/test';

// Basic E2E test for dashboard root
// Assumes dashboard is running at production

test('Dashboard loads and main widgets are visible', async ({ page }) => {
  await page.goto('https://resonanceenergy.github.io/NCC-Doctrine/');
  
  // Login with username/password
  await page.fill('input[type="text"]', 'azprime');
  await page.fill('input[type="password"]', 'ncc2026');
  await page.click('button[type="submit"]');
  
  // Wait for dashboard to load
  await page.waitForSelector('.min-h-screen', { timeout: 10000 });
  
  // Verify we're on the dashboard (not login page)
  await expect(page.locator('h2:has-text("NCC Doctrine Access")')).not.toBeVisible();
  
  // Check that main dashboard elements are present
  await expect(page.locator('.min-h-screen')).toBeVisible();
  await expect(page.getByTestId('btn')).toHaveCount(4);
  await expect(page.getByTestId('panel-metrics')).toBeVisible();
  await expect(page.getByTestId('priority-list')).toBeVisible();
  await expect(page.getByTestId('activity-feed')).toBeVisible();
});
