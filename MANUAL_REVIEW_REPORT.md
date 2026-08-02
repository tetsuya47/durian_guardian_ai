# Manual Review Report — Release 1.3.2: Responsive UI Optimization

- **Release:** 1.3.2 — Responsive UI Optimization (Desktop / Laptop / Tablet / Mobile / Mobile-min breakpoints)
- **Date:** 2026-08-01
- **Reviewer:** Automation-assisted manual review (Playwright 1.62.1 + real Chromium 151.0.7922.34)
- **Result:** **RETURN TO STEP 4** — 1 functional/usability issue found at the 320px mobile breakpoint (Dashboard heatmap controls clipped and inaccessible)

---

## 1. Review Environment

| Item | Detail |
|---|---|
| Frontend | Vite dev server `http://localhost:5173` (React 19, TypeScript). Vite on 5174 also running (no proxy — `src/api/axios.ts` calls `http://127.0.0.1:8000` directly) |
| Backend | FastAPI + Motor already running on `http://127.0.0.1:8000` (Python PIDs 15692/16404) |
| Database | MongoDB `27017`, seeded Vietnam-localized data (61 users, 10 farms; farm dashboard target FARM001 Farm Ea Kar, 506 trees) |
| Browser | Playwright Chromium (headless), engine validated with minimal launch test |
| Viewports | Desktop 1440×900, Laptop 1366×768, Tablet 768×1024, Mobile 390×844, Mobile-min 320×640 |
| Login account | `bao@gmail.com` / `123456` (Admin; token role=Admin via `/api/v1/auth/login`) |

Review flow: Admin login against the live API → 14 routes scanned × 5 viewports for real-data rendering, console/network errors, and horizontal overflow → targeted interaction passes (navigation click-through, CRUD drawers, tree detail + pagination, dashboard KPIs/charts/heatmap, mobile sidebar, mobile edit drawer, heatmap scrolling, farmer overview content + back navigation, auth pages at 320px).

> Screenshots are saved under `frontend/manual_review/132/*.png`. DOM/geometry/accessibility metrics were used as the visual truth because eyeballing raw images was not possible in this environment; all screenshots were additionally validated as non-blank.

---

## 2. Desktop (1440×900)

- All 14 routes render real data with no horizontal page overflow (`docOverflow = 0` for every route).
- Multi-column layouts render correctly; main content scrolls vertically where intended.
- Sidebar click-through of all 9 primary nav entries: every page reports `over=0/0` (no main overflow, no out-of-viewport content).
- Dashboard at desktop: KPI cards render, heatmap renders and is horizontally scrollable, charts render (88 SVG nodes), 6198 card/DOM nodes — no overflow.
- Users edit drawer opens with overlay, no horizontal overflow (`bad=[]` at 1440px).
- Trees detail drawer opens, pagination to page 2 works, no overflow.
- Header/footer render on every page.

## 3. Laptop (1366×768)

- All 14 routes render real data with `docOverflow = 0`.
- Alerts, companies, dashboard, detection-results, disease-history, diseases, farm-dashboard, farmer-overview, farms, inspections, settings, trees, users, zones all confirmed at this width (screenshots `viewport-*-laptop.png`).
- Sidebar click-through at laptop width reports no main overflow for every nav route.

## 4. Tablet (768×1024)

- All 14 routes render real data with `docOverflow = 0`.
- Grid layouts collapse gracefully to the intended tablet arrangement; no clipped or off-viewport content (`bad=[]`).
- Farmer-overview deep-link path verified at tablet: renders all sections.

## 5. Mobile (390×844)

- All 14 routes render real data with `docOverflow = 0`.
- Single-column layout; edit drawer (users) opens without overflow on mobile.
- Heatmap is horizontally scrollable on mobile (scroll containers with overflow 4px / 81px measured — intended scrollable region).
- Mobile sidebar opens correctly: transform becomes identity matrix `matrix(1,0,0,1,0,0)`, backdrop present, no overflow. (The interaction harness reported a false negative here — see Issues Found, observation #3.)
- Farmer overview renders all sections at 390px (confirmed by full-text dump: profile, farm stats, inspection, AI detection, alerts, neighbor, 20-item timeline).

## 6. Mobile-min (320×640)

- **FAIL — Dashboard:** main content is wider than the viewport. `main.scrollWidth = 357` vs `clientWidth = 320` → **horizontal overflow ≈ 37px** (scan pass measured 46px). See Issues Found, issue #1.
- All other routes at 320px: `docOverflow = 0`, no JS errors.
- Auth pages (login / register) at 320px: no overflow, no console errors.
- Farmer overview at 320px: page overflow is 0 (address truncates cosmetically — observation #2).

---

## 7. Navigation

- Sidebar click-through (desktop/laptop): **Bảng điều khiển, Công ty, Trang trại, Khu vực, Cây, Người dùng, Kiểm tra, Lịch sử phát sinh bệnh, Cảnh báo** — all render with `over=0/0`.
- Routing: deep links to all 14 scan routes resolve after login; no 404s.
- Mobile sidebar toggle opens/closes with backdrop; default state closed (`matrix(1,0,0,1,-80,0)`), open state correct.

## 8. CRUD

- Users edit drawer (desktop + mobile): opens with overlay, no horizontal overflow, fields populated from live data.
- Trees detail drawer: opens, shows real tree data, no overflow.
- Pagination: trees table navigates to page 2, no overflow, no errors.
- No create/update/delete flows were modified in 1.3.2; existing flows render inside responsive containers without breakage.

## 9. Dashboard

- KPI cards, heatmap (scrollable on mobile), and charts all render with real data.
- Desktop/tablet/laptop: full layout fits, no overflow.
- **320px: heatmap filter/refresh controls are clipped and the refresh button is fully inaccessible** — see Issues Found, issue #1.

## 10. Tables

- Companies, farms, zones, trees, users, inspections, detection-results, disease-history, alerts, diseases: tables render rows from live API data at every viewport.
- No horizontal page overflow on any table route at any width (`docOverflow = 0`); responsive tables adapt (scroll containers where needed).
- Probe row/table assertions passed for all table routes (rows present, real values visible).

## 11. Timeline

- Farmer overview activity timeline renders 20 items, newest-first, across sources (AI detection, inspection, alert, neighbor contact), each with type label, formatted timestamp, and detail text (e.g., `Cây TREE03314 – Khỏe mạnh (độ tin cậy 90.5%)`, `Contact Shared … Trang trại Farm Ea Súp – contact_shared`).
- Timeline renders on desktop, tablet, and mobile (390px full-text verified; also rendered at 320px per scan).

## 12. Neighbor

- Neighbor contact block on farmer overview renders 4 summary cards (Đã gửi 1 / Đã nhận 4 / Đã chia sẻ liên hệ 1 / Chờ đồng ý 3) plus per-status chips (Chờ xử lý, Chờ đồng ý của người gửi, Chờ đồng ý của người nhận, Bị từ chối, Đã hủy) — all matching the live `/api/v1/admin/users/<id>/overview` response.
- NCR-derived timeline events (Contact Shared, Consent Required, Awaiting Consent, Request Received) render with correct status text.

## 13. Farmer Overview

- API `/api/v1/admin/users/6a6d9357b9a0ef641ae50967/overview` → **200** for farm owner USR0051 Nguyễn Văn An (Công ty Ea Kar, Farm Ea Kar).
- Rendered content (verified by full `main` text dump at 390px): profile (name, code USR0051, email, phone, address, company, farm, created 01/08/2026), farm stats (1 farm, 10 zones, 565 trees, 43.77 ha), inspection (950 total, latest 18/06/2026), AI detection (healthy 542 / diseased 408 / 72.2%), alerts (95 / 95 / 0 / 0), neighbor block, 20-item timeline.
- Back action (**Người dùng** button) navigates to `/users` — confirmed live (`/users/6a6d…` → `/users`).
- Loading state renders while request is in flight; content arrives ≈ 12–15 s (matches the pre-existing overview latency, see Performance).

## 14. Responsive

| Width | Horizontal page overflow | Result |
|---|---|---|
| 1440×900 (Desktop) | 0 on all 14 routes | PASS |
| 1366×768 (Laptop) | 0 on all 14 routes | PASS |
| 768×1024 (Tablet) | 0 on all 14 routes | PASS |
| 390×844 (Mobile) | 0 on all 14 routes | PASS |
| 320×640 (Mobile-min) | **Dashboard: main overflow 37–46px (heatmap controls clipped)** | **FAIL** |

- All other routes at 320px: no page overflow, no JS errors, no console errors.
- Login/register at 320px: no overflow, no console errors.

## 15. Performance

- Scan-route API calls (auth/me, users, companies, overview, alerts, etc.) responded in ~1–35 ms during this session; page navigations were responsive.
- Farmer overview endpoint retains the pre-existing latency from Release 1.3: **min ~5.1 s, max ~10.5 s, avg ~7.8 s (n=10)**, with the React StrictMode double-fetch on mount doubling it to ~10 s. This is a **known performance note, not a 1.3.2 regression** — no code change applied.
- No memory-growth or repeated-request anomalies observed across the 70-scan + interaction passes.

## 16. Issues Found

### Issue #1 — BLOCKING (functional + visual): Dashboard heatmap controls clipped at 320px

- **Where:** `src/pages/dashboard/components/HeatmapCard.tsx` — title row `div.flex.items-center.justify-between` (line 29) does not wrap; card has `overflow:hidden` (line 27).
- **Live geometry at 320×640 (Playwright measurement):**
  - `main`: `scrollWidth 357` vs `clientWidth 320` → main content overflows by **37–46 px**.
  - Title row (wrapper): x 37→283, width 246.
  - **Lọc theo khu vực** select (`aria-label`): x 219→327 — extends **7 px past the viewport** and **44 px past the card's right edge** → partially clipped, mostly unusable.
  - **Làm mới bản đồ nhiệt** button (`aria-label`): x 333→357 — **37 px past the viewport**, fully beyond the card right edge → **completely clipped and inaccessible**.
- **Impact:** at the 320px mobile breakpoint the heatmap refresh button cannot be seen or clicked, and the zone filter is partially cut off.
- **Not present at:** 390×844, 768×1024, 1366×768, 1440×900 — all controls fit and are fully interactive at those widths.
- **Per STEP 6 rules:** any functional or visual issue found during manual review → **RETURN TO STEP 4**. **No code fix applied during this review.**

### Observation #2 — Minor (cosmetic): farmer-overview address at 320px

- Profile address span (`Thôn 4, Xã Ea H'leo, Ea Kar, Đắk Lắk`) measures right-edge 340px > 320px viewport, but the page itself has `docOverflow = 0` and the address uses truncation — cosmetic ellipsis, no clipping of the page layout. Non-blocking.

### Observation #3 — Test-harness false negatives (re-verified as PASS, not app defects)

- **mobile sidebar:** harness asserted `transform === "none"`; the sidebar actually opens correctly (identity matrix + backdrop + `bad=0`). Re-verified → sidebar opens.
- **farmer-overview sections:** harness probed with case-sensitive title-case labels (`Liên hệ hàng xóm`, `Hoạt động gần đây`) while the UI renders UPPERCASE labels (`LIÊN HỆ HÀNG XÓM`, `HOẠT ĐỘNG GẦN ĐÂY`). Full-text dump confirms every section renders. Re-verified → PASS.
- **back-navigation:** harness matched the off-viewport sidebar link `a[href="/users"]`; the real back control is a `button` ("Người dùng", `onClick → navigate("/users")`). Clicked live → lands on `/users`. Re-verified → PASS.

---

## 17. Final Result

**RETURN TO STEP 4**

- **Total scan checks:** 70 (14 routes × 5 viewports) → **68 PASS / 2 flagged** (1 blocking + 1 cosmetic).
- **Interaction checks:** 22 executed → 19 PASS + 3 harness false negatives, all 3 re-verified as PASS against the live app.
- **Blocker:** Dashboard heatmap filter/refresh controls are clipped and the refresh button is fully inaccessible at the 320×640 mobile breakpoint (Issue #1). This is a functional/usability issue in a 1.3.2-responsive-touched component, so the release must return to STEP 4 to fix the 320px layout of the heatmap card before re-review.
- No code changes, no commits, no merges were performed during this manual review.
- Awaiting the user's decision to proceed to STEP 4 (and subsequent re-review).
