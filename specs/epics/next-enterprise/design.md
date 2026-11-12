# next-enterprise — design

## 1. The starter

Blazity/next-enterprise at `97c4f3e` (2026-05-18), Vercel's "Next.js
Enterprise Boilerplate" template, is one Next.js 15.5 app at the repository
root: a pre-rendered landing page (`app/page.tsx`) — the template's name as
title and heading, a two-button hero, and a grid of the twenty features it
ships (`lp-items.tsx`) — a health route (`app/api/health/route.ts`,
`{"status":"ok"}`) that `next.config.ts` rewrites from `/healthz`,
`/api/healthz`, `/health` and `/ping`, two CVA components (`Button` with a
Vitest test and a Storybook story, `Tooltip` on Radix), a `t3-env` schema
(`env.mjs`, one optional `ANALYZE` switch for `@next/bundle-analyzer`), and
`instrumentation.ts` registering `@vercel/otel`. Around it: ESLint (flat
config: typescript-eslint, import, storybook, Next's rules), Prettier with the
Tailwind plugin, Vitest with React Testing Library in jsdom, Playwright (one
title test, in chromium, firefox and webkit, against `pnpm dev`), Storybook
8.6 (`@storybook/nextjs`) and its test runner, patch-package, a coupling-graph
script, Renovate, semantic-release, a conventional-commits pre-commit hook,
all-contributors, and three GitHub workflows (lint, format, test, a Storybook
build with its test runner; Playwright; a bundle-size report).

## 2. How each Vercel piece maps

| Vercel | Here |
|---|---|
| A Next.js deployment (the page pre-rendered, the health route a function) | One Worker built by `@opennextjs/cloudflare` with Static Assets: the page from the static-assets incremental cache, the health route and its rewrites in the Worker |
| Next.js 15.5.18 | Next.js 15.5.29, the template's own line: the adapter's floor (§3.1) |
| `instrumentation.ts` + `@vercel/otel` | Workers Observability (`observability` in `wrangler.jsonc`) — the Worker's logs; traces and OTLP export in Cloudflare's settings (§3.3) |
| `next-enterprise.vercel.app` in the Open Graph card; the card's image hot-linked from Blazity's repository | `NEXT_PUBLIC_SITE_URL` (declared in `env.mjs`), set by the Orun build per environment; the image served from `public/` |
| "Get started" → Blazity's repository; "Deploy Now" → Vercel's clone flow | The site's own repository (`SOURCE_URL`), and its README's "Deploy by hand" |
| Deploy on push | `apps/web/component.yaml` (`cloudflare-workers-assets-turbo`): build and dry run on pull requests; build, deploy and a smoke over the page and `/healthz` on merge |
| The template's GitHub workflows | `ci.yml` (Orun's, the only workflow a site carries) and this repository's `baseline.yml`, which runs the template's Playwright suite and Storybook's test runner against the built Worker |
| semantic-release, the pre-commit hook | Not carried: Orun lands each change through its own pull request |

## 3. What the spike proved

In a scratch copy of the template (one package, as upstream ships it),
before any of the repository; served by `wrangler dev` and probed with real
requests. Notes: `~/orunbase/spikes/next-enterprise.md`.

### 3.1 Next.js 15.5 on OpenNext

@opennextjs/cloudflare refuses a Next.js its peer range excludes, at build:
1.20.11 wants `>=15.5.27 <16 || >=16.3.8`, 1.20.12–1.20.15 `>=15.5.28`, and
1.20.16, the latest, `>=15.5.29 <16 || >=16.4.5`. No 1.20.x accepts the
template's 15.5.18. Next 15.5.29 — the template's own line, its newest patch —
on 1.20.16 builds: `○ /`, `○ /_not-found`, `ƒ /api/health`. One snag: Next's
build type-checks every `.ts` file the tsconfig includes, and the template's
`moduleResolution: "node"` cannot resolve `@opennextjs/cloudflare/config` (an
`exports` subpath). The adapter config and the build output are excluded from
the tsconfig; the template's resolution stays.

### 3.2 Every route on workerd

`/` 200 with the template's title, heading and stylesheet; `/api/health`,
`/healthz`, `/api/healthz`, `/health` and `/ping` all 200
`application/json` `{"status":"ok"}`; a missing page and a missing
`/_next/static` chunk 404 — as plain requests and as browser navigations
(`Sec-Fetch-Mode: navigate`, which since 2025-04-01 can be answered by the
assets without the Worker; here the Worker answers both, because no
`not_found_handling` is set). The Worker is 897 KiB gzipped: Workers Free.

### 3.3 `@vercel/otel` on Workers

OpenNext keeps Next's instrumentation hook, and `register()` runs on workerd
(`NEXT_RUNTIME=nodejs`). With OpenTelemetry's console logger at debug and the
exporter pointed at a local OTLP collector, `@vercel/otel` starts
(`started next-app nodejs`, the trace exporter configured for the collector),
and the collector received nothing — four requests, sixteen seconds. Its
batch span processor exports from a timer after the response, which workerd
does not run for a finished request; with no endpoint set it targets
`localhost:4318`. Every request also logs `@vercel/otel: Vercel telemetry
extension not found`. Nothing ever failed — but it costs a span per request
and sends none, so it is dropped, and Workers Observability is the mapping.

### 3.4 `t3-env`

`env.mjs` is read by `next.config.ts` alone. The build needs no variable;
`ANALYZE` unset is `false`. The origin joins it as an optional client
variable, validated as a URL: unset, the card's links fall back to
`http://localhost:3000`; malformed, the build fails loudly.

### 3.5 The template's tests

`next lint` and Prettier's check are clean (Prettier once the build output is
ignored); the Vitest suite passes (3/3); the template's devDependency
`tsc@2.0.4` is a placeholder whose binary shadows TypeScript's own, and
TypeScript's compiler passes. Playwright, pointed at the Worker under
`wrangler dev`, passes its title test in chromium, firefox and webkit.
Storybook builds (seven seconds), and its test runner, against the built
Storybook served statically, passes the Button story's smoke test.

## 4. The repository

| Path | What |
|---|---|
| `apps/web` | the site (§1), built by OpenNext into `.open-next/` |
| `apps/web/app/site.ts` | the one rename seam: `SITE_NAME`, `SOURCE_URL`, and `SITE_URL` from `env.mjs` |
| `tests/web` | our vitest suite: the page, the seam, the health route, the environment schema, the stories, the config |
| `tooling/` | the workspace's TypeScript and ESLint configuration (for `tests/web`; the app keeps its own), the wrangler renderer, the component-docs generator |
| `intent.yaml`, `.github/workflows/ci.yml` | the deploy contract: stage and prod on merge, dev verify-only |

## 5. The baseline

portfolio-starter-kit's: one landing (`01-product`) places, brands and lands
the whole site and waits for the convergence to deploy it to stage and prod;
`03-docs` probes both and records what went live. The rename has one seam
(`SITE_NAME` in `app/site.ts`), the worker names, the build origin and the
source link — and one exception: `next-enterprise` is the template's own
name, so Blazity's repository and its Vercel demo are protected from the slug
rule, as postgres-kysely protects its upstream. The end-to-end tier replays
the stage lane in the tree orun stages, serves the built Worker, smoke-tests
it with the component's own command, reads every route, and then runs the
template's own browser tests against it.

## 6. Alternatives rejected

- **Next.js 16.** The adapter's 16 line wants 16.4.5 or later; moving the
  template a major version is a larger change than the port needs, and the
  15.5 line is supported.
- **OpenNext 1.20.11 with Next 15.5.27.** The adapter the earlier Next.js
  baselines lock. 1.20.16 is the current release and its 15.5 floor is the
  newest 15.5 patch.
- **Keeping `@vercel/otel`.** It runs and exports nothing (§3.3).
- **A no-op `instrumentation.ts`.** A file that does nothing invites an owner
  to believe tracing is set up.
- **Running Playwright against `next dev` in the e2e tier.** It would not
  prove the Worker.
- **Moving the template's tests into `tests/web`.** They stay beside the
  components they test, as the template keeps them.
- **Changing the template's `moduleResolution`.** Excluding the adapter
  config is the smaller change.
