# OpenClaw Testing Specification (TESTING.md)

This document outlines the testing strategy for OpenClaw, covering unit, integration, end-to-end, and local model validation.

## 🎯 Goals
1.  **Ensure Core Functionality:** Verify that OpenClaw successfully integrates and executes against the defined environment (Node.js, Python, browser automation).
2.  **Validate Model Integration:** Test the workflow of connecting and interacting with both the primary target local LLM (e.g., an Ollama-managed model) and as a fallback, a general-purpose LLM via a local API wrapper.
3.  **Maintain Code Health:** Utilize existing comprehensive test suites defined in the `Makefile`.

## 🛠️ Prerequisites
Before running any tests, ensure the following are installed and configured:
*   Docker and Docker Buildx (for CI/CD parity).
*   OpenClaw dependencies (via `npm install` and `pip install`).
*   `ollama` (for running local LLMs).
*   Required services are running (e.g., database access, if applicable).

## 🧪 Existing Test Targets (Makefile)

The existing `Makefile` provides a robust suite of tests. These should be run as the first phase of any testing cycle.

### 1. General Smoke Test (`make test-quick`)
A minimal check to ensure all primary dependencies are accessible and basic functions execute successfully.
*   **Coverage:** Basic CLI version check, Playwright import check, OpenClaw version check, `npm test` execution.
*   **Target:** `make test-quick`

### 2. Comprehensive Full Regression (`make test`)
The primary test target. This runs full end-to-end checks across the entire stack within a Docker container to guarantee environment consistency.
*   **Coverage:** Chrome, Playwright, Node.js, Python, OpenClaw CLI, and the full `npm test` suite.
*   **Target:** `make test`

### 3. OpenClaw Specific Integration (`make test-openclaw`)
Focuses solely on the OpenClaw CLI functionality. This ensures the core logic, command handling, and API interactions of the OpenClaw tool itself are sound.
*   **Coverage:** CLI version, help output, and command availability.
*   **Target:** `make test-openclaw`

## 🌐 Local Model Validation (New Focus Area)

### 1. OpenClaw's Intended Local Model (Recommended)
The primary flow should be testing the specific local model integration designed for OpenClaw.
*   **Testing Scope:** Full round-trip flow: User input $\rightarrow$ OpenClaw processing $\rightarrow$ Local Model call $\rightarrow$ Output parsing.
*   **Test Case:** Write a dedicated integration test that initializes OpenClaw and passes a dummy prompt to the configured local model endpoint.

### 2. Fallback/Ad-Hoc Local LLM Testing (Using Ollama)
If the dedicated OpenClaw model connector is difficult to mock or test, or if a general LLM behavior needs validation, we can fall back to testing directly with `ollama`.
*   **Goal:** Validate the ability to correctly invoke and parse output from a generic local model.
*   **Execution Example (via shell):**
    ```bash
    ollama run claude "simple prompt"
    ```
*   **Testing Strategy:**
    *   **Input:** Use simple, single-prompt inputs that cover all expected prompt formats (e.g., a prompt requiring JSON, a prompt requiring a list, a simple Q&A).
    *   **Validation:** The test must verify that OpenClaw's *output parsing logic* successfully extracts the data from the unstructured text/JSON output received from the `ollama` stream.

## 📝 Testing Checklist Summary

| Feature/Scope | Test Target | Priority | Notes |
| :--- | :--- | :--- | :--- |
| Basic Setup/Dependencies | `make test-quick` | High | Smoke test, always run first. |
| Full System Integration | `make test` | High | Full regression, critical for CI/CD. |
| OpenClaw Logic | `make test-openclaw` | High | Verifies the CLI wrapper logic. |
| Local LLM Integration | Manual/New Test | Critical | Needs dedicated tests for the LLM call path. |
| Fallback LLM (Ollama) | Manual/New Test | Medium | Use `ollama run` to validate output parsing. |
