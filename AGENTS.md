See [`README.md`](./README.md) for purpose, requirements, and usage.

### Agent notes
- Prefer running tools inside the container via `make run cmd="..."` (e.g. `make run cmd="gh release create ..."`).
- Do not run `git` commands via `make run` (run git on the host).
- The container runs as `root` by default, so home is `/root`.
- If you need additional tools later, prefer adding them to `Dockerfile` and documenting them in [`README.md`](./README.md).

