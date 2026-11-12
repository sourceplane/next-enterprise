# web-tests

The site's vitest suites (the template's own Button tests and ours — the page, the name seam, the health route, the env schema, the stories as portable stories, the Worker config), run with pnpm test, and a Storybook build check

The test suite for **web**. It deploys nothing: its lane installs, builds and runs the tests.

|              |                      |
| ------------ | -------------------- |
| Type         | `turbo-package`      |
| Source       | `tests/web`          |
| Package      | `@app/web-tests`     |
| Environments | `dev`: `quick-check` |

## Depends on

- (none)

## Depended on by

- (none)
