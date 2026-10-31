# Security

Toolwrite writes code with an AI model and, if you ask it to, runs that code. This page says what Toolwrite protects you from, and what it does not.

## What Toolwrite does to keep you safe

**Nothing is written until it passes.** Every generated file is reviewed by Eunice (syntax, correctness, security, completeness, and the project contract) and checked locally (parsers, compilers where available, placeholder and secret checks). The files are then checked together as one project. A build writes all of its files or none of them.

**You see changes before they happen.** With `--apply`, Toolwrite shows every file it will create or change, with line counts, and asks first. Replaced files are backed up, and `toolwrite undo` reverses the latest build, leaving files you edited since then alone.

**Secrets stay out.** `.env` files, private keys, and credential files are never read or sent to a model (see [PRIVACY.md](PRIVACY.md)). API keys live only in environment variables, never in settings files.

**Generated code does not get your keys.** `--run-checks` removes secret-looking environment variables (`*KEY*`, `*TOKEN*`, `*SECRET*`, `*PASSWORD*`, …) from everything it starts, and gives the generated code placeholder values for the secrets it expects.

**Downloads are verified.** The installers check each release's SHA-256 checksum and refuse a file that does not match.

## Risks you should know about

**`--run-checks` runs code on your computer.** Installing a project's packages runs their install scripts, and the check starts the generated app. This happens in a scratch folder, not your project, without your secrets, and a check that hangs is stopped. But it is **not a sealed sandbox**: the code runs as you, with your user's access to files and the network. That is why it is off unless you ask for it. Use it on projects you are prepared to run, ideally in a virtual machine or container for anything sensitive.

**Generated code is a starting point.** Eunice's review and the checks catch many problems, but a model can still write code with bugs or weaknesses. Read and test what Toolwrite builds before you put it in production, especially anything handling logins, payments, or personal data.

**Your project is sent to the model you choose.** A cloud model's provider receives your request and parts of your project (see [PRIVACY.md](PRIVACY.md)). Use a model on your own computer for code that must not leave it.

**Project files can contain instructions.** Toolwrite reads parts of your project to understand it. A file written to mislead an AI ("ignore your instructions and …") could influence what the model produces. The preview before `--apply` and the review of every file are the safeguards: read the preview.

**Releases are not yet code-signed.** Windows SmartScreen and macOS Gatekeeper may warn the first time. The installer's checksum check is the safeguard until releases are signed.

## Reporting a security problem

Please report security problems **privately** to the maintainer, MygreatTuesday, on GitHub, and do not open a public issue. Include what you did, what happened, and the Toolwrite version (`toolwrite --version`). You will get an answer as soon as possible.
