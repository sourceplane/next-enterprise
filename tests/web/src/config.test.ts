// @vitest-environment node
import * as fs from "node:fs"
import * as path from "node:path"

import { describe, expect, it } from "vitest"

const root = path.resolve(__dirname, "../../..")
const web = path.join(root, "apps/web")
const read = (rel: string) => fs.readFileSync(path.join(web, rel), "utf8")

describe("the Next.js config (apps/web/next.config.ts)", () => {
  it("keeps the template's health aliases and builds standalone from the workspace root", async () => {
    const { default: config } = await import("../../../apps/web/next.config")
    expect(config.output).toBe("standalone")
    expect(path.resolve(config.outputFileTracingRoot!)).toBe(root)
    expect(config.reactStrictMode).toBe(true)
    const rewrites = await (config.rewrites as () => Promise<{ source: string; destination: string }[]>)()
    expect(rewrites).toEqual(
      ["/healthz", "/api/healthz", "/health", "/ping"].map((source) => ({ source, destination: "/api/health" }))
    )
  })
})

describe("the Worker (apps/web/wrangler.jsonc, open-next.config.ts)", () => {
  const wrangler = JSON.parse(read("wrangler.jsonc")) as {
    main: string
    compatibility_flags: string[]
    assets: { directory: string; binding: string }
    observability: { enabled: boolean }
  }

  it("runs OpenNext's Worker with its static assets, on Node.js compatibility", () => {
    expect(wrangler.main).toBe(".open-next/worker.js")
    expect(wrangler.assets).toEqual({ directory: ".open-next/assets", binding: "ASSETS" })
    expect(wrangler.compatibility_flags).toContain("nodejs_compat")
  })

  it("keeps Workers Observability on, in place of @vercel/otel", () => {
    expect(wrangler.observability.enabled).toBe(true)
    expect(fs.existsSync(path.join(web, "instrumentation.ts"))).toBe(false)
  })

  it("serves the pre-rendered page from the static-assets incremental cache", () => {
    expect(read("open-next.config.ts")).toMatch(/incrementalCache: staticAssetsIncrementalCache/)
  })
})

describe("what the port leaves behind (apps/web/package.json)", () => {
  const pkg = JSON.parse(read("package.json")) as {
    dependencies: Record<string, string>
    devDependencies: Record<string, string>
  }
  const all = { ...pkg.dependencies, ...pkg.devDependencies }

  it("ships no Vercel telemetry, release or contributor tooling, and no placeholder tsc", () => {
    for (const name of Object.keys(all)) {
      expect(name).not.toMatch(/^(@vercel\/otel|@opentelemetry\/|semantic-release|@semantic-release\/|all-contributors-cli|tsc)$/)
      expect(name).not.toMatch(/^@semantic-release\//)
      expect(name).not.toMatch(/^@opentelemetry\//)
    }
  })

  it("keeps the template's Next.js line on the adapter that supports it", () => {
    expect(pkg.dependencies.next).toMatch(/^15\.5\.\d+$/)
    expect(pkg.dependencies["@opennextjs/cloudflare"]).toMatch(/^1\.20\.\d+$/)
  })
})
