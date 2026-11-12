import * as fs from "node:fs"
import * as path from "node:path"

import { describe, expect, it, vi } from "vitest"

const seam = path.resolve(__dirname, "../../../apps/web/app/site.ts")

describe("the site's identity (apps/web/app/site.ts)", () => {
  it("names the site and links its source repository", async () => {
    const { SITE_NAME, SOURCE_URL } = await import("app/site")
    expect(SITE_NAME.trim()).not.toBe("")
    expect(SOURCE_URL).toMatch(/^https:\/\/github\.com\/[A-Za-z0-9-]+\/[A-Za-z0-9._-]+$/)
  })

  it("keeps the two names literal and on one line each, as the rename expects", () => {
    const text = fs.readFileSync(seam, "utf8")
    expect(text).toMatch(/^export const SITE_NAME = "[^"\n]+"$/m)
    expect(text).toMatch(/^export const SOURCE_URL = "https:\/\/github\.com\/[^"\n]+"$/m)
  })

  it("falls back to localhost for the origin when the build sets none", async () => {
    vi.resetModules()
    vi.stubEnv("NEXT_PUBLIC_SITE_URL", undefined)
    const { SITE_URL } = await import("app/site")
    vi.unstubAllEnvs()
    expect(SITE_URL).toBe("http://localhost:3000")
  })
})
