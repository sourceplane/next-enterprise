# next-enterprise — open risks

What is not yet proven or not yet decided. The full write-up of every risk,
including the accepted and resolved ones, is
`specs/epics/next-enterprise/risks-and-open-questions.md`; this page
lists only what is still live, so it should be short.

| ID | Risk | State | What closes it |
|---|---|---|---|
| EB-A | No site has been bootstrapped from this baseline against a workspace yet | OPEN | One bootstrap from `baseline-v1`, with its timings recorded |
| EB-C | The adapter raises its Next 15.5 floor with releases; a re-resolved lockfile can pair a newer adapter with an older Next | WATCH | Both are pinned exactly; move them together |
| EB-E | The lanes install Storybook, Playwright and the template's tooling (about 1.2 GB) on every build | WATCH | Accepted for now: they are the template's dev dependencies |

Accepted, and worth knowing before you change them: EB-D (`@vercel/otel`
dropped for Workers Observability), EB-F (Playwright and Storybook's test
runner run by hand and in Baseline CI, not in a site's own lanes).
