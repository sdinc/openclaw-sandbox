# OpenClaw Testing Strategy (TESTING.md)

This document describes the testing approach for the OpenClaw sandbox image.
The sandbox's purpose is to bundle tools (Node, Python, Chrome, openclaw, gh, etc.)
into a consistent amd64 container; tests verify that every listed tool is present
and functional.

## Test Suite

| Target | Scope | Runs in CI |
|---|---|---|
| `make test` | Full: version-check + test-openclaw + test-quick + **npm test** | Yes |
| `make test-basic` | Basic toolchain assertions (test/basic.js) | No (hidden from `make help`) |
| `make test-quick` | Chrome, Playwright import, openclaw version, npm test | Part of `test` |
| `make version-check` | Dockerfile / Makefile / package.json / pyproject.toml version sync | Part of `test` |

## test/basic.js

`test/basic.js` asserts that each tool installed by the image is present,
executable, and returns a plausible version string. It is run via the hidden
`make test-basic` target (not shown in `make help`).

### What it checks

- `openclaw --version` — matches `vYYYY.M.P`
- `node --version` — matches `v\d+`
- `npm --version` — matches `\d+\.\d+\.\d+`
- `python --version` — matches `Python \d+`
- `uv --version` — matches `uv`
- `gh --version` — matches `\d+\.\d+\.\d+`
- `zsh --version` — matches `zsh \d+`
- `google-chrome-stable --version` — present and matches `Google.*Chrome`
- `import playwright` — present (skipped if Python playwright not yet installed)

### Running

```bash
# Inside the container:
make test-basic

# Directly:
node test/basic.js
```

## Future work

- Add a `test-openclaw-integration` target that exercises a real openclaw command
  (e.g., `openclaw --help` or `openclaw version`) with output validation.
- Add a `test-chrome` target that verifies Chrome can launch headlessly:
  `google-chrome-stable --headless --dump-dom https://example.com`.
- Add a `test-playwright` target that runs a minimal Playwright script against
  a local test page.
- Consider adding `make test-dockerfile-changes` to validate new Dockerfile
  additions (like `plocate`) are present:
  `docker run --rm $(IMAGE) which plocate`.
- Replace the current `npm test` (`openclaw --version && echo 'OpenClaw test passed'`)
  with a real test script once the openclaw integration tests are written.

## What the current `npm test` does

```json
"scripts": {
  "test": "openclaw --version && echo 'OpenClaw test passed'"
}
```

This only verifies that the `openclaw` binary exists and prints a success
message. It does **not** assert output content or test any openclaw behavior.
Add real assertions to `test/basic.js` and update `package.json` to use them.