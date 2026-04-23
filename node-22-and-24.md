# Node 22 and Node 24 Version Matrix Plan

This document outlines the necessary changes to support building and testing the `openclaw-sandbox` codebase across both Node.js v22 and Node.js v24 environments. This requires coordinated updates to the `Dockerfile`, `package.json`, and the GitHub Actions workflow file.

## 🚀 Overview
The goal is to move from a single, fixed environment build to a matrix build in CI, allowing us to test our application's compatibility with two major Node versions side-by-side.

## 📁 1. `Dockerfile` Modifications
The Dockerfile must be updated to treat `NODE_VERSION` as an argument, ensuring the correct base image is pulled for the build context.

**Location:** `Dockerfile`
**Change Required:** Update the `FROM` line to use the argument.

*   **Before (Conceptually):** `FROM node:24`
*   **After (Implementation):** Use `ARG NODE_VERSION` and update `FROM node:${NODE_VERSION}`.

## 📜 2. `package.json` Modifications
The package manager must be aware that the code is intended to run on multiple Node versions.

**Location:** `package.json`
**Change Required:** Update the `"engines"` field.

*   **Before:** `"node": ">=22.14.0"`
*   **After:** Update to a range that encompasses both v22 and v24, for example: `"node": ">=22.0.0 <25.0.0"`. (This suggests broad support across the current major releases).

## ⚙️ 3. `.github/workflows/make-test.yml` Modifications
This is the core change, implementing the matrix strategy.

**Location:** `.github/workflows/make-test.yml`
**Change Required:** Convert the job from a single definition to a matrix strategy.

**Summary of Changes:**
1.  Replace the single `make-test` job definition with a `strategy: matrix` targeting `node-version: [22, 24]`.
2.  The `actions/setup-node` step must use the `${{ matrix.node-version }}` context variable.
3.  The `make build` and `make test` steps must explicitly pass the active Node version as an environment variable to the `make` command:
    *   `run: NODE_VERSION=${{ matrix.node-version }} make build`
    *   `run: NODE_VERSION=${{ matrix.node-version }} make test`

## ✨ Summary of Implementation Steps
1.  Edit `Dockerfile` to use `NODE_VERSION` argument.
2.  Edit `package.json` to update `"engines"`.
3.  Edit `.github/workflows/make-test.yml` to use a matrix strategy and pass `NODE_VERSION` environment variable to `make` commands.

This plan fully addresses the need to test both Node 22 and Node 24 by leveraging the build arguments and matrix capabilities of GitHub Actions, ensuring the correct environment context is passed to the underlying `make` build system.