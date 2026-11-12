import * as fs from "node:fs"
import * as path from "node:path"

import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Web, { metadata } from "app/page"
import { SITE_NAME, SITE_URL, SOURCE_URL } from "app/site"
import { LP_GRID_ITEMS } from "lp-items"

const web = path.resolve(__dirname, "../../../apps/web")

describe("the landing page (apps/web/app/page.tsx)", () => {
  it("is headed and titled with the site's name", () => {
    render(<Web />)
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(SITE_NAME)
    expect(metadata.title).toBe(SITE_NAME)
  })

  it("links its buttons to the site's own repository, not the template's or Vercel", () => {
    render(<Web />)
    expect(screen.getByRole("link", { name: "Get started" })).toHaveAttribute("href", SOURCE_URL)
    expect(screen.getByRole("link", { name: "Deploy Now" })).toHaveAttribute("href", `${SOURCE_URL}#deploy-by-hand`)
    const source = fs.readFileSync(path.join(web, "app/page.tsx"), "utf8")
    expect(source).not.toMatch(/vercel\.com|vercel\.app|Blazity\/next-enterprise/)
  })

  it("shows every feature of the template's grid", () => {
    render(<Web />)
    expect(LP_GRID_ITEMS.length).toBeGreaterThan(10)
    for (const item of LP_GRID_ITEMS) {
      expect(screen.getByRole("heading", { level: 3, name: item.title })).toBeInTheDocument()
    }
  })

  it("puts its Open Graph card on the site's own origin, the image served from public/", () => {
    const og = metadata.openGraph as { url: string; images: { url: string }[] }
    expect(og.url).toBe(`${SITE_URL}/`)
    expect(og.images[0]?.url).toBe(`${SITE_URL}/project-logo.png`)
    expect(fs.existsSync(path.join(web, "public/project-logo.png"))).toBe(true)
  })
})
