# next-enterprise — decisions

The choices that shape this repository, one line each, with where the full
reasoning lives. Superseded decisions stay listed, marked, so the history
reads in order.

| # | Decision | Why | Source |
|---|---|---|---|
| 1 | OpenNext on Workers + Static Assets (`cloudflare-workers-assets-turbo`), the static-assets incremental cache + `populateCache` | The page is pre-rendered at build; the health route is the only request-time code | design.md, risk EB-B |
| 2 | Next.js stays on the template's 15.5 line, at 15.5.29, with @opennextjs/cloudflare 1.20.16, both pinned exactly | The adapter refuses any 15.5 below 15.5.27 (1.20.16: 15.5.29); 16 is a larger move than the port needs | spike notes, risk EB-C |
| 3 | `instrumentation.ts` and `@vercel/otel` are dropped; Workers Observability is the mapping | On workerd `register()` runs and OTel starts, but its batch exporter never sends (0 spans to a local collector) and it logs a Vercel warning per request | design.md, risk EB-D |
| 4 | The template's tsconfig keeps `moduleResolution: "node"`; the adapter config and build output are excluded from it | `node` resolution cannot read `@opennextjs/cloudflare/config`'s exports; the template's resolution is not ours to change | IMPLEMENTATION-STATUS |
| 5 | The origin is `NEXT_PUBLIC_SITE_URL`, declared in `env.mjs` (t3-env), baked in by the Orun build: the environment's `SITE_URL`, else its workers.dev URL | The template hard-coded `next-enterprise.vercel.app` for its Open Graph card | IMPLEMENTATION-STATUS |
| 6 | The template's three GitHub workflows, semantic-release, the pre-commit hook, all-contributors and the bundle-size report are not carried; Renovate's config is (`.github/renovate.json`) | `ci.yml` is the only workflow on a push to `main`; Orun lands every change through its own pull requests | IMPLEMENTATION-STATUS |
| 7 | The template's Playwright suite runs against the built Worker (`PLAYWRIGHT_BASE_URL`) in all three browsers, and Storybook's test runner against the built Storybook, in the baseline's end-to-end tier | Port every test, drop none; a browser test against `next dev` would not prove the Worker | `testing/e2e.test.sh` |
| 8 | The name seam is `apps/web/app/site.ts` (`SITE_NAME`, `SOURCE_URL`); the page's title, heading and buttons read it | One literal line each, as the rebrand expects | `tooling/rebrand/rebrand.mjs` |
| 9 | `next-enterprise` is both this baseline's slug and the template's name: Blazity's repository and demo are protected from the rename | A product's README must still credit the right upstream | `tooling/rebrand/rebrand.mjs` (UPSTREAM) |
| 10 | One landing (`01-product`) then the record (`03-docs`), each bootstrap landing checked by `plan` alone | portfolio-starter-kit's shape (cirrus-baseline since baseline-v22) | design.md |
| 11 | stack-tectonic 0.19.0 | Turbopack refuses 0.20.0's lane-shared install (portfolio-starter-kit's first live bootstrap) | `intent.yaml` |
| 12 | No domain phase; a custom domain is the owner's step (`SITE_URL`) | `workers-deploy` has no zone scope | README, "Custom domain" |
