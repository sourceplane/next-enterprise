import { expect, test } from "@playwright/test"

import { SITE_NAME } from "../app/site"

// The page's title is the site's name, which a product built from this
// baseline renames: match it literally, whatever characters it carries.
const literally = (value: string) => new RegExp(value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))

test("has title", async ({ page }) => {
  await page.goto("./")

  await expect(page).toHaveTitle(literally(SITE_NAME))
})
