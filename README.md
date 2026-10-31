# Toolwrite

Toolwrite is a developer CLI that routes build requests through Treehouse to the appropriate specialist and requires Eunice verification before generated code is delivered.

New here? Start with the [User Guide](docs/user-guide.md). Beta testers: [the beta guide](docs/beta-testers.md). Also: [Privacy](PRIVACY.md) (what is sent to the AI model, what is stored), [Security](SECURITY.md) (what Toolwrite protects, the risks, and reporting a problem), and the [Changelog](CHANGELOG.md).

## Install

### One command

```powershell
# Windows (PowerShell)
irm https://<toolwrite-site>/install.ps1 | iex
```

```sh
# macOS and Linux
curl -fsSL https://<toolwrite-site>/install.sh | sh
```

The installers in `install/` download the newest release for your system, check its SHA-256 checksum, and install `toolwrite` for your user without administrator rights: into `%LOCALAPPDATA%\Programs\toolwrite\bin` (added to your PATH) on Windows, and `~/.local/bin` on macOS and Linux. They then show how to continue: `toolwrite setup`. `TOOLWRITE_VERSION` picks a release, `TOOLWRITE_INSTALL` another folder, and `TOOLWRITE_REPO` another release repository; by default they read releases from the public `MygreatTuesday/toolwrite-releases` repository, which the code repository's releases are published to.

### From a release

Each release has a ready-made download for Windows (x86-64), macOS (Apple silicon and Intel), and Linux (x86-64), with a `.sha256` checksum. Download the archive for your system from the repository's Releases page, unpack it, and put `toolwrite` (`toolwrite.exe` on Windows) in a folder on your `PATH`. No Rust is needed.

On macOS, an unsigned download is blocked the first time; allow it with `xattr -d com.apple.quarantine toolwrite`, or in System Settings → Privacy & Security.

To publish a release, set the version in `crates/toolwrite-cli/Cargo.toml`, commit, then push a matching tag: `git tag v0.1.0 && git push origin v0.1.0`. The Release workflow builds the four downloads and attaches them.

### From source

Toolwrite is not published to crates.io. Install Rust and Cargo 1.88 or newer, then run from the repository root:

```sh
cargo install --path crates/toolwrite-cli --locked
```

Confirm the command is on your `PATH`:

```sh
toolwrite --version
toolwrite --help
```

To build without installing, use `cargo build --release -p toolwrite-cli`; the executable is `target/release/toolwrite` (Windows: `target/release/toolwrite.exe`).

## First Build

Choose your AI model once:

```sh
toolwrite setup
```

`setup` finds Ollama (free, from [ollama.com](https://ollama.com/download)), lists its models, recommends one (`gpt-oss:120b-cloud`, the model Toolwrite is tested with, when you are signed in to Ollama; otherwise another cloud model, or the largest model on your computer), and saves your choice to your personal settings: `%APPDATA%\toolwrite\config.toml` on Windows, `~/Library/Application Support/toolwrite/config.toml` on macOS, `~/.config/toolwrite/config.toml` on Linux (`TOOLWRITE_CONFIG` names another file). Every project without its own `.toolwrite.toml` uses them. It ends with one small test request. `--model NAME` chooses without asking; `--yes` takes the recommendation. Without a model server it explains how to get one, and Toolwrite stays in offline mode.

Then, in any empty folder:

```sh
toolwrite "Create a small responsive landing page for a neighborhood bakery"
```

For settings that belong to one project, create a project file there:

```sh
toolwrite init
toolwrite doctor
```

`init` creates `.toolwrite.toml` and defaults to `stub`, the offline mode: no AI provider and no network. In offline mode a new project gets Toolwrite's built-in blueprint when one fits the request (see [Blueprints](#blueprints)); other files are basic templates. Generated files go to `output/` by default. Eunice must approve the result before Toolwrite writes it there. A rejected request exits unsuccessfully and includes the verification findings. A build writes all of its files or none of them; when it replaces an existing file whose contents change, the previous version is first saved under `.toolwrite/backups/<task-id>/`.

To use a hosted model, select the provider and set its key in the process environment. You can choose a provider during initialization, in `.toolwrite.toml`, or per command:

```sh
toolwrite init --provider openai
toolwrite doctor
toolwrite build "Add a JSON health endpoint" --model gpt-4o-mini
```

A successful build ends with how to run the result (open the page, `cargo run`, `npm run dev`, `uvicorn main:app --reload`, and so on). Ask `toolwrite "what can you build?"` for the supported stacks; a request that names nothing to build gets a clarifying question instead of a guess.

### First real-AI test

`scripts/live-test.ps1` runs your first hosted-model build in one step. It asks for the key with hidden input, keeps it only in its own process, confirms the key and credit with one tiny request, then runs a small build in `~/toolwrite-live-test` with fast review mode and a 40-call cap:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\live-test.ps1 -Provider openai
powershell -ExecutionPolicy Bypass -File scripts\live-test.ps1 -Provider anthropic -Model claude-sonnet-5-5
```

Supported providers are `gemini`, `openai`, `anthropic`, `local` (an OpenAI-compatible local server), and `stub`. An explicit `TOOLWRITE_RUNTIME` environment variable or `--provider` overrides the project setting. With no project config, Toolwrite auto-detects provider keys and otherwise uses stub mode. Empty variables count as unset. `TOOLWRITE_API_KEY` alone does not name a provider, so Toolwrite asks you to choose one with `--provider`, `TOOLWRITE_RUNTIME`, or the config instead of guessing.

### Without a hosted provider

Toolwrite does not need OpenAI, Anthropic, or Gemini. The `local` provider works with any OpenAI-compatible model server on your machine: Ollama (`http://127.0.0.1:11434`, the default), LM Studio, llama.cpp's `llama-server`, LocalAI, or vLLM. No API key is needed:

```sh
toolwrite --provider local --model qwen2.5-coder:7b doctor --online
toolwrite --provider local --model qwen2.5-coder:7b build "Create a landing page for a bakery"
```

Set `TOOLWRITE_ENDPOINT` for a server other than Ollama. Local models run on your hardware; without a dedicated GPU, expect a small build to take several minutes. Raise `TOOLWRITE_TIMEOUT_SECS` (default 300) if single requests time out.

## Blueprints

Blueprints are Toolwrite's own library of complete, working starter projects. When a request starts a new project on a stack with a blueprint, every file's blueprint goes to the specialist as a known-good starting point to adapt, which helps small local models in particular. In offline mode the blueprint is delivered as is, named from the request: "a landing page for a neighborhood bakery" is titled "Neighborhood Bakery", and "a todo API" serves `/todos`.

| Blueprint | Chosen for | Files |
|---|---|---|
| Static landing page | Frontend, plain HTML/CSS/JS | `index.html` (navigation, hero, highlights, contact form), `styles.css` (responsive, dark mode, reduced motion), `script.js` (menu, form validation) |
| React app | Frontend, React | `src/App.tsx` (add, mark done, filter, remove; saved in the browser), `src/App.css`, `src/main.tsx`, `index.html`, `src/App.test.tsx` (Vitest, Testing Library), `vite.config.ts`, `tsconfig.json`, `package.json`, `README.md` |
| FastAPI service | Python / FastAPI backend | `main.py` (CRUD API on SQLite, `/health`), `test_main.py`, `requirements.txt`, `README.md` |
| Flask API | Python / Flask backend | `main.py` (CRUD JSON API on SQLite, validation, `/health`), `test_main.py`, `requirements.txt`, `README.md` |
| Express API | Node / Express backend | `server.js` (CRUD JSON API, validation, `/health`), `server.test.js`, `package.json`, `README.md` |
| Axum API | Rust / Axum backend | `src/main.rs` (CRUD JSON API, validation, `/health`, tests), `Cargo.toml`, `README.md` |

Each blueprint is proven to work: its tests pass, and the app starts (or, for React, type-checks and builds).

Blueprints are never applied inside an existing project, so they cannot overwrite your code.

## API Keys

Keys are read only from environment variables. Never put a key in `.toolwrite.toml`, source code, a prompt, or a committed file. Toolwrite does not save or print key values, and it never reads `.env` files or private keys into a prompt. Prefer the provider-specific key; `TOOLWRITE_API_KEY` is also accepted by the hosted providers as a fallback. Use the secret key itself (OpenAI's start with `sk-`), not the key's ID or name.

PowerShell, for the current terminal session (the key is not shown while you paste it):

```powershell
$k = Read-Host "OpenAI key" -AsSecureString; $env:OPENAI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($k))
toolwrite init --provider openai
toolwrite doctor --online
```

Bash or Zsh, for the current terminal session:

```sh
read -rs OPENAI_API_KEY && export OPENAI_API_KEY
toolwrite init --provider openai
toolwrite doctor --online
```

`doctor` checks that a key is set; `doctor --online` also sends one tiny request, so a wrong key or an empty credit balance shows up before a build. Rejected keys and billing errors fail at once with the provider's message; only rate limits and server errors are retried.

The provider key names are `GEMINI_API_KEY`, `OPENAI_API_KEY`, and `ANTHROPIC_API_KEY`. For a local OpenAI-compatible server, `TOOLWRITE_ENDPOINT` defaults to `http://127.0.0.1:11434/v1/chat/completions`; `TOOLWRITE_MODEL` defaults to `llama3.2`. Set `TOOLWRITE_API_KEY` only if the local server requires authentication.

## The Toolwrite Shell

Run `toolwrite` with no request to open the shell. Type a request to build it, or a question to ask about the project; commands start with `/`:

```text
/build <request>       Build, even if it reads like a question
/ask <question>        Ask about the project (needs an AI provider)
/analyze               Report on the project without AI
/status                Show provider, model, and settings
/provider <name>       Switch provider: gemini, openai, anthropic, local, stub
/model <name>          Switch model, e.g. /model gpt-oss:120b-cloud
/apply on|off          Write into the project itself (with a preview)
/run-checks on|off     Install, test, and start the app before delivering
/verbose on|off        Show every layer's detailed logs
/undo                  Reverse the latest build
/help, /exit
```

Builds show one line per step and file, then a short summary:

```text
  Treehouse  ▸ starting from the Static landing page (HTML, CSS, JavaScript) blueprint
  Treehouse  ▸ planned 3 file(s) · Static HTML
  Eugenia    ▸ index.html ✓ approved
  Eugenia    ▸ styles.css · fixing ✓ approved after 1 fix
  Eugenia    ▸ script.js ✓ approved
  Project    ▸ ✓ web-links

✓ Built 3 file(s) in 74s in output: index.html, styles.css, script.js
```

Every layer's detailed logs (each review stage, task transitions, the full report) appear with `--verbose`, on the command line or as `/verbose on` in the shell.

## Commands

```text
toolwrite                              Open the Toolwrite shell
toolwrite setup [--model NAME] [--yes] Choose your AI model for every project
toolwrite init [--provider PROVIDER]   Create project configuration
toolwrite build REQUEST                Run a build request
toolwrite "REQUEST"                    Shorthand for build
toolwrite ask QUESTION                 Answer a question; nothing is written
toolwrite status [--json]              Show selected provider and project settings
toolwrite doctor [--json] [--online]   Check config, credentials, and output access
toolwrite build REQUEST --apply        Change the project itself, after a preview
toolwrite build REQUEST --run-checks   Install, test, and start the project before delivering
toolwrite undo                         Reverse the latest build
toolwrite analyze [PATH] [--json]      Report on a project without AI (read-only)
toolwrite verify FILE                  Run Eunice verification on an existing file
toolwrite review FILE                  Backward-compatible alias for verify
toolwrite sandbox init                 Create an isolated scratch workspace
toolwrite memory --help                Manage project memory
```

`status --json` and `doctor --json` emit one JSON object on stdout. Diagnostics and errors never include API-key values. `doctor` exits nonzero when a required credential, configuration value, local endpoint, or output permission is missing.

Exit codes: `0` means success, `1` means a build/verification/doctor action failed, and `2` means invalid command configuration or provider setup. Clap uses exit code `2` for invalid usage and prints the relevant help text.

## Configuration

`.toolwrite.toml` contains non-secret project defaults:

```toml
[project]
output_dir = "output"

[model]
provider = "stub"
# model = "gpt-4o-mini"
max_calls = 160

[review]
max_retries = 3
```

`max_calls` caps the model calls one build request may make; `TOOLWRITE_MAX_MODEL_CALLS` overrides it. Eunice spends several calls verifying each file, so a multi-file build needs well over a hundred calls once corrections are included. `max_retries` is how many times a file Eunice rejects goes back to its specialist for correction; `0` rejects the build on the first failed review.

## Changing an Existing Project

Inside an existing project, Toolwrite plans the change from the project's own files: it lists them for the model, asks which must change and which are new (at most 8), and checks the answer (inside the project, not in `.git`, `node_modules`, or build folders; a file is new only if it does not exist). Each planned file is sent whole with the request; a file over 60,000 characters is left unchanged, since a shortened copy would lose code. Without a usable plan (offline, or a model that answers in prose) the fixed plan for the stack is used.

The whole-project check (and, with `--run-checks`, the install, tests, and start) covers the whole project with the change in it, not the changed files alone, and is compared with the project as it was: Toolwrite checks the project once before the change, a check that already failed then does not count against the change, and a new failure goes to a changed file to fix. Secrets, dependencies, and build output are not copied; a project over 2,000 files or 20 MB is checked by its changed files.

By default a build writes to `output/`. With `--apply` it writes into the project itself:

```sh
toolwrite build "Add a contact form to the home page" --apply
```

- Each planned file that already exists is given to the specialist in full, with the instruction to keep what still applies and change only what the request needs.
- Before anything is written, Toolwrite lists every file as `create`, `change` (with lines added and removed), or `same`, and asks `Apply these changes? [y/N]`. Add `--yes` (`-y`) to apply without asking. Without a terminal to answer in and without `--yes`, nothing is written.
- Files are written all at once or not at all, and every replaced file is backed up under `.toolwrite/backups/<task-id>/` first.
- `toolwrite undo` reverses the latest build: it restores the files it replaced and removes the files it created. A file you edited after the build is left as it is and listed, so undo never discards your work. A build can be undone once.

Offline mode cannot change code: existing files stay exactly as they are, so it can only add new files around them.

## Analyzing a Project

`toolwrite analyze` reports on the project in the current directory (or `PATH`) without any AI model: the detected stack, languages and line counts, entry points, configuration files, a syntax check of every source file, and the whole-project checks (linked files, script IDs, `package.json` dependencies). For a Rust crate or workspace with a `Cargo.lock` it also runs `cargo check --locked`. Analysis is read-only: build output goes to a temporary directory and nothing in the project is created or changed. It exits `0` when no problems are found and `1` otherwise; `--json` prints one JSON object.

## What Happens Before Files Are Written

1. Each file is generated with the files the request already produced, so a stylesheet matches its HTML and a manifest lists the packages the source imports.
2. Eunice reviews each file (syntax, correctness, security, quality, completeness, frontend validation, and the project contract) and runs local sandbox checks. Documentation and configuration (`README.md`, manifests, `tsconfig.json`, `*.config.*`) get only the security and contract stages, since the sandbox parses them and the project check holds manifests against the code. A rejected file goes back to its specialist up to `max_retries` times.
3. The files are checked together as one project: every stylesheet and script a page links exists, scripts only look up IDs the pages define, `package.json` lists every imported package, and a Rust crate passes `cargo check`. A file the check blames gets one more correction.
4. With `--run-checks` (or `run_checks = true` under `[review]`), the project is then run for real in a scratch directory: its dependencies are installed (`pip` into a virtual environment, `npm install`), its tests run (`pytest`, `npm test`, `cargo test`), and a FastAPI, Flask, Node, or Rust server is started once and must answer `GET /health`; a front end with a `build` script must build (`npm run build`). Toolwrite prints the packages before installing them. Installs are reused: the scratch workspace is kept per `requirements.txt` or `package.json` (in your temp folder, under `toolwrite-run-cache`; the 8 most recent are kept), so a correction round or a later build with the same dependencies installs nothing, while the tests and the start still run every time. The generated code never sees your own secrets: environment variables whose names look like secrets (`*KEY*`, `*TOKEN*`, `*SECRET*`, `*PASSWORD*`, …) are removed from everything a run check starts, and the secrets the code reads (`process.env.JWT_SECRET`) get placeholder values. A failure goes back to the file to fix (the manifest for a missing package, otherwise the app's source) for one correction round. This is opt-in because it downloads packages and runs the generated code on your machine.
5. Only when all of that passes are the files written, all at once.

Python and Node backends are generated with a test file (`test_main.py`, `server.test.js`), and every blueprint except the static landing page includes working tests.

Environment switches: `TOOLWRITE_REVIEW_MODE=fast` skips Eunice's correctness, quality, and completeness stages and her written summary (fewer model calls); `TOOLWRITE_MAX_MODEL_CALLS` caps model calls per request; `TOOLWRITE_PROJECT_BUILD=off` skips `cargo check` (for example, offline). Each real-provider build ends with the number of model calls it used.

Configuration is loaded from the current directory or its parents. Unknown fields and invalid providers are reported rather than silently ignored. `toolwrite status` shows which configuration file is active; `toolwrite doctor` checks the selected provider and output directory.

## Tests

Run the complete workspace test suite from the repository root:

```sh
cargo test --workspace
```

To run everything CI runs (formatting, lints, all tests, and the Rust 1.88 check when that toolchain is installed) in one go, on your own machine:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check.ps1          # about 6 minutes
powershell -ExecutionPolicy Bypass -File scripts\check.ps1 -Eval    # plus the offline build-success suite
```

`scripts\release-local.ps1` builds the Windows release archive and its checksum into `dist\`, packaged like the Release workflow's, for publishing by hand.

### Build-success suite

`scripts/eval.ps1` measures how well Toolwrite builds real projects with a given model: it runs the 20 requests in `scripts/eval-cases.json` (each blueprint stack, custom content, harder features, stacks without a blueprint, a full-stack app, and changes to existing projects), each in its own empty folder, and reports how many passed, how long they took, and how many AI calls they used.

```powershell
# The offline baseline (no AI); also checks that the suite itself works.
powershell -ExecutionPolicy Bypass -File scripts\eval.ps1 -Provider stub

# A model, all cases (makes real model calls: up to 160 per case).
powershell -ExecutionPolicy Bypass -File scripts\eval.ps1 -Provider local -Model gpt-oss:120b-cloud

# Some cases or groups, with the production check.
powershell -ExecutionPolicy Bypass -File scripts\eval.ps1 -Provider local -Model gpt-oss:120b-cloud -Groups "custom content","existing project" -RunChecks
```

A case passes when the build delivers, the expected stack and files are there, the files mention what the request asked for (`contains`), and, with `-RunChecks`, every project check passes. Results go to `~/toolwrite-eval/<date-time>/`: `summary.md`, `summary.json`, and each case's project, log, and result file. The script reads each build's result through `TOOLWRITE_RESULT_FILE`: set it to a path and Toolwrite writes what the build planned, checked, and delivered there as JSON.

## License

Toolwrite is proprietary software. Copyright (c) 2026 MygreatTuesday. All rights reserved. See [LICENSE](LICENSE); no use, copying, or distribution is permitted without written permission.
