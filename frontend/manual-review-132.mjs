import { chromium } from "playwright";
import fs from "fs";
import path from "path";

const BASE = process.env.BASE || "http://localhost:5173";
const OUT = path.resolve("manual_review/132");
fs.mkdirSync(OUT, { recursive: true });

const VIEWPORTS = [
  { key: "desktop", width: 1440, height: 900 },
  { key: "laptop", width: 1366, height: 768 },
  { key: "tablet", width: 768, height: 1024 },
  { key: "mobile", width: 390, height: 844 },
  { key: "mobile-min", width: 320, height: 640 },
];

const FARMER_ID = "6a6d9357b9a0ef641ae50967";
const FARM_ID = "6a6d9357b9a0ef641ae50971";

const ROUTES = [
  { path: "/dashboard", key: "dashboard", slow: true },
  { path: `/dashboard/farm/${FARM_ID}`, key: "farm-dashboard", slow: true },
  { path: "/companies", key: "companies" },
  { path: "/farms", key: "farms" },
  { path: "/zones", key: "zones" },
  { path: "/trees", key: "trees" },
  { path: "/users", key: "users" },
  { path: `/users/${FARMER_ID}`, key: "farmer-overview", slow: true },
  { path: "/inspections", key: "inspections" },
  { path: "/detection-results", key: "detection-results" },
  { path: "/disease-history", key: "disease-history" },
  { path: "/alerts", key: "alerts" },
  { path: "/diseases", key: "diseases" },
  { path: "/settings", key: "settings" },
];

const results = [];
const log = (msg) => console.log(`[${new Date().toISOString().slice(11, 19)}] ${msg}`);

function attachWatchers(page) {
  const w = { pageErrors: [], consoleErrors: [], httpErrors: [], apiTimings: {} };
  page.on("pageerror", (e) => w.pageErrors.push(String(e).slice(0, 400)));
  page.on("console", (m) => {
    if (m.type() === "error") w.consoleErrors.push(m.text().slice(0, 400));
  });
  page.on("request", (r) => {
    if (r.url().includes("/api/")) w.apiTimings[r.url()] = Date.now();
  });
  page.on("response", (r) => {
    const st = r.status();
    const url = r.url();
    if (st >= 400 && !/favicon|\.map/.test(url)) {
      w.httpErrors.push({ status: st, url: url.slice(0, 140) });
    }
    if (url.includes("/api/") && w.apiTimings[url]) {
      w.apiTimings[url] = Date.now() - w.apiTimings[url];
    }
  });
  return w;
}

async function settle(page, maxWait) {
  const t0 = Date.now();
  try {
    await page.waitForLoadState("networkidle", { timeout: maxWait });
  } catch {}
  try {
    await page.waitForFunction(
      () => document.querySelectorAll(".animate-pulse").length === 0,
      null,
      { timeout: 25000 }
    );
  } catch {}
  await page.waitForTimeout(1200);
  return Date.now() - t0;
}

async function scanOverflow(page) {
  return page.evaluate(() => {
    const vw = window.innerWidth;
    const de = document.documentElement;
    const docOverflow = Math.max(0, de.scrollWidth - vw, document.body.scrollWidth - vw);
    const main = document.querySelector("main");
    const mainOverflow = main ? Math.max(0, main.scrollWidth - main.clientWidth) : 0;
    const bad = [];
    for (const el of document.querySelectorAll("body *")) {
      if (el.closest("script,style,noscript")) continue;
      const r = el.getBoundingClientRect();
      if (r.width === 0 && r.height === 0) continue;
      if (r.right > vw + 1) {
        let inScroll = false;
        let a = el.parentElement;
        while (a && a !== document.body) {
          const cs = getComputedStyle(a);
          if ((cs.overflowX === "auto" || cs.overflowX === "scroll") && a.scrollWidth > a.clientWidth) {
            inScroll = true;
            break;
          }
          a = a.parentElement;
        }
        if (!inScroll) {
          bad.push({ tag: el.tagName, cls: String(el.className || "").slice(0, 90), rr: Math.round(r.right), rw: Math.round(r.width) });
        }
      }
    }
    const scrollables = [];
    for (const el of document.querySelectorAll("main *")) {
      if (el.scrollWidth > el.clientWidth + 1) {
        const cs = getComputedStyle(el);
        if (cs.overflowX === "auto" || cs.overflowX === "scroll") {
          scrollables.push({ tag: el.tagName, cls: String(el.className || "").slice(0, 70), over: el.scrollWidth - el.clientWidth });
        }
      }
    }
    return { docOverflow, mainOverflow, bad, scrollables };
  });
}

async function contentProbe(page) {
  return page.evaluate(() => {
    const h1 = document.querySelector("main h1, .text-lg.font-bold")?.textContent || "";
    const tables = document.querySelectorAll("main table").length;
    const rows = document.querySelectorAll("main tbody tr:not(.animate-pulse)").length;
    const cards = document.querySelectorAll("main [class*='rounded-']").length;
    const title = document.title;
    return { h1: h1.trim().slice(0, 60), tables, rows, cards, title };
  });
}

async function login(page) {
  await page.goto(`${BASE}/login`, { waitUntil: "domcontentloaded" });
  await page.waitForLoadState("networkidle", { timeout: 20000 }).catch(() => {});
  await page.fill('input[type="email"]', "bao@gmail.com");
  await page.fill('input[type="password"]', "123456");
  await page.click('button[type="submit"]');
  await page.waitForURL("**/dashboard", { timeout: 60000 });
  log("logged in as admin");
}

const browser = await chromium.launch({ headless: true });
const summary = { viewports: [], routeChecks: [], totalChecks: 0, passed: 0, failed: 0, failures: [], screenshots: [] };

const PHASE = process.env.PHASE || "all";

if (PHASE === "all" || PHASE === "scan") {
  for (const vp of VIEWPORTS) {
    const context = await browser.newContext({ viewport: { width: vp.width, height: vp.height } });
    const page = await context.newPage();
    const w = attachWatchers(page);
    try {
      await login(page);
    } catch (e) {
      log(`LOGIN FAILED at ${vp.key}: ${e}`);
      await context.close();
      continue;
    }

    for (const route of ROUTES) {
      const rec = { viewport: vp.key, route: route.key, path: route.path, ok: true, problems: [] };
      try {
        const t0 = Date.now();
        await page.goto(`${BASE}${route.path}`, { waitUntil: "domcontentloaded" });
        const navMs = await settle(page, route.slow ? 65000 : 35000);
        rec.navMs = navMs;

        const over = await scanOverflow(page);
        rec.overflow = over;

        if (over.mainOverflow > 1) {
          rec.ok = false;
          rec.problems.push(`mainOverflow=${over.mainOverflow}`);
        }
        if (over.docOverflow > 1) {
          rec.ok = false;
          rec.problems.push(`docOverflow=${over.docOverflow}`);
        }
        if (over.bad.length > 0) {
          rec.ok = false;
          rec.problems.push(`bad elements: ${JSON.stringify(over.bad.slice(0, 5))}`);
        }

        const probe = await contentProbe(page);
        rec.content = probe;
        if (probe.tables === 0 && probe.rows === 0 && route.key !== "dashboard" && route.key !== "farm-dashboard" && route.key !== "farmer-overview" && route.key !== "settings" && route.key !== "disease-history" && route.key !== "detection-results" && route.key !== "alerts" && route.key !== "diseases") {
          // CRUD pages should render a table; skip soft for others
        }

        const shot = `viewport-${route.key}-${vp.key}.png`;
        await page.screenshot({ path: path.join(OUT, shot) });
        rec.screenshot = shot;
        summary.screenshots.push(shot);

        if (w.pageErrors.length) {
          rec.ok = false;
          rec.problems.push(`pageErrors=${JSON.stringify(w.pageErrors)}`);
        }
        if (w.httpErrors.length) {
          rec.ok = false;
          rec.problems.push(`httpErrors=${JSON.stringify(w.httpErrors)}`);
        }
      } catch (e) {
        rec.ok = false;
        rec.problems.push(`exception: ${String(e).slice(0, 300)}`);
      }

      rec.consoleErrors = [...w.consoleErrors];
      rec.pageErrors = [...w.pageErrors];
      rec.httpErrors = [...w.httpErrors];
      rec.apiCalls = Object.entries(w.apiTimings).map(([url, ms]) => ({ url: url.replace(/^https?:\/\/[^/]+/, "").slice(0, 90), ms })).filter((x) => x.ms >= 0);

      w.pageErrors.length = 0;
      w.consoleErrors.length = 0;
      w.httpErrors.length = 0;
      w.apiTimings = {};

      results.push(rec);
      summary.totalChecks++;
      rec.ok ? summary.passed++ : summary.failed++;
      if (!rec.ok) summary.failures.push(rec);
      log(`${vp.key} ${route.key} -> ${rec.ok ? "OK" : "FAIL"} (${rec.navMs ?? "-"}ms) overflow=${rec.overflow?.mainOverflow ?? "?"}/${rec.overflow?.docOverflow ?? "?"} bad=${rec.overflow?.bad?.length ?? 0}`);
    }
    await context.close();
  }
}

if (PHASE === "all" || PHASE === "interact") {
  // ---- Desktop interactions ----
  const ctxD = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const pageD = await ctxD.newPage();
  await attachWatchers(pageD);
  await login(pageD);

  // 1. Sidebar click-through
  const navTest = { name: "sidebar-clickthrough", checks: [] };
  const links = [
    { label: "Bảng điều khiển", path: "/dashboard" },
    { label: "Công ty", path: "/companies" },
    { label: "Trang trại", path: "/farms" },
    { label: "Khu vực", path: "/zones" },
    { label: "Cây", path: "/trees" },
    { label: "Người dùng", path: "/users" },
    { label: "Kiểm tra", path: "/inspections" },
    { label: "Lịch sử phát sinh bệnh", path: "/disease-history" },
    { label: "Cảnh báo", path: "/alerts" },
  ];
  for (const l of links) {
    try {
      await pageD.click(`nav a[href="${l.path}"]`);
      await pageD.waitForURL(`**${l.path}`, { timeout: 15000 });
      await settle(pageD, 30000);
      const over = await scanOverflow(pageD);
      navTest.checks.push({ label: l.label, path: l.path, ok: over.mainOverflow <= 1 && over.bad.length === 0, detail: `over=${over.mainOverflow}/${over.docOverflow}` });
      await pageD.screenshot({ path: path.join(OUT, `nav-${l.label}.png`) });
    } catch (e) {
      navTest.checks.push({ label: l.label, path: l.path, ok: false, detail: String(e).slice(0, 200) });
    }
  }
  summary.nav = navTest;

  // 2. Header & Footer presence
  const headerOk = await pageD.evaluate(() => {
    const h = document.querySelector("header");
    if (!h) return false;
    return h.textContent.trim().length > 0;
  });
  await pageD.evaluate(() => { const m = document.querySelector("main"); if (m) m.scrollTo(0, m.scrollHeight); });
  await pageD.waitForTimeout(600);
  const footerOk = await pageD.evaluate(() => {
    const f = document.querySelector("footer");
    return f ? f.textContent.trim().length > 0 : false;
  });
  summary.headerFooter = { headerOk, footerOk };

  // 3. Users: edit drawer (desktop)
  const drawerDesktop = { name: "edit-drawer-desktop", checks: [] };
  try {
    await pageD.goto(`${BASE}/users`, { waitUntil: "domcontentloaded" });
    await settle(pageD, 40000);
    const editBtn = pageD.locator('button[aria-label^="Chỉnh sửa"]').first();
    await editBtn.waitFor({ timeout: 20000 });
    await editBtn.click();
    await pageD.waitForTimeout(1500);
    const dInfo = await pageD.evaluate(() => {
      const overlay = document.querySelector('[class*="fixed"]');
      const vw = window.innerWidth;
      const bad = [];
      for (const el of document.querySelectorAll("body *")) {
        const r = el.getBoundingClientRect();
        if (r.width === 0) continue;
        if (r.right > vw + 1 && !el.closest('[class*="overflow-x-auto"]')) bad.push(el.tagName);
      }
      return { hasOverlay: !!overlay, bad: bad.slice(0, 10), vw };
    });
    drawerDesktop.checks.push({ name: "drawer-opens-without-overflow", ok: dInfo.bad.length === 0, detail: JSON.stringify(dInfo) });
    await pageD.screenshot({ path: path.join(OUT, "drawer-edit-desktop.png") });
    // close
    await pageD.keyboard.press("Escape");
    await pageD.waitForTimeout(600);
  } catch (e) {
    drawerDesktop.checks.push({ name: "drawer", ok: false, detail: String(e).slice(0, 200) });
  }
  summary.drawerDesktop = drawerDesktop;

  // 4. Trees detail drawer + pagination
  const treeTest = { name: "trees-detail+pagination", checks: [] };
  try {
    await pageD.goto(`${BASE}/trees`, { waitUntil: "domcontentloaded" });
    await settle(pageD, 45000);
    await pageD.locator('button[title="Xem"]').first().waitFor({ timeout: 20000 });
    await pageD.locator('button[title="Xem"]').first().click();
    await pageD.waitForTimeout(2500);
    const detailOk = await pageD.evaluate(() => {
      const vw = window.innerWidth;
      let bad = 0;
      for (const el of document.querySelectorAll("body *")) {
        const r = el.getBoundingClientRect();
        if (r.width === 0) continue;
        if (r.right > vw + 1 && !el.closest('[class*="overflow-x-auto"]')) bad++;
      }
      return { bad, text: document.body.innerText.includes("Kết quả nhận diện") || document.body.innerText.includes("Nhận diện") };
    });
    treeTest.checks.push({ name: "detail-drawer", ok: detailOk.bad === 0, detail: JSON.stringify(detailOk) });
    await pageD.screenshot({ path: path.join(OUT, "drawer-tree-detail-desktop.png") });
    await pageD.keyboard.press("Escape");
    await pageD.waitForTimeout(600);

    const pageBefore = await pageD.locator('button[aria-label="Đến trang 2"]').count();
    if (pageBefore > 0) {
      await pageD.locator('button[aria-label="Đến trang 2"]').first().click();
      await settle(pageD, 30000);
      const after = await pageD.evaluate(() => {
        const active = document.querySelector('button[aria-label="Đến trang 2"]');
        const vw = window.innerWidth;
        let bad = 0;
        for (const el of document.querySelectorAll("body *")) {
          const r = el.getBoundingClientRect();
          if (r.width === 0) continue;
          if (r.right > vw + 1 && !el.closest('[class*="overflow-x-auto"]')) bad++;
        }
        return { bad };
      });
      treeTest.checks.push({ name: "pagination-to-page2", ok: after.bad === 0, detail: JSON.stringify(after) });
    } else {
      treeTest.checks.push({ name: "pagination-available", ok: false, detail: "no page-2 button found" });
    }
  } catch (e) {
    treeTest.checks.push({ name: "trees-test", ok: false, detail: String(e).slice(0, 200) });
  }
  summary.treesTest = treeTest;

  // 5. Dashboard (desktop): KPI/charts/heatmap presence
  const dashTest = { name: "dashboard-desktop", checks: [] };
  try {
    await pageD.goto(`${BASE}/dashboard`, { waitUntil: "domcontentloaded" });
    const navMs = await settle(pageD, 65000);
    const dash = await pageD.evaluate(() => {
      const text = document.body.innerText;
      const heat = document.querySelector('[class*="overflow-x-auto"]');
      return {
        hasKpi: ["Cây khỏe mạnh", "Khỏe mạnh", "Cây trồng", "Tổng"].some((s) => text.includes(s)),
        hasHeatmap: !!heat,
        heatScrollable: heat ? heat.scrollWidth > heat.clientWidth : false,
        hasChart: document.querySelectorAll("svg.recharts-surface, .recharts-wrapper, svg").length > 0,
        svgCount: document.querySelectorAll("svg").length,
        cardCount: document.querySelectorAll("main [class*='rounded-']").length,
      };
    });
    dashTest.checks.push({ name: "dashboard-rendered", ok: dash.hasKpi && dash.cardCount > 4, detail: JSON.stringify(dash) });
    await pageD.screenshot({ path: path.join(OUT, "dashboard-desktop.png") });
    summary.dashTest = dashTest;
  } catch (e) {
    dashTest.checks.push({ name: "dashboard", ok: false, detail: String(e).slice(0, 200) });
    summary.dashTest = dashTest;
  }
  await ctxD.close();

  // ---- Mobile interactions ----
  const ctxM = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const pageM = await ctxM.newPage();
  await attachWatchers(pageM);
  await login(pageM);

  // 6. Mobile sidebar toggle
  const mobNav = { name: "mobile-sidebar", checks: [] };
  try {
    const aside = pageM.locator("aside");
    const closedTransform = await aside.evaluate((el) => getComputedStyle(el).transform);
    mobNav.checks.push({ name: "sidebar-closed-default", ok: closedTransform !== "none", detail: closedTransform });
    await pageM.locator("button svg.lucide-menu").first().locator("..").click();
    await pageM.waitForTimeout(800);
    const openState = await pageM.evaluate(() => {
      const aside = document.querySelector("aside");
      const tr = getComputedStyle(aside).transform;
      const backdrop = document.querySelector('[class*="bg-black/40"]');
      const vw = window.innerWidth;
      let bad = 0;
      for (const el of document.querySelectorAll("body *")) {
        const r = el.getBoundingClientRect();
        if (r.width === 0) continue;
        if (r.right > vw + 1) bad++;
      }
      return { transform: tr, hasBackdrop: !!backdrop, bad };
    });
    mobNav.checks.push({ name: "sidebar-opens-on-mobile", ok: openState.transform === "none" && openState.hasBackdrop && openState.bad === 0, detail: JSON.stringify(openState) });
    await pageM.screenshot({ path: path.join(OUT, "mobile-sidebar-open.png") });
    if (openState.hasBackdrop) {
      await pageM.locator('[class*="bg-black/40"]').first().click({ position: { x: 300, y: 400 } });
      await pageM.waitForTimeout(700);
    }
  } catch (e) {
    mobNav.checks.push({ name: "mobile-sidebar", ok: false, detail: String(e).slice(0, 200) });
  }
  summary.mobileSidebar = mobNav;

  // 7. Users edit drawer (mobile)
  const drawerMobile = { name: "edit-drawer-mobile", checks: [] };
  try {
    await pageM.goto(`${BASE}/users`, { waitUntil: "domcontentloaded" });
    await settle(pageM, 40000);
    await pageM.locator('button[aria-label^="Chỉnh sửa"]').first().waitFor({ timeout: 20000 });
    await pageM.locator('button[aria-label^="Chỉnh sửa"]').first().click();
    await pageM.waitForTimeout(1500);
    const dInfo = await pageM.evaluate(() => {
      const vw = window.innerWidth;
      let bad = 0;
      for (const el of document.querySelectorAll("body *")) {
        const r = el.getBoundingClientRect();
        if (r.width === 0) continue;
        if (r.right > vw + 1) bad++;
      }
      return { bad };
    });
    drawerMobile.checks.push({ name: "drawer-opens-without-overflow", ok: dInfo.bad === 0, detail: JSON.stringify(dInfo) });
    await pageM.screenshot({ path: path.join(OUT, "drawer-edit-mobile.png") });
    await pageM.keyboard.press("Escape");
    await pageM.waitForTimeout(600);
  } catch (e) {
    drawerMobile.checks.push({ name: "drawer", ok: false, detail: String(e).slice(0, 200) });
  }
  summary.drawerMobile = drawerMobile;

  // 8. Dashboard heatmap scroll (mobile)
  const heatTest = { name: "heatmap-mobile-scroll", checks: [] };
  try {
    await pageM.goto(`${BASE}/dashboard`, { waitUntil: "domcontentloaded" });
    await settle(pageM, 65000);
    const heatInfo = await pageM.evaluate(() => {
      const els = [...document.querySelectorAll("main *")].filter((el) => {
        const cs = getComputedStyle(el);
        return (cs.overflowX === "auto" || cs.overflowX === "scroll") && el.scrollWidth > el.clientWidth + 1;
      });
      return els.map((el) => ({ cls: String(el.className || "").slice(0, 80), over: el.scrollWidth - el.clientWidth }));
    });
    heatTest.checks.push({ name: "heatmap-scrollable", ok: heatInfo.some((x) => x.over > 5), detail: JSON.stringify(heatInfo) });
    await pageM.screenshot({ path: path.join(OUT, "dashboard-mobile.png") });
    summary.heatmapMobile = heatTest;
  } catch (e) {
    heatTest.checks.push({ name: "heatmap", ok: false, detail: String(e).slice(0, 200) });
    summary.heatmapMobile = heatTest;
  }

  // 9. Farmer overview (mobile) + back nav
  const ovTest = { name: "farmer-overview-mobile", checks: [] };
  try {
    await pageM.goto(`${BASE}/users`, { waitUntil: "domcontentloaded" });
    await settle(pageM, 40000);
    const actBtn = pageM.locator('button[title="Tổng quan hoạt động"]').first();
    await actBtn.waitFor({ timeout: 20000 });
    await actBtn.click();
    await pageM.waitForURL("**/users/*", { timeout: 15000 });
    await settle(pageM, 65000);
    const ov = await pageM.evaluate(() => {
      const t = document.body.innerText;
      const has = {
        profile: t.includes("Hồ sơ") || t.includes("Email"),
        farm: t.includes("Số trang trại") || t.includes("Khu vực"),
        neighbor: t.includes("Đã gửi") || t.includes("Hàng xóm") || t.includes("Neighbor"),
        timeline: t.includes("Hoạt động") || t.includes("mới nhất"),
      };
      return has;
    });
    ovTest.checks.push({ name: "overview-sections", ok: ov.profile && ov.farm && ov.timeline, detail: JSON.stringify(ov) });
    await pageM.screenshot({ path: path.join(OUT, "farmer-overview-mobile.png") });
    const backBtn = pageM.locator('a[href="/users"], button:has-text("Người dùng")').first();
    await backBtn.click().catch(() => {});
    await pageM.waitForURL("**/users", { timeout: 15000 }).catch(() => {});
    ovTest.checks.push({ name: "back-navigation", ok: pageM.url().endsWith("/users"), detail: pageM.url() });
    summary.overviewMobile = ovTest;
  } catch (e) {
    ovTest.checks.push({ name: "overview", ok: false, detail: String(e).slice(0, 300) });
    summary.overviewMobile = ovTest;
  }
  await ctxM.close();

  // 10. Login / Register standalone overflow at 320
  const ctxL = await browser.newContext({ viewport: { width: 320, height: 640 } });
  const pageL = await ctxL.newPage();
  const wl = attachWatchers(pageL);
  const authTest = { name: "auth-pages-320", checks: [] };
  for (const [label, p] of [["login", "/login"], ["register", "/register"]]) {
    try {
      await pageL.goto(`${BASE}${p}`, { waitUntil: "domcontentloaded" });
      await settle(pageL, 20000);
      const over = await scanOverflow(pageL);
      authTest.checks.push({ name: `${label}-overflow`, ok: over.docOverflow <= 1 && over.bad.length === 0, detail: JSON.stringify(over) });
      await pageL.screenshot({ path: path.join(OUT, `${label}-320.png`) });
    } catch (e) {
      authTest.checks.push({ name: label, ok: false, detail: String(e).slice(0, 200) });
    }
  }
  authTest.checks.push({ name: "auth-console-errors", ok: wl.pageErrors.length === 0 && wl.consoleErrors.length === 0, detail: JSON.stringify({ pe: wl.pageErrors, ce: wl.consoleErrors }) });
  summary.authTest = authTest;
  await ctxL.close();
}

// ---- Tall full-content screenshots for key pages (desktop & mobile) ----
if (PHASE === "all" || PHASE === "tall") {
  const TALL = [
    { route: "/dashboard", key: "dashboard" },
    { route: "/users", key: "users" },
    { route: `/users/${FARMER_ID}`, key: "farmer-overview" },
    { route: "/companies", key: "companies" },
    { route: "/trees", key: "trees" },
  ];
  for (const [vpKey, width] of [["desktop", 1440], ["mobile", 390]]) {
    const ctx = await browser.newContext({ viewport: { width, height: 900 } });
    const page = await ctx.newPage();
    await attachWatchers(page);
    try { await login(page); } catch (e) { log(`tall login fail ${vpKey}: ${e}`); await ctx.close(); continue; }
    for (const r of TALL) {
      try {
        await page.goto(`${BASE}${r.route}`, { waitUntil: "domcontentloaded" });
        await settle(page, 65000);
        const contentH = await page.evaluate(() => {
          const main = document.querySelector("main");
          return main ? main.scrollHeight : document.documentElement.scrollHeight;
        });
        const h = Math.min(Math.max(contentH, 1000), 5000);
        await page.setViewportSize({ width, height: h });
        await page.waitForTimeout(800);
        const shot = `full-${r.key}-${vpKey}.png`;
        await page.screenshot({ path: path.join(OUT, shot) });
        summary.screenshots.push(shot);
        log(`tall ${vpKey} ${r.key} (h=${h})`);
        await page.setViewportSize({ width, height: 900 });
      } catch (e) {
        log(`tall fail ${vpKey} ${r.key}: ${String(e).slice(0, 150)}`);
      }
    }
    await ctx.close();
  }
}

// ---- Summary ----
summary.totalChecks = results.length + (summary.nav?.checks?.length || 0) + (summary.drawerDesktop?.checks?.length || 0) + (summary.treesTest?.checks?.length || 0) + (summary.dashTest?.checks?.length || 0) + (summary.mobileSidebar?.checks?.length || 0) + (summary.drawerMobile?.checks?.length || 0) + (summary.heatmapMobile?.checks?.length || 0) + (summary.overviewMobile?.checks?.length || 0) + (summary.authTest?.checks?.length || 0);
let passedCount = 0;
for (const r of results) if (r.ok) passedCount++;
for (const group of [summary.nav, summary.drawerDesktop, summary.treesTest, summary.dashTest, summary.mobileSidebar, summary.drawerMobile, summary.heatmapMobile, summary.overviewMobile, summary.authTest]) {
  if (group?.checks) for (const c of group.checks) if (c.ok) passedCount++;
}
summary.passedChecks = passedCount;
summary.results = results;

fs.writeFileSync(path.join(OUT, "step6_132_results.json"), JSON.stringify(summary, null, 2));
log(`DONE. scanChecks=${results.length} passedScan=${passedCount} total=${summary.totalChecks}`);
const failList = [];
for (const r of results) if (!r.ok) failList.push(`${r.viewport}/${r.route}: ${r.problems.join("; ")}`);
for (const group of [summary.nav, summary.drawerDesktop, summary.treesTest, summary.dashTest, summary.mobileSidebar, summary.drawerMobile, summary.heatmapMobile, summary.overviewMobile, summary.authTest]) {
  if (group?.checks) for (const c of group.checks) if (!c.ok) failList.push(`${group.name}/${c.name}: ${c.detail}`);
}
if (failList.length) {
  console.log("FAILURES:");
  for (const f of failList) console.log("  - " + f.slice(0, 300));
}
await browser.close();
