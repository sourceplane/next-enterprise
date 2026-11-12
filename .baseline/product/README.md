# next-enterprise

Blazity's [Next.js Enterprise Boilerplate](https://github.com/Blazity/next-enterprise)
— Next.js 15 with Tailwind CSS 4, strict TypeScript, Radix UI and CVA
components, a typed environment (`t3-env`), Kubernetes-style health checks,
Vitest, Playwright and Storybook — on **Cloudflare Workers + Static Assets**
through [`@opennextjs/cloudflare`](https://opennext.js.org/cloudflare).

Working on it with a coding agent? [AGENTS.md](AGENTS.md) says what to read
first, how a change lands and what not to touch.

## Live deployment

<!-- 03-docs:begin -->
Not recorded yet. The bootstrap's last phase writes the live URLs, the
workspace and the secrets the site uses into
[ai/context/deployment.md](ai/context/deployment.md); how the site deploys
and how to operate it is in
[ai/context/operations.md](ai/context/operations.md).
<!-- 03-docs:end -->

## What is here

| Surface | Where |
|---|---|
| The site's name and source link | `apps/web/app/site.ts` |
| The landing page and its feature grid | `apps/web/app/page.tsx`, `apps/web/lp-items.tsx` |
| The health check (`/api/health`, and `/healthz`, `/api/healthz`, `/health`, `/ping`) | `apps/web/app/api/health/route.ts`, `apps/web/next.config.ts` |
| Components (CVA, Radix) and their stories | `apps/web/components`, `apps/web/.storybook` |
| Typed environment | `apps/web/env.mjs` |
| Tests | `apps/web/components/**/*.test.tsx` (Vitest), `apps/web/e2e` (Playwright), `tests/web` (Vitest) |
| Workers build and deploy contract | `apps/web/next.config.ts`, `open-next.config.ts`, `wrangler.jsonc`, `component.yaml` |

## Getting started

```bash
pnpm install
pnpm typecheck
pnpm lint             # next lint, then prettier --check
pnpm test             # Vitest: the app's and tests/web
pnpm build            # next build + opennextjs-cloudflare build → apps/web/.open-next
```

```bash
pnpm --filter @app/web dev              # http://localhost:3000
pnpm --filter @app/web preview          # wrangler dev over the built Worker
pnpm --filter @app/web storybook        # http://localhost:6006
pnpm --filter @app/web e2e:headless     # Playwright (needs `pnpm exec playwright install` once)
pnpm --filter @app/web analyze          # the bundle analyzer
```

Storybook's test runner checks every story in a browser: build the Storybook
(`pnpm --filter @app/web build-storybook`), serve `apps/web/storybook-static`
on port 6006, and run `pnpm --filter @app/web test-storybook`. Playwright runs
against `next dev` by default; set `PLAYWRIGHT_BASE_URL` to test a running
site instead (the Worker under `pnpm --filter @app/web preview`, say).

Make the site yours in `apps/web/app/page.tsx` (the landing page),
`apps/web/lp-items.tsx` (its feature grid) and `apps/web/app/site.ts` (its name
and the repository its buttons link to).

Two optional build-time variables (`apps/web/.env.example`), both declared in
`apps/web/env.mjs`:

| Variable | What it does |
|---|---|
| `NEXT_PUBLIC_SITE_URL` | The site's public origin, for the Open Graph card's absolute links. The deploy sets it per environment (see below). Defaults to `http://localhost:3000`. |
| `ANALYZE` | `true` wraps the build in the bundle analyzer (`pnpm analyze` sets it). |

## Observability

The Worker's logs are on (`observability` in `apps/web/wrangler.jsonc`): see
them on the Worker's Observability tab in Cloudflare's dashboard, or tail them
with `wrangler tail`. Traces, and exporting logs and traces to an
OpenTelemetry backend, are switched on there too. Workers needs no
`instrumentation.ts`.

## How it deploys

Merges to `main` converge through [Orun](https://github.com/sourceplane/orun):
`.github/workflows/ci.yml` plans the changed components and runs each lane
against the workspace in `intent.yaml`. The site deploys to `stage`, then to
`prod` once stage has converged on the same commit; `dev` only verifies. The
Worker is `next-enterprise-web-<env>` on your account's workers.dev
subdomain, and every deploy is smoke-tested over HTTP: the landing page, and
the health check at `/healthz`. A pull request runs the same pipeline's verify
lanes: the site built and dry-deployed for each environment, with nothing
deployed. They do not lint or run the tests, so run `pnpm typecheck`,
`pnpm lint` and `pnpm test` before you push. (A push to `main` builds, deploys
and smoke-tests.)

The pipeline holds one credential, GitHub's own `GITHUB_TOKEN`. The
Cloudflare token and account id are brokered per run from the workspace's
Cloudflare connection; nothing provider-shaped is stored in the repository
or in GitHub.

## Deploy by hand

Orunbase's **Deploy** button on a component, or **Run workflow** on the CI
workflow in GitHub's Actions tab (on `main`), runs `ci.yml` for the
environment and components you pick, and each one deploys exactly as a merge
would deploy it. Leave the component blank to redeploy every component in
that environment, with nothing changed: after rotating a secret, say. A
component with nothing to run in that environment (a test suite in `prod`) is
left out with a notice.

## Custom domain

The site answers on workers.dev from its first deploy. To serve it on your
own domain:

1. Add the domain to the Cloudflare account the site deploys into, and attach
   it to the Worker (dashboard → Workers & Pages →
   `next-enterprise-web-prod` → Settings → Domains & Routes → Add →
   Custom domain). Do the same for stage with a subdomain if you want one.
2. Set the environment's public origin in `intent.yaml`, so the Open Graph
   card's links use it (until then they use the workers.dev URL):

   ```yaml
   environments:
     prod:
       env:
         SITE_URL: https://next-enterprise.example.com
   ```

   The site was born with the reserved placeholder
   `next-enterprise.example.com` where its domain goes: that example,
   and `BASE_DOMAIN` under each environment (dev, stage and prod) in
   `intent.yaml`. Replace it with your domain in the same change.

3. Merge. The next deploy of `apps/web` builds with the new origin. (A change
   to `intent.yaml` alone deploys nothing — touch `apps/web` in the same pull
   request, or let the next change to the site carry it.)

## Licence

The template is MIT-licensed, © 2023 Blazity: `apps/web/LICENSE`.
