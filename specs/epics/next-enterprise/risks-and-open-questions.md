# next-enterprise — risks and open questions

## EB-A — No live bootstrap yet (OPEN)

Everything short of the platform is proven on every pull request: the card
against the build, the blueprint read by the pinned orun, the leak gate, the
offline bootstrap with the blueprint's own hooks, the site's own plan for the
01-product merge, and the produced site built, dry-deployed, served,
smoke-tested and read route by route in the job tree orun stages, with the
template's browser tests run against it. Not proven: the repository created
and linked, the token minted, a real `wrangler deploy`, the smoke against
workers.dev.

## EB-B — The page is pre-rendered (ACCEPTED)

The landing page is static (`○ /`): it is built once per environment with that
environment's origin and served from the static-assets cache. A page that
reads request data (cookies, headers) becomes dynamic and renders in the
Worker; nothing in the template does.

## EB-C — The adapter's Next.js floor moves (WATCH)

Each @opennextjs/cloudflare release has raised the 15.5 floor (15.5.27, then
15.5.28, then 15.5.29). Both are pinned exactly, so a fresh lockfile cannot
pair a newer adapter with an older Next. Moving either means moving both,
checked by the e2e tier's build.

## EB-D — `@vercel/otel` is dropped (ACCEPTED)

It starts on workerd and exports nothing (design §3.3). The Worker's logs are
Workers Observability's; traces and OTLP export to an OpenTelemetry backend
are switched on in Cloudflare's dashboard. An owner who needs spans from code
uses Workers' own tracing, not a Node SDK.

## EB-E — The lanes install every dev tool (WATCH)

The template's dev dependencies — Storybook, Playwright, the Storybook test
runner's Jest, ESLint's plugins — are about 1.2 GB of `node_modules`, and
every deploy lane installs the workspace. It costs install time, not Worker
size (897 KiB gzipped).

## EB-F — Browser tests run by hand in a site (ACCEPTED)

A site's `ci.yml` builds and dry-deploys on pull requests; its tests' lane is
`quick-check` (install and check), as on every Next.js baseline. The
template's Vitest suite runs with `pnpm test`; its Playwright suite and
Storybook's test runner need browsers and run by hand (the README says how),
and in this repository's Baseline CI against the built Worker.

## EB-G — Playwright's installer on Node 26 (RESOLVED for CI)

On this repository's development machine, Playwright 1.58.2's `playwright
install` hangs extracting its archives under Node 26. CI runs Node 22 on
Linux with `--with-deps`, where it does not. Locally the browsers were
unpacked from the same archives by hand.

## EB-H — `next lint` is deprecated (WATCH)

Next.js 15.5 prints a deprecation notice for `next lint` (removed in 16). The
template's script is kept; moving to the ESLint CLI comes with Next 16.
