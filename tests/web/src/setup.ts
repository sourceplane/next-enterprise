import "@testing-library/jest-dom/vitest"

import { cleanup } from "@testing-library/react"
import { afterEach } from "vitest"

// Without vitest's globals, Testing Library cannot register its own cleanup:
// unmount every render between tests.
afterEach(() => {
  cleanup()
})
