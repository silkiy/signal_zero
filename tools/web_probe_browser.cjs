// Run against tools/web_probe_server.py with WEB_PROBE=true release build.
// Requires Playwright and an installed Chrome; all browser profiles are isolated.
const {chromium} = require('playwright');
const fs = require('node:fs/promises');
const assert = require('node:assert/strict');
const path = require('node:path');
const evidence = path.resolve('tasks/evidence');

async function status(frame) {
  return frame.evaluate(() => JSON.parse(window.signalZeroProbeStatus || '{}'));
}
async function ready(frame) {
  await frame.waitForFunction(() => {
    const p = JSON.parse(window.signalZeroProbeStatus || '{}');
    return p.ready && p.frames > 0;
  }, undefined, {timeout: 90000});
}
async function valueIs(frame, value) {
  await frame.waitForFunction(value => {
    const p = JSON.parse(window.signalZeroProbeStatus || '{}');
    return p.value === value;
  }, value);
}
async function scenario(browser, embedded) {
  const context = await browser.newContext({acceptDownloads: true, viewport: {width: 1280, height: 900}});
  const page = await context.newPage();
  const errors = [];
  const requests = [];
  page.on('pageerror', error => errors.push(String(error)));
  page.on('console', message => {
    if (message.type() === 'error') errors.push(message.text());
  });
  page.on('requestfailed', request => requests.push({url:request.url(), error:request.failure()?.errorText}));
  await page.goto(embedded ? 'http://localhost:8192/' : 'http://127.0.0.1:8191/');
  let frame = embedded ? page.frames().find(f => f.url().startsWith('http://127.0.0.1:8191/')) : page.mainFrame();
  if (!frame) {
    await page.waitForEvent('framenavigated', {predicate:f => f.url().startsWith('http://127.0.0.1:8191/')});
    frame = page.frames().find(f => f.url().startsWith('http://127.0.0.1:8191/'));
  }
  await ready(frame);
  const initial = await status(frame);
  await frame.getByLabel('Probe canvas', {exact:true}).click();
  await frame.waitForFunction(taps => JSON.parse(window.signalZeroProbeStatus || '{}').taps > taps, initial.taps);
  await frame.getByRole('button', {name: 'Increment', exact: true}).click();
  await valueIs(frame, initial.value + 1);
  const saved = initial.value + 1;
  const [download] = await Promise.all([
    page.waitForEvent('download'),
    frame.getByRole('button', {name: 'Export probe', exact: true}).click(),
  ]);
  const exported = path.join(evidence, embedded ? 'T004-iframe-export.json' : 'T004-direct-export.json');
  await download.saveAs(exported);
  assert.equal(JSON.parse(await fs.readFile(exported, 'utf8')).value, saved);
  await frame.locator('#probe-import').setInputFiles({
    name:'probe.json', mimeType:'application/json', buffer:Buffer.from('{"version":"sz-probe-1","value":37}'),
  });
  await valueIs(frame, 37);
  await frame.locator('#probe-import').setInputFiles({
    name:'bad.json', mimeType:'application/json', buffer:Buffer.from('{"version":"foreign","value":38}'),
  });
  await frame.waitForFunction(() => JSON.parse(window.signalZeroProbeStatus || '{}').operation === 'rejected');
  assert.equal((await status(frame)).value, 37);
  await frame.getByRole('button', {name:'Play tone', exact:true}).click();
  await frame.waitForFunction(() => JSON.parse(window.signalZeroProbeStatus || '{}').audio === 'running');
  await frame.getByRole('button', {name:'Mute', exact:true}).click();
  await frame.getByRole('button', {name:'Play tone', exact:true}).click();
  await frame.waitForFunction(() => JSON.parse(window.signalZeroProbeStatus || '{}').operation === 'muted-tone-skipped');
  await page.screenshot({path:path.join(evidence, embedded ? 'T004-iframe.png':'T004-direct.png'),fullPage:true});
  await page.reload();
  frame = embedded ? page.frames().find(f => f.url().startsWith('http://127.0.0.1:8191/')) : page.mainFrame();
  await ready(frame);
  await valueIs(frame, 37);
  // This proves continued offline execution after assets/workers have loaded.
  // Offline reload/cold install is explicitly NOT claimed by this check.
  await context.setOffline(true);
  await frame.getByRole('button', {name:'Increment',exact:true}).click();
  await valueIs(frame, 38);
  const offline = await status(frame);
  await context.setOffline(false);
  const result = {embedded, initial, afterReload:true, exportImport:true,
    invalidImportPreserved:true, audioUserGesture:true, mute:true, pointerInput:true,
    offlineReload:'not-tested',
    offlineIncrement:true, final:offline, errors, failedRequests:requests};
  await context.close();
  assert.equal(errors.length, 0, JSON.stringify(errors));
  return result;
}
async function foundation(browser) {
  const context = await browser.newContext({viewport:{width:1000,height:720}});
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(String(error)));
  page.on('console', message => {if(message.type()==='error') errors.push(message.text());});
  await page.goto('http://127.0.0.1:8193/');
  await page.locator('flutter-view').waitFor();
  // Playwright CSS locators pierce Flutter's nested open shadow roots. Plain
  // document.querySelector does not and would give a false-negative timeout.
  await page.locator('canvas').first().waitFor({state:'visible'});
  // Wait for Flutter's first frame, without depending on an always-animating
  // GameWidget reaching networkidle or exposing internal widget structure.
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  assert.equal(await page.title(), 'SIGNAL ZERO');
  assert.equal(await page.evaluate(() => typeof window.signalZeroProbeStatus), 'undefined');
  await page.screenshot({path:path.join(evidence,'T003-foundation.png'),fullPage:true});
  assert.equal(errors.length,0,JSON.stringify(errors));
  const result = {browser:await browser.version(),defaultShell:true,probeHookAbsent:true,errors};
  await fs.writeFile(path.join(evidence,'T003-browser.json'),JSON.stringify(result,null,2)+'\n');
  await context.close();
  return result;
}
(async () => {
  await fs.mkdir(evidence,{recursive:true});
  const browser = await chromium.launch({channel:'chrome',headless:true});
  try {
    if (process.argv.includes('--foundation')) {
      console.log(JSON.stringify(await foundation(browser),null,2));
      return;
    }
    const report = {browser:await browser.version(), checkedAt:new Date().toISOString(), results:[]};
    for (const embedded of [false,true]) {
      report.results.push(await scenario(browser,embedded));
    }
    await fs.writeFile(path.join(evidence,'T004-browser.json'),JSON.stringify(report,null,2)+'\n');
    console.log(JSON.stringify(report,null,2));
  } finally {await browser.close();}
})().catch(error => {console.error(error);process.exitCode=1;});
