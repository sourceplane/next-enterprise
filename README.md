# next-enterprise

Vercel's [Next.js Enterprise Boilerplate](https://github.com/Blazity/next-enterprise)
(Blazity's `next-enterprise`) — Next.js 15 with Tailwind CSS 4, strict
TypeScript with `ts-reset`, Radix UI and CVA components, `t3-env`,
Kubernetes-style health checks, Vitest with React Testing Library, Playwright
and Storybook — running on **Cloudflare Workers + Static Assets** through
[`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare), deployed by
[Orun](https://github.com/sourceplane/orun) to stage and prod on every merge.
Packaging it as an Orun baseline is the next milestone (EB2).

The template's code is the code. What the port adds is the Workers build, the
monorepo wrapper, a test package, and the deploy contract; what it swaps is
`@vercel/otel` (for Workers Observability), the template's GitHub workflows
(for Orun's CI) and the hard-coded `vercel.app` origin (for an environment
variable). See [`specs/epics/next-enterprise`](specs/epics/next-enterprise/README.md)
for the design, the milestones and the as-built status.

## What is here (the site)

| Surface | Where |
|---|---|
| The site's name and source link | `apps/web/app/site.ts` |
| The landing page and its feature grid | `apps/web/app/page.tsx`, `apps/web/lp-items.tsx` |
| The health check (`/api/health`, and `/healthz`, `/api/healthz`, `/health`, `/ping`) | `apps/web/app/api/health/route.ts`, `apps/web/next.config.ts` |
| Components (CVA, Radix) and their stories | `apps/web/components`, `apps/web/.storybook` |
| Typed environment (`t3-env`) | `apps/web/env.mjs` |
| The template's tests: Vitest, Playwright | `apps/web/components/**/*.test.tsx`, `apps/web/e2e` |
| Workers build and deploy contract | `apps/web/next.config.ts`, `open-next.config.ts`, `wrangler.jsonc`, `component.yaml` |
| Our tests (vitest) | `tests/web` |

## Getting started

```bash
pnpm install
pnpm typecheck
pnpm lint             # next lint, then prettier --check
pnpm test             # the template's Vitest suite and tests/web
pnpm build            # next build + opennextjs-cloudflare build → apps/web/.open-next
```

```bash
pnpm --filter @app/web dev              # http://localhost:3000
pnpm --filter @app/web preview          # wrangler dev over the built Worker
pnpm --filter @app/web storybook        # http://localhost:6006
pnpm --filter @app/web build-storybook  # → apps/web/storybook-static
pnpm --filter @app/web e2e:headless     # Playwright (starts `pnpm dev` itself)
pnpm --filter @app/web analyze          # the bundle analyzer
```

Two optional build-time variables (`apps/web/.env.example`), both declared in
`apps/web/env.mjs`:

| Variable | What it does |
|---|---|
| `NEXT_PUBLIC_SITE_URL` | The site's public origin, for the Open Graph card's absolute links. The Orun build sets it to the environment's `SITE_URL` (intent.yaml), else its Worker URL. Defaults to `http://localhost:3000`. |
| `ANALYZE` | `true` wraps the build in `@next/bundle-analyzer` (`pnpm analyze` sets it). |

## How it maps to Vercel

| Vercel | Here |
|---|---|
| Next.js hosting (SSG + route handlers) | One Cloudflare Worker (`.open-next/worker.js`) + Static Assets; the pre-rendered page comes from the static-assets cache, the health route runs in the Worker |
| `instrumentation.ts` + `@vercel/otel` | Workers Observability (`observability` in `wrangler.jsonc`): the Worker's logs, and traces and OTLP export from Cloudflare's settings. On Workers `@vercel/otel` started but exported nothing |
| The template's GitHub workflows (check, Playwright, bundle analysis) | Orun's `ci.yml`, which builds and dry-deploys the site on every pull request; the template's Vitest suite runs with `pnpm test`, Playwright and Storybook's test runner by hand, and all three in this repository's `baseline.yml` |
| semantic-release, the conventional-commits pre-commit hook | Not carried: Orun lands every change through its own pull requests |
| Hard-coded `next-enterprise.vercel.app` origin | `NEXT_PUBLIC_SITE_URL` |
| Deploy on push | Orun deploys `<repo>-web-{stage,prod}` on merge to `main` (`apps/web/component.yaml`) |
| "Deploy Now" (clone the template to Vercel) | `orun new --blueprint repo-blueprint.yaml` — a new repository, branded, deployed |

## CI

| Workflow | What it runs | Ships to a site |
|---|---|---|
| `ci.yml` | the Orun pipeline, and the only workflow a site carries: `orun plan --changed`, then one job per lane. A pull request runs the verify lanes (the site built and dry-deployed per environment; the tests' `quick-check` lane installs and checks the package, it does not run them), except the bootstrap's own landings (`orun/BASE-*`), where `plan` alone is the check; a merge deploys stage → prod. It plans nothing while `intent.yaml` names the placeholder workspace `ws_CHANGE_ME`, as this repository does. A manual run (Orunbase's Deploy button, or Run workflow on `main`) plans the environment and components it names under the push-to-main trigger, so they deploy as a merge deploys them | yes |

The template is MIT-licensed (© 2023 Blazity); its licence ships as
`apps/web/LICENSE`.
