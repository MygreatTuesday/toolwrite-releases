# Privacy

Toolwrite is a program on your computer. The program sends **no usage data, analytics, or telemetry** anywhere. With Toolwrite Cloud, its requests go through Toolwrite's server to the AI model; the Toolwrite Cloud account and the website are covered by the [Privacy Policy](https://toolwrite.dev/privacy). Otherwise, the only data that leaves your computer is what a build or a question needs, sent to the AI model **you** choose.

## What is sent to the AI model

When you build, change a project, or ask a question, Toolwrite sends the model:

- **your request**;
- **a sample of your project**, when you run Toolwrite inside one: its file list, entry points, configuration, and parts of its source files, at most about 12,000 characters in all;
- with `--apply`: the **current contents of the files being changed** (a long file is shortened);
- the **files Toolwrite has generated** for this request, so later files fit earlier ones;
- the project's **contract and memory** (the stack and decisions recorded in `.toolwrite/memory/`);
- for checking, each **generated file** and the findings of earlier checks.

Where it goes:

| When | Where the data goes |
|---|---|
| Signed in to Toolwrite Cloud | Through Toolwrite's server to the AI model services it uses. Prompts and replies are not stored; only the tokens each request used are counted. |
| Offline (not signed in) | Nowhere: it stays on your computer. |
| An AI service of your own, if you connect one | To that service, under its privacy policy. |

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
| Your sign-in choice from `toolwrite login` | `%APPDATA%\toolwrite\config.toml` (Windows), `~/Library/Application Support/toolwrite/config.toml` (macOS), `~/.config/toolwrite/config.toml` (Linux) |
| Installed packages reused by `--run-checks` | your temp folder, `toolwrite-run-cache` (the 8 most recent) |
| Compiled Rust dependencies for checks | your temp folder, `toolwrite-cargo-target` |

Delete any of these whenever you like; Toolwrite recreates what it needs.

## Other network connections

Besides the model, Toolwrite connects only:

- with `--run-checks`: to the package registries your generated project uses (PyPI through pip, npm, crates.io through cargo), to install its dependencies;
- to the app it just started, on your own computer, to check it answers.

The installer downloads Toolwrite from GitHub.
