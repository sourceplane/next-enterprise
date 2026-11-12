# apps/web — the site

Blazity's [Next.js Enterprise Boilerplate](https://github.com/Blazity/next-enterprise)
(MIT, `LICENSE` beside this file), running on Cloudflare Workers + Static
Assets:

- Next.js 15 (App Router), Tailwind CSS 4, strict TypeScript with `ts-reset`
  and absolute imports
- Components built with CVA and Radix UI (`components/`), each with its stories
  (`.storybook/`)
- A typed environment with `t3-env` (`env.mjs`)
- A health check at `/api/health`, also answering `/healthz`, `/api/healthz`,
  `/health` and `/ping`
- Vitest and React Testing Library (`components/**/*.test.tsx`), Playwright
  (`e2e/`), Storybook and its test runner
- ESLint, Prettier, the bundle analyzer, patch-package and the coupling graph

The site's name and the repository its buttons link to are in `app/site.ts`.

```bash
pnpm dev              # next dev on http://localhost:3000
pnpm build            # next build + opennextjs-cloudflare build → .open-next/
pnpm preview          # wrangler dev over the built Worker
pnpm test             # Vitest
pnpm e2e:headless     # Playwright; set PLAYWRIGHT_BASE_URL to test a running site instead of `pnpm dev`
pnpm storybook        # Storybook on http://localhost:6006
pnpm test-storybook   # Storybook's test runner, against a running Storybook
pnpm analyze          # the bundle analyzer
```

How it is deployed — per environment, on merge to `main` — is the
repository's README and `component.yaml` beside this file.
