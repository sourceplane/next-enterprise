# next-enterprise — implementation plan

Three milestones, one task each, each landed as one pull request.

## EB0 — the spec (EB-1)

The repository is born with portfolio-starter-kit's frame — `intent.yaml`
(dev verify-only, stage, prod after stage; the placeholder workspace
`ws_CHANGE_ME`, so CI plans nothing until it is linked), `ci.yml` byte for
byte turso-starter's (as portfolio-starter-kit carries it), the shared
TypeScript and ESLint configuration, the wrangler renderer, the pnpm workspace
and turbo pipeline, and the spec index — and this doc set and the three task
contracts land on it.

## EB1 — the site on Workers (EB-2)

- `apps/web` is upstream's tree: `app/` (layout, page, health route),
  `components/` (Button with its test and story, Tooltip), `lp-items.tsx`,
  `styles/`, `env.mjs`, `e2e/`, `.storybook/`, and its ESLint, Prettier,
  PostCSS, Vitest and Playwright configuration, with its `LICENSE`.
- Next.js 15.5.29 on @opennextjs/cloudflare 1.20.16, `output: "standalone"`,
  the static-assets incremental cache, `wrangler.jsonc` with `nodejs_compat`
  and Workers Observability; `instrumentation.ts` and `@vercel/otel` removed
  (design §3.3).
- One seam, `app/site.ts`: the page's title and heading read `SITE_NAME`, its
  buttons `SOURCE_URL`, its Open Graph card `SITE_URL` (`NEXT_PUBLIC_SITE_URL`
  in `env.mjs`).
- `component.yaml` (`cloudflare-workers-assets-turbo`): the build with the
  environment's origin, a smoke over the page's feature grid and `/healthz`.
- `tests/web` (vitest) beside the template's own suite; Playwright's config
  takes `PLAYWRIGHT_BASE_URL`.
- The README: run, test, deploy; how each Vercel piece maps.

Done when typecheck, lint (with Prettier), test and build are green, and
`wrangler dev` answers every route; the template's Playwright suite and
Storybook's test runner pass against it.

## EB2 — a baseline (EB-3)

portfolio-starter-kit's machinery on this tree: the card, the build document
(one landing, `01-product`, then the record, `03-docs`), `.baseline/`
(identity, the product's README and agent page, task contracts), the rename
engine (the `SITE_NAME` seam, and Blazity's repository and demo protected
from the slug rule), the bootstrap helpers, the deployment-record renderer
(probing `/` and `/healthz`, and its render test with no PyYAML), the phase
pages, the context pack, and the baseline's tests — with the end-to-end tier
replaying the stage lane in a staged job tree, reading every route from the
staged Worker under `wrangler dev`, as plain requests and as browser
navigations, then running the template's Playwright suite in three browsers
against it and Storybook's test runner against the built Storybook. Done when
every Baseline CI tier is green; tagged `baseline-v1`.
