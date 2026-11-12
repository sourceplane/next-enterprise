// @vitest-environment node
import { afterEach, describe, expect, it, vi } from "vitest"

const saved = { ...process.env }

async function load(vars: Record<string, string | undefined>) {
  vi.resetModules()
  for (const [k, v] of Object.entries(vars)) {
    if (v === undefined) delete process.env[k]
    else process.env[k] = v
  }
  return import("env.mjs")
}

afterEach(() => {
  process.env = { ...saved }
})

describe("the environment schema (apps/web/env.mjs, t3-env)", () => {
  it("needs no variable at all: the build reads none as a secret", async () => {
    const { env } = await load({ ANALYZE: undefined, NEXT_PUBLIC_SITE_URL: undefined })
    expect(env.ANALYZE).toBe(false)
    expect(env.NEXT_PUBLIC_SITE_URL).toBeUndefined()
  })

  it("turns ANALYZE=true into the bundle analyzer switch", async () => {
    const { env } = await load({ ANALYZE: "true" })
    expect(env.ANALYZE).toBe(true)
  })

  it("takes the origin the Orun build sets, and the seam trims its trailing slash", async () => {
    await load({ NEXT_PUBLIC_SITE_URL: "https://acme-web-stage.acme.workers.dev/" })
    const { SITE_URL } = await import("app/site")
    expect(SITE_URL).toBe("https://acme-web-stage.acme.workers.dev")
  })

  it("refuses an origin that is not a URL", async () => {
    await expect(load({ NEXT_PUBLIC_SITE_URL: "not a url" })).rejects.toThrow(/Invalid environment variables/)
  })
})
