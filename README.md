# next-enterprise

Vercel's [Next.js Enterprise Boilerplate](https://github.com/Blazity/next-enterprise)
(Blazity's `next-enterprise`) — Next.js 15 with Tailwind CSS 4, strict
TypeScript with `ts-reset`, Radix UI and CVA components, `t3-env`,
Kubernetes-style health checks, Vitest with React Testing Library, Playwright
and Storybook — running on **Cloudflare Workers + Static Assets** through
[`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare), and packaged
as an **Orun baseline**: one command takes a new site from nothing to live on
stage and prod, in its own repository, under its own name.

The template's code is the code. What the port adds is the Workers build, the
monorepo wrapper, a test package, and the deploy contract; what it swaps is
`@vercel/otel` (for Workers Observability), the template's GitHub workflows
(for Orun's CI) and the hard-coded `vercel.app` origin (for an environment
variable). What the baseline adds is everything needed to make a copy of it
somebody else's — built the way [cirrus-baseline](https://github.com/sourceplane/cirrus-baseline)
is. See [`specs/epics/next-enterprise`](specs/epics/next-enterprise/README.md)
for the design, the milestones and the as-built status.

## Instantiating a site

```bash
git clone --depth 1 --branch <baseline-tag> https://github.com/sourceplane/next-enterprise
cd next-enterprise
orun new --blueprint repo-blueprint.yaml --out ~/sites/acme-app --run-hooks --resume \
  --set reponame=acme-app --set productname="Acme App" \
  --set githuborg=acme-inc --set subdomain=<workers-dev-subdomain>
```

Or, once the platform's registry lists it, from the Orun console (Baselines →
`next-enterprise` → Build). Two phases — `01-product` (the repository
created, then the whole site in one pull request, deployed to stage and prod
and smoke-tested) and `03-docs` (the live deployment recorded) — each landing
one pull request in the new repository.
**[BOOTSTRAP.md](BOOTSTRAP.md)** is the operator guide;
[docs/phases/](docs/phases/README.md) has a page per phase.

The new repository receives the **site only** — the app, its tests and
stories, its CI, its tooling, a README and an `AGENTS.md` of its own and its
operating contract — renamed throughout to the site's name, repository and
Cloudflare Worker. None of this repository's machinery ships.

| What makes it a baseline | Where |
|---|---|
| The console card (inputs, secrets, programme) | `blueprint.yaml` |
| The build document (modules, phases, hooks) | `repo-blueprint.yaml` |
| This tree's identity, and the bootstrap's task contracts | `.baseline/` |
| The rename engine | `tooling/rebrand/rebrand.mjs` |
| The bootstrap's helpers (deferrals, redeploy marker, work-tree strip) | `tooling/bootstrap/` |
| The deployment-record renderer | `hooks/render-deployment-docs.sh` |
| The site's README, agent page and context pack | `.baseline/product/README.md`, `.baseline/product/AGENTS.md`, `ai/context/` |
| The baseline's tests: contract, leak, offline bootstrap, end to end | `testing/`, `.github/workflows/baseline.yml` |
| Cutting a `baseline-vN` tag | `.github/workflows/tag.yml` |

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
| `baseline.yml` | the baseline's own tiers: contract tests, the blueprint read by the pinned orun, the leak gate, the offline bootstrap, the site built, dry-deployed and served, and the template's Playwright suite and Storybook test runner against it | no |
| `tag.yml` | cuts a `baseline-vN` tag (manual) | no |

The template is MIT-licensed (© 2023 Blazity); its licence ships as
`apps/web/LICENSE`.
