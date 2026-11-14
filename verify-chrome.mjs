import { chromium } from 'playwright';

async function verifyBrowser(label, options) {
    const browser = await chromium.launch(options);
    try {
        const version = browser.version();
        const page = await browser.newPage();
        await page.setContent('<!DOCTYPE html><html><head><title>Playwright Verify</title></head><body><main id="status">READY</main></body></html>');
        const title = await page.title();
        const text = await page.locator('#status').textContent();
        if (title !== 'Playwright Verify' || text !== 'READY') {
            throw new Error(`Unexpected page content: title=${title}, text=${text}`);
        }
        console.log(`[PASS] ${label} (v${version}) launched and verified successfully.`);
    } finally {
        await browser.close();
    }
}

await verifyBrowser('Google Chrome Stable (headless)', {
    channel: 'chrome',
    headless: true,
});

await verifyBrowser('Playwright Bundled Chromium (headless)', {
    headless: true,
});

if (process.env.DISPLAY) {
    await verifyBrowser(`Google Chrome Stable (KDE Desktop ${process.env.DISPLAY})`, {
        channel: 'chrome',
        headless: false,
    });
}
