import { test, expect } from '@playwright/test';

test('Google Chrome launches and renders page cleanly', async ({ page }) => {
    await page.setContent('<!DOCTYPE html><html><head><title>Chrome Smoke Test</title></head><body><h1>OK</h1></body></html>');
    await expect(page).toHaveTitle('Chrome Smoke Test');
    await expect(page.locator('h1')).toHaveText('OK');
});
