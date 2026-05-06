See [`README.md`](./README.md) for purpose, requirements, and usage.

## Agent Development Workflow

When making changes to this repository, follow this workflow:

1. **Make all file edits** - Complete all necessary changes before testing
2. **Commit and push changes** - Push to trigger CI first:
   ```bash
   git add .
   git commit -m "descriptive message"
   git push
   ```
3. **Monitor CI** - Check GitHub Actions status
4. **Build locally (if needed)** - If CI is still running, every 20 seconds, start local build and let it run validating if actions completes with green every 20 seconds.:
   ```bash
   make build
   make test
   ```
   it is basically a race to see which one finishes with a return code first.  If we need to spawn two sub agents one to monitor local command and one to monitor actions please do so. 
5. **Cancel local if CI passes** - If CI completes successfully before local tests finish, cancel the local run

This workflow prioritizes CI feedback and avoids redundant local testing when CI passes quickly.

### Agent Notes
- Prefer running tools inside the container via `make run cmd="..."` (e.g. `make run cmd="gh release create ..."`).
- Do not run `git` commands via `make run` (run git on the host).
- The container runs as `root` by default, so home is `/root`.
- If you need additional tools later, prefer adding them to `Dockerfile` and documenting them in [`README.md`](./README.md).
- When editing multiple files, complete all edits before running `make build` and `make test`.

