# Epics

Orun-style work programs. Each epic is a folder carrying `epic.yaml` (the
declaration the platform reads: slug, key prefix, milestones with exit
criteria and task keys) beside its doc set. The pull request that adds the
folder is the adoption; the merge creates the epic in the workspace.

| Epic | Cluster | Status | What it is |
|------|---------|--------|------------|
| [`next-enterprise/`](./next-enterprise/) | **EB** | In progress (EB1: the site on Workers) | Vercel's Next.js Enterprise Boilerplate (Blazity's next-enterprise), its page, health route, components, stories and tests kept, on Next.js 15.5 in one Cloudflare Worker with Static Assets via OpenNext — and an Orun baseline that instantiates it in one landing (EB2) |

As-built ≠ intent: what shipped lives in each epic's `IMPLEMENTATION-STATUS.md`.
