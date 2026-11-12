import * as path from "node:path"

import react from "@vitejs/plugin-react"
import { defineConfig } from "vitest/config"

// The app's own absolute imports (its tsconfig's baseUrl is apps/web), so a
// test imports the page, the seam, the components and the stories as the app
// does. A file that reads the server-side environment (next.config.ts,
// env.mjs) runs under `// @vitest-environment node`: in jsdom, t3-env treats
// the test as a browser and refuses a server variable.
const web = path.resolve(__dirname, "../../apps/web")

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: [
      { find: /^app\//, replacement: `${web}/app/` },
      { find: /^components\//, replacement: `${web}/components/` },
      { find: /^lp-items$/, replacement: `${web}/lp-items.tsx` },
      { find: /^env\.mjs$/, replacement: `${web}/env.mjs` },
    ],
    dedupe: ["react", "react-dom"],
  },
  test: {
    include: ["src/**/*.test.ts", "src/**/*.test.tsx"],
    environment: "jsdom",
    setupFiles: ["./src/setup.ts"],
  },
})
