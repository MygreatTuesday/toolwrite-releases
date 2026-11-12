# Security

Toolwrite writes code with an AI model and, if you ask it to, runs that code. This page says what Toolwrite protects you from, and what it does not.

## What Toolwrite does to keep you safe

**Nothing is written until it passes.** Every generated file is reviewed by Toolwrite's checks (syntax, correctness, security, completeness, and the project contract) and checked locally (parsers, compilers where available, placeholder and secret checks). The files are then checked together as one project. A build writes all of its files or none of them.

**You see changes before they happen.** With `--apply`, Toolwrite shows every file it will create or change, with line counts, and asks first. Replaced files are backed up, and `toolwrite undo` reverses the latest build, leaving files you edited since then alone.

**Secrets stay out.** `.env` files, private keys (`.pem`, `.key`, `.p12`, `.pfx`, `.p8`, `.ppk`, `.jks`, `.keystore`, SSH `id_*` keys), and credential files (`.npmrc`, `.pypirc`, `.netrc`, `.git-credentials`, `.htpasswd`, `credentials.json`) are never read or sent to a model (see [PRIVACY.md](PRIVACY.md)), and a change never rewrites them. API keys live only in environment variables, never in settings files, and their values are removed from every error message Toolwrite prints.

**Toolwrite stays inside your project.** Paths a model proposes are refused if they leave the project (`..`, absolute paths, drive letters) or point into `.git`, `node_modules`, or similar folders. Symbolic links and Windows junctions are never followed: a linked file is not read, and nothing is written through a linked folder, so a link cannot send a private key to a model or make Toolwrite write outside the project.

**Generated code does not get your keys.** `--run-checks` removes secret-looking environment variables (`*KEY*`, `*TOKEN*`, `*SECRET*`, `*PASSWORD*`, …) from everything it starts, and gives the generated code placeholder values for the secrets it expects.

**Downloads are verified.** The installers check each release's SHA-256 checksum and refuse a file that does not match.

**Dependencies are audited.** Toolwrite's Rust dependencies are checked against the OSV vulnerability database (RustSec and GitHub advisories) before a release; known issues are fixed by updating the dependency.

## Risks you should know about

**`--run-checks` runs generated code.** Installing a project's packages runs their install scripts, and the check starts the generated app.

- **With Docker running** (and the sandbox downloaded once with `toolwrite sandbox prepare`), Python and Node projects run in throwaway containers from the official `python:3.12-slim` and `node:22-slim` images. A container sees only the project's scratch copy, never your files or environment; it has **no network** while the tests and the app run (only the install step can download packages); it runs with all Linux capabilities dropped and `no-new-privileges`; and it is limited to 2 GB of memory and 512 processes. The app is checked from inside its own container, so it never listens on your computer.
- **Without Docker**, and for Rust projects, the checks run **on your computer**: in a scratch folder, not your project, without your secrets, and a check that hangs is stopped. But that is **not a sealed sandbox**: the code runs as you, with your user's access to files and the network.

That is why run checks are off unless you ask for them. `toolwrite doctor` shows where they would run; `sandbox = "docker"` under `[review]` skips them rather than run them outside Docker.

**Generated code is a starting point.** Toolwrite's reviews and checks catch many problems, but a model can still write code with bugs or weaknesses. Read and test what Toolwrite builds before you put it in production, especially anything handling logins, payments, or personal data.

**Your project is sent to the AI.** With Toolwrite Cloud, your request and the parts of your project a build needs go to the AI model services Toolwrite uses (see [PRIVACY.md](PRIVACY.md)). Offline mode sends nothing.

**Project files can contain instructions.** Toolwrite reads parts of your project to understand it. A file written to mislead an AI ("ignore your instructions and …") could influence what the model produces. The preview before `--apply` and the review of every file are the safeguards: read the preview.

**Releases are not yet code-signed.** Windows SmartScreen and macOS Gatekeeper may warn the first time. The installer's checksum check is the safeguard until releases are signed.

## Reporting a security problem

Please report security problems **privately** to the maintainer, MygreatTuesday, on GitHub, and do not open a public issue. Include what you did, what happened, and the Toolwrite version (`toolwrite --version`). You will get an answer as soon as possible.
