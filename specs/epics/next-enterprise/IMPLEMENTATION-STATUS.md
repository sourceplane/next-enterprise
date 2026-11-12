# next-enterprise — implementation status

| Milestone | State | Landed |
|---|---|---|
| EB0 — the spec | ✅ | EB-1 |
| EB1 — the site on Workers | ✅ | EB-2 |
| EB2 — a baseline | ✅ | EB-3, tagged `baseline-v1` |

## Departures from the upstream template

Everything not listed here is the template as it is upstream at `97c4f3e`:
its page, its feature grid, its health route and rewrites, its components,
stories and tests, its ESLint, Prettier, Vitest, Playwright and Storybook
configuration.

| # | What | Why |
|---|---|---|
| 1 | The app lives in `apps/web` of a pnpm workspace (`@app/web`); upstream's root `package.json` scripts and dependencies move there; its `README.md`, `.all-contributorsrc` and `graph.svg` (a generated image) are not carried; `assets/` (the README's logos) neither | The workspace's shape (portfolio-starter-kit's); the site's README is the product's |
| 2 | `next` 15.5.18 → **15.5.29**, pinned exactly; `@opennextjs/cloudflare` **1.20.16** and `wrangler` added | Every @opennextjs/cloudflare 1.20.x refuses Next 15.5 below 15.5.27, and 1.20.16 below 15.5.29 (design §3.1, risk EB-C); the template's own 15.5 line is kept |
| 3 | `instrumentation.ts`, `@vercel/otel` and the five `@opentelemetry/*` dev pins (its peers) are removed; `wrangler.jsonc` keeps `observability` on | On Workers `register()` runs and OTel starts, but no span is ever exported, and every request logs a Vercel warning (design §3.3, risk EB-D) |
| 4 | `semantic-release`, the six `@semantic-release/*` packages and `.releaserc`; `.pre-commit-config.yaml` and `git-conventional-commits.yaml`; `all-contributors-cli`; `report-bundle-size.js` with `gzip-size` and `mkdirp`; `vercel.json`; `.github/nodejs.version` and the three workflows (`check.yml`, `playwright.yml`, `nextjs_bundle_analysis.yml`) are not carried | `ci.yml` is the only workflow that runs on a push to `main`, and Orun lands every change through its own pull requests; each tool existed only for a dropped workflow or for Vercel |
| 5 | The devDependency `tsc@2.0.4` is removed | It is a placeholder package whose `tsc` binary shadows TypeScript's own and prints "This is not the tsc command you are looking for"; `typecheck` (`tsc --noEmit`) needs TypeScript's |
| 6 | `renovate.json` moves to `.github/renovate.json` | A site carries the whole of `.github`; Renovate reads its config there |
| 7 | `next.config.ts`: `output: "standalone"`, `outputFileTracingRoot` (the workspace root) and `allowedDevOrigins` (orun.work's live Preview) added | OpenNext bundles the standalone output; the preview loads `next dev` from another host |
| 8 | `open-next.config.ts` and `wrangler.jsonc` added (static-assets incremental cache; `nodejs_compat`, `observability`) | The Workers build replaces Vercel's |
| 9 | `tsconfig.json`: `open-next.config.ts`, `.open-next`, `.wrangler` and `storybook-static` join `exclude` | The template's `moduleResolution: "node"` cannot resolve `@opennextjs/cloudflare/config`, and Next's build type-checked it (design §3.1) |
| 10 | `app/site.ts` added (`SITE_NAME = "Next.js Enterprise Boilerplate"`, `SOURCE_URL`, `SITE_URL`); the page's `title` and heading read `SITE_NAME`; "Get started" links `SOURCE_URL` (upstream: Blazity's repository) and "Deploy Now" `SOURCE_URL#deploy-by-hand` (upstream: Vercel's clone flow) | One rename seam; the buttons point at the site's own repository and its deploy, not the template's or Vercel's |
| 11 | The Open Graph card: `url` is the site's origin (upstream `https://next-enterprise.vercel.app/`) and the image is `/project-logo.png`, served from `public/` (upstream hot-links `.github/assets/project-logo.png` from Blazity's `main`) | The card describes the site, and nothing loads from another repository's branch |
| 12 | `env.mjs`: an optional client variable `NEXT_PUBLIC_SITE_URL` (a URL) beside `ANALYZE` | The origin is typed and validated where the template declares its environment |
| 13 | `package.json` scripts: `build` is Next's then OpenNext's; `preview` and `typecheck` added; `lint` runs `next lint` then `prettier --check` (upstream's CI ran both); `test` is `vitest run` (upstream `vitest`, which watches outside CI); `analyze` is `ANALYZE=true next build` (upstream ran its `build`, then `next build` alone) | The Workers build; the template's CI checks, in the commands every lane and landing runs |
| 14 | `playwright.config.ts`: `baseURL` from `PLAYWRIGHT_BASE_URL` when set, and `webServer` (`pnpm dev`) only when it is not; `e2e/example.spec.ts` matches the title against `SITE_NAME` (upstream: the literal `/Next.js Enterprise Boilerplate/`) | The suite runs against the built Worker in the baseline's e2e tier; a site renames its title |
| 15 | `eslint.config.mjs` ignores `.open-next/`, `.wrangler/` and `storybook-static/`; `.prettierignore` the same and Playwright's and Vitest's output | Build output is not source |
| 16 | `next-env.d.ts` is not committed (upstream commits it) | Next 15.5.29's build appends a reference to `.next/types/routes.d.ts`, which a fresh tree's typecheck cannot find; the workspace ignores the file, as portfolio-starter-kit does |
| 17 | `pnpm.overrides` (`tmp@<=0.2.3`) moves to `pnpm-workspace.yaml`; `onlyBuiltDependencies` lists esbuild, workerd and sharp; `packageManager` is pnpm 10.12.1 (upstream 10.0.0) | The workspace's install; pnpm 10 runs no dependency's build script it is not told to |
| 18 | `tests/web` added (vitest): the page (title, heading, buttons, feature grid, Open Graph card), the name seam, the health route, the environment schema, the Button stories as portable stories, the Next.js and Worker config, and what the port leaves behind | Ours, beside the template's own suite, which is kept as it is |
| 19 | `apps/web/LICENSE` is upstream's MIT licence, unchanged | The template ships under it; the product carries it |
