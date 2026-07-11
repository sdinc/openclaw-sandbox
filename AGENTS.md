See [`README.md`](./README.md) for purpose, requirements, and usage.

## Agent Development Workflow

When making changes to this repository, follow this workflow:

1. **Make all file edits** - Complete all necessary changes before testing

2. **Build and test locally with cache** - Always test locally before committing:
   ```bash
   make build-cached  # Uses buildx cache for faster builds
   make test          # Run full test suite
   ```
   - First run will create the buildx builder automatically
   - Subsequent builds will be much faster due to caching
   - Tests must pass locally before proceeding

3. **Commit and push changes** - Only after local tests pass:
   ```bash
   git add .
   git commit -m "descriptive message"
   git push
   ```

4. **Monitor CI** - Verify GitHub Actions passes with same results

### Build and Cache Management

**Available Make Targets:**
- `make build` - Standard Docker build (no cache)
- `make build-cached` - Build with buildx cache (recommended, matches CI)
- `make test` - Full test suite with version checks
- `make test-quick` - Fast smoke test (no version check)
- `make test-openclaw` - OpenClaw-specific functionality tests
- `make bump` - Bump OpenClaw version across all codebase files (`Dockerfile`, `Makefile`, `package.json`, `pyproject.toml`)
  - Set `BETA=1` to allow bumping to beta/pre-release versions (e.g., `make bump BETA=1`)
  - Set `YES=1` to auto-approve the version bump non-interactively (e.g., `make bump YES=1`)
- `make clean` - Remove generated files and Docker images
- `make build-cached-cleanup` - Remove buildx builder and cache

**Cache Location:**
- Local cache: `/tmp/.buildx-cache`
- CI cache: `/tmp/.buildx-cache` (in GitHub Actions runner)

**First Time Setup:**
The `build-cached` target will automatically create the `openclaw-builder` buildx builder on first use.

### Version Bumping

The repository supports automated version bumping using `bump.py` via `make bump`.
- It fetches the latest OpenClaw release tag from GitHub and replaces the old version in all relevant files.
- To include beta/pre-release versions, run:
  ```bash
  make bump BETA=1
  ```
- To run non-interactively (useful for automation):
  ```bash
  make bump YES=1
  ```

### Agent Notes
- **ALWAYS run `make build-cached && make test` before git commit**
- To configure trusted workspaces and auto-approved commands for the Google Antigravity CLI (`agy`), refer to the **Configuration** section in [`README.md`](./README.md) regarding `settings.json`.
- Prefer running tools inside the container via `make run cmd="..."` (e.g. `make run cmd="gh release create ..."`).
- Do not run `git` commands via `make run` (run git on the host).
- The container runs as `root` by default, so home is `/root`.
- If you need additional tools later, prefer adding them to `Dockerfile` and documenting them in [`README.md`](./README.md).
- When editing multiple files, complete all edits before running `make build-cached` and `make test`.
- Test failures will exit with non-zero status - do not commit if tests fail.

