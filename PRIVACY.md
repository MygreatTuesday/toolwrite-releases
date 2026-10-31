# Privacy

Toolwrite is a program on your computer. It has no Toolwrite server and no account, and it sends **no usage data, analytics, or telemetry** anywhere. The only data that leaves your computer is what a build or a question needs, sent to the AI model **you** choose.

## What is sent to the AI model

When you build, change a project, or ask a question, Toolwrite sends the model:

- **your request**;
- **a sample of your project**, when you run Toolwrite inside one: its file list, entry points, configuration, and parts of its source files, at most about 12,000 characters in all;
- with `--apply`: the **current contents of the files being changed** (a long file is shortened);
- the **files Toolwrite has generated** for this request, so later files fit earlier ones;
- the project's **contract and memory** (the stack and decisions recorded in `.toolwrite/memory/`);
- for review, each **generated file** and Eunice's findings.

Where it goes depends on the provider you chose:

| Provider | Where the data goes |
|---|---|
| `local` with a model on your computer (for example `llama3:8b` in Ollama) | Nowhere: it stays on your computer. |
| `local` with an Ollama **cloud** model (names ending in `-cloud`, such as `gpt-oss:120b-cloud`) | Ollama sends it to Ollama's servers. Ollama's privacy policy (on ollama.com) applies. |
| `openai`, `anthropic`, `gemini` | To that company. Its privacy policy applies. |
| `stub` (offline) | Nowhere. |

## What is never read or sent

These files are skipped when Toolwrite reads a project, so they never reach a model:

- `.env` and its variants (`.env.production`, `.env.local`, …), except the shareable templates `.env.example`, `.env.sample`, and `.env.template`;
- private keys: `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa`, `id_ed25519`;
- credential files: `.npmrc`, `.pypirc`, `.netrc`, `credentials.json`;
- Toolwrite's own `.toolwrite.toml`, dependency folders (such as `node_modules` and `.venv`), and build output.

API keys are read only from environment variables. Toolwrite refuses settings files that contain them and never prints their values.

When `--run-checks` runs generated code, environment variables whose names look like secrets (`*KEY*`, `*TOKEN*`, `*SECRET*`, `*PASSWORD*`, `*CREDENTIAL*`, `*AUTH*`, `*SESSION*`, `*PRIVATE*`) are removed first, so generated code cannot read your keys.

## What is stored on your computer

| What | Where |
|---|---|
| Generated files | `output/` in the folder you ran Toolwrite in (or the project itself with `--apply`) |
| Backups of replaced files, for `toolwrite undo` | `.toolwrite/backups/` in the project |
| Project memory (stack, decisions, past runs) | `.toolwrite/memory/` in the project |
| Your model choice from `toolwrite setup` | `%APPDATA%\toolwrite\config.toml` (Windows), `~/Library/Application Support/toolwrite/config.toml` (macOS), `~/.config/toolwrite/config.toml` (Linux) |
| Installed packages reused by `--run-checks` | your temp folder, `toolwrite-run-cache` (the 8 most recent) |
| Compiled Rust dependencies for checks | your temp folder, `toolwrite-cargo-target` |

Delete any of these whenever you like; Toolwrite recreates what it needs.

## Other network connections

Besides the model, Toolwrite connects only:

- to Ollama on your computer (`127.0.0.1:11434`), to list its models in `toolwrite setup` and to check it is running;
- with `--run-checks`: to the package registries your generated project uses (PyPI through pip, npm, crates.io through cargo), to install its dependencies;
- to the app it just started, on your own computer, to check it answers.

The installer downloads Toolwrite from GitHub.
