// OpenNext Cloudflare adapter config.
//
// The page is statically generated: it is pre-rendered at build time and
// nothing revalidates. The static-assets incremental cache serves it straight
// from the Worker's static assets (read only, no R2/KV/D1 to provision). The
// health route is dynamic and needs no cache at all.
import { defineCloudflareConfig } from "@opennextjs/cloudflare/config"
import staticAssetsIncrementalCache from "@opennextjs/cloudflare/overrides/incremental-cache/static-assets-incremental-cache"

export default defineCloudflareConfig({
  incrementalCache: staticAssetsIncrementalCache,
})
