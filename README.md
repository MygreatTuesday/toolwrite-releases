# Toolwrite: a guide for testers

Thank you for testing Toolwrite before everyone else. This is a test version for a small group of people we trust. It will have rough edges, and finding them is exactly why you are here. Testing is free until Toolwrite opens on 1 January 2027.

**What Toolwrite does:** you describe a piece of software in plain words, and it builds it: it plans the files, writes the code, checks every file, and, if you ask, installs the project, runs its tests, and starts it, before handing anything over. It can also change a project you already have, showing you every change first.

## 1. Before you start

You need:

- **Windows 10 or 11**, 64-bit. (macOS and Linux test builds come later.)
- **A free Toolwrite account**, at toolwrite.dev. Toolwrite runs on its own AI, Toolwrite Cloud: there is no other account to open and nothing to choose.
- For testing apps with `--run-checks` (recommended): **Python 3** and/or **Node.js** installed, for Python and JavaScript projects.

## 2. Install and sign in (2 minutes)

Open **PowerShell** normally (not as administrator) and paste:

```powershell
irm https://raw.githubusercontent.com/MygreatTuesday/toolwrite-releases/main/install.ps1 | iex
```

You will see the **TOOLWRITE** banner when it is done. Open a **new** PowerShell window, then sign in once:

```powershell
toolwrite login
```

It shows where to create your key (on your dashboard at toolwrite.dev) and how to save it on your computer, hidden while you paste it. Open a new window again, and check that everything is ready:

```powershell
toolwrite doctor --online
```

> **Windows SmartScreen** may warn the first time you run Toolwrite, because this test version is not signed yet. Click **More info → Run anyway**. The installer has already checked that the download is exactly the published one.

## 3. Things to try (pick a few)

Make a **folder** for each test and go into it (for example `mkdir $HOME\test1; cd $HOME\test1`). Always start with the word `toolwrite`; quotes are optional. Then try:

1. **A website:**
   `toolwrite Create a landing page for a hair salon in Accra with prices, opening hours, and a booking form`
   Then open `output\index.html` in your browser.
2. **An API, tested for real:**
   `toolwrite --run-checks Build a FastAPI API for a library with books and authors, with search by author`
3. **An app:**
   `toolwrite --run-checks Build a React app for a shopping list where I can tick items off`
   Then `cd output`, `npm install`, `npm run dev`, and open the address it shows.
4. **A change to something it built:** go into the `output` folder of test 1 and run
   `toolwrite --apply Add a section with three customer reviews`
   Look at the list of changes it shows before saying yes. Then try `toolwrite undo`.
5. **Your own idea**, or **a project you already have** (use `--apply`, read the preview, and keep a copy first: this is a test version).
6. **A question:** `toolwrite ask How do I add a contact page?`

If your request leaves something out, Toolwrite asks a few short questions first (press Enter to keep its suggestion), and it always shows its plan and asks **Build it?** before it writes anything. `toolwrite` on its own opens a chat-like shell; type `/help` there.

## 4. What we would love to hear

For every test, even the ones that worked:

- **What you asked for** (the exact sentence).
- **What happened:** worked, failed, or "worked but looks wrong". A screenshot of the terminal helps a lot.
- **How long it took**, roughly.
- **Anything confusing**: a message you did not understand, a step you did not know how to do.
- For problems, the version: `toolwrite --version`.

**Where to report:** open an issue at <https://github.com/MygreatTuesday/toolwrite-releases/issues> (one issue per problem), or send it to the person who invited you. Never send passwords or keys.

## 5. Known limitations

- **Windows first.** macOS and Linux come later.
- **The internet matters.** Toolwrite's AI is in Toolwrite Cloud and, with `--run-checks`, packages are downloaded. On a slow or unsteady connection a build can take several minutes, and a dropped connection stops it with a message saying so. Try again when the connection is back; packages downloaded once are reused.
- **AI answers vary.** The same request can work one time and need a second try another time.
- **Review what it builds** before using it for anything important, especially logins, payments, or personal data.
- **`--run-checks` runs the generated code on your computer** (in a temporary folder, without your passwords or keys), or in a locked-down container when Docker is running. Only use it for projects you are happy to run.
- Best results so far: websites, React apps, and APIs in Python (FastAPI, Flask), JavaScript (Express), Rust (Axum), and Go.

## 6. Privacy in short

Your request and the parts of your project a build needs go through Toolwrite Cloud to the AI model services we use; your prompts and the replies are not stored. Toolwrite never reads `.env` files, passwords, or keys, and sends no usage data anywhere. Details: [PRIVACY.md](PRIVACY.md).

## 7. Removing Toolwrite

Delete the folder `%LOCALAPPDATA%\Programs\toolwrite`, and remove it from your PATH (Settings → System → About → Advanced system settings → Environment Variables → Path). Your settings are in `%APPDATA%\toolwrite`.

Thank you. Every problem you find is one a future user will not.
