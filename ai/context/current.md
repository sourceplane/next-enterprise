# next-enterprise — where this repository stands

The entry page for anyone (or any agent) picking this repository up. It is
this repository's own state and does not ship to a site built from it; the
two pages that do are [operations.md](operations.md) and
[deployment.md](deployment.md).

## What it is

Vercel's Next.js Enterprise Boilerplate (Blazity's `next-enterprise`) —
Next.js 15, Tailwind CSS 4, strict TypeScript, Radix UI and CVA components,
`t3-env`, Kubernetes-style health checks, Vitest, Playwright and Storybook —
on Cloudflare Workers + Static Assets (`@opennextjs/cloudflare`), packaged as
an Orun baseline: `orun new --blueprint repo-blueprint.yaml` builds a new site
in its own repository and takes it to live on stage and prod in one landing
(`01-product`), then records what went live (`03-docs`). One component, no
infra.

## Release

| | |
|---|---|
| Latest tag | `baseline-v1` — EB0–EB2: the epic doc set, the site on Workers, and the baseline (one landing, then the record) |
| Proven live | Not yet (risk EB-A). Every tier passes locally and in Baseline CI, including the template's Playwright suite in three browsers and Storybook's test runner against the built site |

## Where to read

| Question | Page |
|---|---|
| What shipped, and every departure from upstream | `specs/epics/next-enterprise/IMPLEMENTATION-STATUS.md` |
| Why it is built this way | [decisions.md](decisions.md), then `specs/epics/next-enterprise/design.md` |
| What could still go wrong | [open-risks.md](open-risks.md), then `specs/epics/next-enterprise/risks-and-open-questions.md` |
| How to instantiate it | `BOOTSTRAP.md`, `docs/phases/` |
| What each component is | `apps/web/docs/`, `tests/web/docs/` (generated; `python3 tooling/catalog/gen-component-docs.py`) |
| What a site's agent reads first | `.baseline/product/AGENTS.md` (ships as the site's `AGENTS.md`) |

## Next

1. Bootstrap one site from `baseline-v1` against a workspace and record its
   timings against the 7-minute estimate (closes EB-A).
2. Watch the Next.js 15.5 line: @opennextjs/cloudflare raises its floor with
   each release (1.20.16 wants ≥ 15.5.29). Move both together, or move the
   site to Next 16 when the adapter's 16 line is the one to be on (EB-C).
