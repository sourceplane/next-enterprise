import { composeStories } from "@storybook/react"
import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import * as stories from "components/Button/Button.stories"

const { Default } = composeStories(stories)

// The template's stories, run as portable stories: what Storybook's test
// runner checks in a browser (the baseline's end-to-end tier runs that too),
// here with every render in jsdom.
describe("the Button stories (apps/web/components/Button/Button.stories.tsx)", () => {
  it("renders the default story with its args", () => {
    render(<Default />)
    const link = screen.getByText("Button")
    expect(link.tagName).toBe("A")
    expect(link).toHaveClass("bg-blue-400", "text-white", "text-lg")
  })

  it("renders the secondary, small variant the controls offer", () => {
    render(<Default intent="secondary" size="sm" />)
    const link = screen.getByText("Button")
    expect(link).toHaveClass("bg-transparent", "text-blue-400", "text-sm")
  })
})
