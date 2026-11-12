import { env } from "env.mjs"

// The site's identity, written once. The page's title and heading read
// SITE_NAME; its "Get started" and "Deploy Now" buttons link SOURCE_URL. A
// product built from this baseline gets both rewritten to its own name and
// repository at instantiation, so keep them literal and on one line each.
export const SITE_NAME = "Next.js Enterprise Boilerplate"
export const SOURCE_URL = "https://github.com/sourceplane/next-enterprise"

// The site's public origin, without a trailing slash (see env.mjs).
export const SITE_URL = (env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000").replace(/\/+$/, "")
