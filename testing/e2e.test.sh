#!/usr/bin/env bash
# TIER 2 — the site a bootstrap produces builds, deploys (dry) and serves.
#
# placement.test.sh proves the tree a bootstrap ends with is the right tree.
# This proves it WORKS, by doing to it what its own pipelines will:
#
#   1. at the finished site, the landing's own checks — install with the
#      lockfile the site ships, render fixtures, typecheck, lint, test,
#      build. The bootstrap's own landings are checked in the box with
#      `orun validate` and `orun plan` alone (`checks: local`; their PR's CI
#      on an `orun/BASE-…` branch is `plan` alone, and the convergence on
#      main builds, deploys and smoke-tests the site), so THIS is where a
#      site those steps refuse is caught: before the tag, not after a build
#      has merged it. Every later pull request of the site runs ci.yml's
#      verify lanes;
#   2. the stage lane's own steps, rendered by `orun plan` in the site: on a
#      pull request (the verify profile) `build-app` — the component's
#      buildCommand, origin and all, the same step the deploy profile runs —
#      `verify-build-output` and `deploy-dry-run` (`wrangler deploy --dry-run
#      --name <reponame>-web-stage`). They run IN THE TREE THE RUNNER STAGES
#      for the job (testing/lib/stage-job.py), with the dependency layout the
#      pinned composition produces: if its install step is `scope: lane`, the
#      top-level node_modules is a symlink to the source checkout's; if not,
#      the job's own install step runs inside the staged tree. Run in a plain
#      checkout, this tier was green while the first live bootstrap's lanes
#      died in the lane layout (Turbopack: "Symlink … points out of the
#      filesystem root");
#   3. serve the built Worker with `wrangler dev` and run the component's OWN
#      `smokeCommand` against it, verbatim — the check the real deploy ends
#      with — and then read every route the site promises: the heading and
#      title carry the site's name, the buttons link the site's repository,
#      the Open Graph card is absolute on the stage origin and its image is
#      served, the health check answers on all five of the template's
#      addresses, a missing page and a missing chunk are 404s — as plain
#      requests and as browser navigations;
#   4. the template's own browser tests: its Playwright suite (e2e/) in the
#      three browsers its config names, against that Worker; and its
#      Storybook built and run by Storybook's test runner, as its check.yml
#      did.
#
# What it cannot do is the platform's half: create the repository, mint the
# brokered Cloudflare token, deploy for real and probe workers.dev. That is a
# bootstrap against a workspace (BOOTSTRAP.md); everything short of it is here.
#
# Needs: orun, node, pnpm, python3 (+PyYAML), git, curl, and the network for
# `pnpm install` (or a warm store) and Playwright's browsers (or a warm cache). A few minutes: two installs and builds
# (the landing's checks over the site, and the stage lane's own in its staged
# tree).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$here/lib/bootstrap.sh"

for bin in orun node pnpm python3 git curl; do
  command -v "$bin" >/dev/null || { echo "e2e.test.sh needs $bin on PATH" >&2; exit 1; }
done

scratch="$(mktemp -d)"
dev_pid=""
sb_pid=""
# wrangler dev runs under pnpm, node and two workerd processes; a TERM to the
# first does not reach the rest, and waiting on it then never returns. So it is
# started as its own process group (setsid) and the whole group is stopped.
stop_group() {
  local pid="$1"
  [ -n "$pid" ] || return 0
  kill -TERM -- "-$pid" 2>/dev/null || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 -- "-$pid" 2>/dev/null || break; sleep 0.5; done
  kill -KILL -- "-$pid" 2>/dev/null || true
}
cleanup() {
  stop_group "$dev_pid"
  stop_group "$sb_pid"
  rm -rf "$scratch"
}
trap cleanup EXIT
values="$here/fixtures/acme.json"
repo="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reponame'])" "$values")"
sub="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['subdomain'])" "$values")"
export CI=1 WRANGLER_SEND_METRICS=false NEXT_TELEMETRY_DISABLED=1 TURBO_TELEMETRY_DISABLED=1

# The landing's own checks, step for step, run here at once on the whole
# tree. A pull request in the site builds and dry-deploys it through ci.yml's
# lanes; the lint and the tests run here, and by hand before a push.
LANDING_CHECKS=(
  "pnpm install --frozen-lockfile"
  "pnpm run wire:fixture"
  "pnpm typecheck"
  "pnpm lint"
  "pnpm test"
  "pnpm build"
)
checks() { # DIR LOG
  local dir="$1" log="$2" cmd
  for cmd in "${LANDING_CHECKS[@]}"; do
    echo "   \$ $cmd" | tee -a "$log"
    if ! (cd "$dir" && bash -c "$cmd") >> "$log" 2>&1; then
      echo "FAIL: \`$cmd\` failed in $dir" >&2; tail -40 "$log" >&2; return 1
    fi
  done
}

echo "── the offline bootstrap (testing/lib/bootstrap.sh)"
tree="$scratch/$repo"
bootstrap_offline "$root" "$tree" "$values" "$scratch/logs" > "$scratch/bootstrap.log" 2>&1 || {
  echo "FAIL: the offline bootstrap stopped" >&2; tail -40 "$scratch/bootstrap.log" >&2; exit 1; }
echo "   2 phases placed and landed"

# ── 1. the finished site ───────────────────────────────────────────────────
echo "── the finished site: install, the fixture render, typecheck, lint, test, build"
checks "$tree" "$scratch/checks-site.log"

# ── 2. the deploy lane's steps, for stage ──────────────────────────────────
echo "── the stage lane: build-app, verify-build-output, deploy-dry-run"
# The 01-product landing over the repository's empty first commit: every file
# of the site changed, as on its pull request.
s00="$(git -C "$tree" rev-parse HEAD~2)"; s01="$(git -C "$tree" rev-parse HEAD~1)"
(cd "$tree" && orun plan --intent intent.yaml --trigger github-pull-request --changed \
   --base "$s00" --head "$s01" --env stage --output "$scratch/plan.json") > "$scratch/plan.log" 2>&1 \
  || { echo "FAIL: orun plan" >&2; tail -15 "$scratch/plan.log" >&2; exit 1; }
python3 - "$scratch/plan.json" "$scratch/steps" <<'PY'
import json, pathlib, sys
plan = json.load(open(sys.argv[1]))
out = pathlib.Path(sys.argv[2]); out.mkdir()
job = next(j for j in plan["jobs"] if j["component"] == "web" and j["environment"] == "stage")
for s in job["steps"]:
    if s["id"] in ("build-app", "verify-build-output", "deploy-dry-run"):
        (out / f"{s['id']}.sh").write_text(s.get("run") or "")
    if s["id"] == "install-workspace-dependencies":
        (out / "install.sh").write_text(s.get("run") or "")
        (out / "install.wd").write_text(s.get("working-directory") or ".")
        (out / "install.scope").write_text(s.get("scope") or "job")
(out / "path").write_text(job.get("path") or "apps/web")
for k, v in (job.get("env") or {}).items():
    (out / "env").open("a").write(f"export {k}={json.dumps(v)}\n")
PY
# The job's private tree, staged as orun stages it. The source checkout
# carries no build output (a CI checkout has none, so the plain-tree build's is
# removed rather than copied in), and its dependencies are what the pinned
# composition says: a lane-scoped install ran once in the source tree (step 1
# ran the same command) and is linked in, or the job installs its own.
rm -rf "$tree/apps/web/.open-next" "$tree/apps/web/.wrangler"
work="$tree/.orun/runs/e2e/web.stage.verify-deploy/work"
[ -f "$scratch/steps/install.sh" ] || { echo "FAIL: the stage lane has no install step" >&2; exit 1; }
if [ "$(cat "$scratch/steps/install.scope")" = lane ]; then
  python3 "$here/lib/stage-job.py" "$tree" "$work" --shared-deps
  [ -L "$work/node_modules" ] || { echo "FAIL: the staged tree's node_modules is not the lane's symlink" >&2; exit 1; }
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: lane — node_modules → the source tree's"
else
  python3 "$here/lib/stage-job.py" "$tree" "$work"
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: job — installing inside it"
  echo "   ▸ install-workspace-dependencies"
  (cd "$work/$(cat "$scratch/steps/path")/$(cat "$scratch/steps/install.wd")" && bash -e "$scratch/steps/install.sh") \
    > "$scratch/install.log" 2>&1 || { echo "FAIL: the lane's install step" >&2; tail -30 "$scratch/install.log" >&2; exit 1; }
  [ -d "$work/node_modules" ] && [ ! -L "$work/node_modules" ] \
    || { echo "FAIL: the job's install did not land inside its own tree" >&2; exit 1; }
fi
for step in build-app verify-build-output deploy-dry-run; do
  [ -f "$scratch/steps/$step.sh" ] || { echo "FAIL: the stage verify lane has no $step step" >&2; exit 1; }
  echo "   ▸ $step"
  # The runner's per-job environment: the job's env (intent environment
  # `env:`) and ORUN_ENVIRONMENT; the step runs in the component's directory.
  if ! (cd "$work/$(cat "$scratch/steps/path")" && \
        { [ -f "$scratch/steps/env" ] && source "$scratch/steps/env"; true; } && \
        export ORUN_ENVIRONMENT=stage && bash -e "$scratch/steps/$step.sh") > "$scratch/$step.log" 2>&1; then
    echo "FAIL: the deploy lane's $step step" >&2; tail -40 "$scratch/$step.log" >&2; exit 1
  fi
done

# ── 3. serve it, and smoke it as the deploy does ───────────────────────────
echo "── wrangler dev over the built Worker"
port=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
(cd "$work/apps/web" && exec setsid pnpm exec wrangler dev --config wrangler.jsonc --ip 127.0.0.1 --port "$port" \
   --name "$repo-web-stage" --show-interactive-dev-session=false) > "$scratch/dev.log" 2>&1 < /dev/null &
dev_pid=$!
url="http://127.0.0.1:$port"
for _ in $(seq 1 90); do
  curl -s -o /dev/null "$url/" && break
  kill -0 "$dev_pid" 2>/dev/null || { echo "FAIL: wrangler dev exited" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }
  sleep 1
done
curl -s -o /dev/null "$url/" || { echo "FAIL: wrangler dev never answered" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }

echo "   ▸ the component's own smokeCommand, DEPLOYED_URL=$url"
smoke="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['smokeCommand'])" "$tree/apps/web/component.yaml")"
DEPLOYED_URL="$url" bash -c "$smoke" || { echo "FAIL: the deploy's smoke refused the site" >&2; exit 1; }

echo "   ▸ every route the site promises"
python3 - "$url" "$values" "https://$repo-web-stage.$sub.workers.dev" <<'PY'
import html, json, re, sys, urllib.error, urllib.request
base, values, origin = sys.argv[1], json.load(open(sys.argv[2])), sys.argv[3]
name, repo, org = values["productname"], values["reponame"], values["githuborg"]
source = f"https://github.com/{org}/{repo}"
problems = []
def bad(m): problems.append(m)
NAV = {"Sec-Fetch-Mode": "navigate", "Sec-Fetch-Dest": "document", "Accept": "text/html"}
def get(path, headers=None):
    req = urllib.request.Request(base + path, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, r.headers.get("content-type", ""), r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers.get("content-type", ""), e.read()
def text(fragment):
    return html.unescape(re.sub(r"<!--.*?-->", "", re.sub(r"<[^>]+>", "", fragment))).strip()

status, _, body = get("/", NAV)
page = body.decode()
if status != 200:
    bad(f"/ answered {status} to a browser navigation")
h1 = re.search(r"<h1[^>]*>(.*?)</h1>", page, re.S)
if not h1 or text(h1.group(1)) != name:
    bad(f"the home page's heading is {h1 and h1.group(1)!r}, not {name!r}")
title = re.search(r"<title>(.*?)</title>", page, re.S)
if not title or html.unescape(title.group(1)) != name:
    bad(f"the home page's <title> is {title and title.group(1)!r}, not {name!r}")
links = [html.unescape(h) for h in re.findall(r'<a [^>]*href="([^"]+)"', page)]
for want in (source, source + "#deploy-by-hand"):
    if want not in links:
        bad(f"no button links {want}: {links}")
if "Next.js Enterprise Boilerplate" in page or "sourceplane/next-enterprise" in page \
        or "Blazity/next-enterprise" in page or "vercel.com/new" in page:
    bad("the home page still carries the baseline's or the template's name or links")
og_url = re.search(r'<meta property="og:url" content="([^"]+)"', page)
og_img = re.search(r'<meta property="og:image" content="([^"]+)"', page)
if not og_url or html.unescape(og_url.group(1)) != origin + "/":
    bad(f"og:url is {og_url and og_url.group(1)!r}, not {origin + '/'!r}")
if not og_img or html.unescape(og_img.group(1)) != origin + "/project-logo.png":
    bad(f"og:image is {og_img and og_img.group(1)!r}, not on {origin}")
s, ctype, body = get("/project-logo.png")
if s != 200 or body[:8] != b"\x89PNG\r\n\x1a\n":
    bad(f"/project-logo.png answered {s} {ctype} — not the Open Graph PNG")
css = re.findall(r'href="(/_next/static/[^"]+\.css)"', page)
if not css or get(css[0])[0] != 200:
    bad(f"the page's stylesheet is not served: {css[:1]}")
if "Create, test, and showcase your components" not in page:
    bad("the feature grid is not rendered")

for path in ("/api/health", "/healthz", "/api/healthz", "/health", "/ping"):
    s, ctype, body = get(path)
    try:
        ok = s == 200 and ctype.startswith("application/json") and json.loads(body) == {"status": "ok"}
    except ValueError:
        ok = False
    if not ok:
        bad(f"{path} answered {s} {ctype} {body[:60]!r}, not the health check's {{status: ok}}")

for path in ("/no-such-page", "/_next/static/chunks/no-such-chunk.js"):
    for label, headers in (("", None), (" (navigation)", NAV)):
        s, _, _ = get(path, headers)
        if s != 404:
            bad(f"{path}{label} answered {s}, want 404")

if problems:
    for p in problems:
        print(f"  ✕ {p}", file=sys.stderr)
    sys.exit(1)
print(f"   /, its Open Graph card on {origin}, the five health addresses and the 404s — the site's own")
PY

# ── 4. the template's own browser tests ───────────────────────────────────
# Playwright's browsers, at the version the site locks. On GitHub's runners
# their system libraries come too (`--with-deps`, which needs sudo).
pw_deps=""
[ "${GITHUB_ACTIONS:-}" = true ] && pw_deps="--with-deps"
echo "── the template's browser tests"
echo "   ▸ playwright install $pw_deps chromium firefox webkit"
(cd "$tree/apps/web" && pnpm exec playwright install $pw_deps chromium firefox webkit) > "$scratch/pw-install.log" 2>&1 \
  || { echo "FAIL: installing Playwright's browsers" >&2; tail -20 "$scratch/pw-install.log" >&2; exit 1; }
echo "   ▸ Playwright (e2e/: chromium, firefox and webkit) against the Worker"
(cd "$tree/apps/web" && PLAYWRIGHT_BASE_URL="$url/" pnpm exec playwright test --reporter=list) > "$scratch/playwright.log" 2>&1 \
  || { echo "FAIL: the template's Playwright suite" >&2; tail -40 "$scratch/playwright.log" >&2; exit 1; }
grep -qE '\b3 passed' "$scratch/playwright.log" \
  || { echo "FAIL: Playwright did not run the title test in all three browsers" >&2; tail -20 "$scratch/playwright.log" >&2; exit 1; }
stop_group "$dev_pid"; dev_pid=""

echo "   ▸ Storybook built, then Storybook's test runner over every story"
(cd "$tree/apps/web" && STORYBOOK_DISABLE_TELEMETRY=1 pnpm run build-storybook --quiet) > "$scratch/storybook-build.log" 2>&1 \
  || { echo "FAIL: build-storybook" >&2; tail -30 "$scratch/storybook-build.log" >&2; exit 1; }
sb_port=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
(cd "$tree/apps/web/storybook-static" && exec setsid python3 -m http.server "$sb_port" --bind 127.0.0.1) > "$scratch/storybook-serve.log" 2>&1 < /dev/null &
sb_pid=$!
for _ in $(seq 1 30); do curl -s -o /dev/null "http://127.0.0.1:$sb_port/index.json" && break; sleep 0.5; done
(cd "$tree/apps/web" && STORYBOOK_DISABLE_TELEMETRY=1 pnpm run test-storybook --url "http://127.0.0.1:$sb_port") > "$scratch/test-storybook.log" 2>&1 \
  || { echo "FAIL: Storybook's test runner" >&2; tail -40 "$scratch/test-storybook.log" >&2; exit 1; }
# The template's script forces colour (FORCE_COLOR=1): read the summary without
# its escape codes.
sed 's/\x1b\[[0-9;]*m//g' "$scratch/test-storybook.log" > "$scratch/test-storybook.txt"
sed 's/\x1b\[[0-9;]*m//g' "$scratch/playwright.log" > "$scratch/playwright.txt"
grep -qE 'Tests: +[1-9][0-9]* passed' "$scratch/test-storybook.txt" \
  || { echo "FAIL: the test runner ran no story" >&2; tail -20 "$scratch/test-storybook.log" >&2; exit 1; }
echo "   Playwright: $(grep -oE '[0-9]+ passed' "$scratch/playwright.txt" | tail -1); Storybook: $(grep -oE 'Tests: +[0-9]+ passed' "$scratch/test-storybook.txt" | tail -1 | tr -s ' ')"

echo "e2e.test.sh: ok"
