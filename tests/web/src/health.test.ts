// @vitest-environment node
import { describe, expect, it } from "vitest"

import { GET } from "app/api/health/route"

describe("the health check (apps/web/app/api/health/route.ts)", () => {
  it("answers 200 with {status: ok} as JSON", async () => {
    const res = await GET()
    expect(res.status).toBe(200)
    expect(res.headers.get("content-type")).toMatch(/^application\/json/)
    expect(await res.json()).toEqual({ status: "ok" })
  })
})
