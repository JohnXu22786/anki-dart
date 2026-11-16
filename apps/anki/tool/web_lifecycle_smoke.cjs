// Copyright (c) 2026 John Tsui <110079544+JohnXu22786@users.noreply.github.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// Run against a served `flutter build web` output. Requires Node.js and Playwright.
const { chromium } = require('playwright');

const baseUrl = process.env.ANKI_WEB_BASE_URL || 'http://127.0.0.1:8099';
const executablePath = process.env.CHROMIUM_EXECUTABLE_PATH;
const launchOptions = {
  headless: true,
  args: ['--no-sandbox'],
};
if (executablePath) launchOptions.executablePath = executablePath;

(async () => {
  const browser = await chromium.launch(launchOptions);
  try {
    const page = await browser.newPage();
    page.on('pageerror', (error) => console.error('PAGEERROR', error.message));
    page.on('console', (message) => {
      if (message.type() === 'error') console.error('CONSOLE', message.text());
    });
    await page.goto(baseUrl, { waitUntil: 'networkidle' });
    await page.locator('flt-semantics-placeholder').press('Enter');
    await page.getByText('Welcome to Anki').waitFor({ timeout: 30000 });
    await page.getByRole('button', { name: 'Set up Anki' }).click();
    await page.getByText('Active profile: Default').waitFor({ timeout: 60000 });
    assertCollectionDatabase(await page.evaluate(() => indexedDB.databases()));

    await page.getByRole('button', { name: 'Profiles' }).click();
    await page.getByRole('button', { name: /Add profile/ }).click();
    await page.getByLabel('Profile name').fill('Web Work');
    await page.getByRole('button', { name: 'Add', exact: true }).click();
    await page.getByRole('button', { name: /Web Work/ }).first().click();
    await page.getByRole('button', { name: 'Close' }).click();
    await page.getByText('Active profile: Web Work').waitFor({ timeout: 60000 });
    assertCollectionDatabase(await page.evaluate(() => indexedDB.databases()));

    await page.reload({ waitUntil: 'networkidle' });
    await page.locator('flt-semantics-placeholder').press('Enter');
    await page.getByText('Active profile: Web Work').waitFor({ timeout: 60000 });
    const databases = await page.evaluate(() => indexedDB.databases());
    assertCollectionDatabase(databases);
    console.log(JSON.stringify({
      firstRunCreated: true,
      switchedProfile: true,
      reopenedAfterReload: true,
      databases,
    }));
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});

function assertCollectionDatabase(databases) {
  if (!databases.some((database) => database.name === 'anki.collection.sqlite.v1')) {
    throw new Error(`missing collection IndexedDB: ${JSON.stringify(databases)}`);
  }
}
