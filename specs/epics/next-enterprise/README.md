# next-enterprise — Vercel's Next.js Enterprise Boilerplate on Cloudflare Workers

**The template is Blazity's enterprise Next.js starter: one pre-rendered
landing page listing its features, a health route answering on five
Kubernetes-style addresses, CVA and Radix components with Storybook stories,
a typed environment, and the tooling around them — Vitest, Playwright,
Storybook's test runner, ESLint, Prettier, the bundle analyzer. Vercel runs it
as a Next.js deployment with `@vercel/otel` tracing it. The port keeps the
app and every test as they are, on the template's own Next.js 15.5 line:
`@opennextjs/cloudflare` builds it into one Cloudflare Worker with Static
Assets, Workers Observability stands in for `@vercel/otel` (which starts on
Workers and exports nothing), the template's Playwright suite and Storybook's
test runner run against the built Worker, and Orun deploys it to stage and
prod on every merge — and the baseline makes a copy of it somebody else's
site in one landing.**

| | |
|---|---|
| Status | In progress — EB0 on main |
| Upstream | [Blazity/next-enterprise](https://github.com/Blazity/next-enterprise) (MIT), at `97c4f3e` (2026-05-18, "chore: bump next 15.5.18") — Vercel's [Next.js Enterprise Boilerplate](https://vercel.com/templates/next.js/nextjs-enterprise-boilerplate) template |
| Reference | [portfolio-starter-kit](https://github.com/sourceplane/portfolio-starter-kit) — Next.js on OpenNext with no infrastructure, its scaffolding, tests and bootstrap |
| Key | `EB` |

## Read in this order

1. [design.md](design.md) — the starter, how each Vercel piece maps to
   Cloudflare, what the spike proved, the repository and the build, and the
   alternatives rejected.
2. [implementation-plan.md](implementation-plan.md) — the milestones and
   what each one lands.
3. [risks-and-open-questions.md](risks-and-open-questions.md) — what is not
   proven, and what was accepted.
4. [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md) — what shipped, and
   every departure from the upstream starter.

## Milestones

| Milestone | What it lands | Task |
|---|---|---|
| EB0 — the spec | the repository, its intent, CI, tooling and spec index; this doc set | EB-1 |
| EB1 — the site on Workers | the template in `apps/web` on Next.js 15.5 and OpenNext, its tests and stories, the README | EB-2 |
| EB2 — a baseline | the console card, the build document, the context pack and the baseline's tests | EB-3 |
