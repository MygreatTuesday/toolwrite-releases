#!/bin/sh
# Toolwrite installer for macOS and Linux.
#
#   curl -fsSL https://<toolwrite-site>/install.sh | sh
#
# Downloads the newest Toolwrite release for this system (Linux x86-64,
# macOS Apple silicon or Intel), checks its SHA-256 checksum, and installs
# `toolwrite` into ~/.local/bin (no sudo needed).
#
# Settings (environment variables, all optional):
#   TOOLWRITE_VERSION   a release tag such as v0.1.0 (default: the newest)
#   TOOLWRITE_REPO      the GitHub repository with the releases
#   TOOLWRITE_INSTALL   the folder to install into
#   TOOLWRITE_BASE_URL  where the release files are (default: the release's
#                       GitHub download folder); for testing a release

set -eu

repo="${TOOLWRITE_REPO:-MygreatTuesday/toolwrite-releases}"
install_dir="${TOOLWRITE_INSTALL:-$HOME/.local/bin}"

fail() {
    printf '\nToolwrite was not installed: %s\n' "$1" >&2
    exit 1
}

need() {
    command -v "$1" >/dev/null 2>&1 || fail "this installer needs \`$1\`."
}
need curl
need tar
need uname

case "$(uname -s)-$(uname -m)" in
    Linux-x86_64 | Linux-amd64) target="x86_64-unknown-linux-gnu" ;;
    Darwin-arm64 | Darwin-aarch64) target="aarch64-apple-darwin" ;;
    Darwin-x86_64) target="x86_64-apple-darwin" ;;
    *) fail "there is no Toolwrite download for $(uname -s) $(uname -m) yet." ;;
esac

echo "Installing Toolwrite ..."
if [ -n "${TOOLWRITE_VERSION:-}" ]; then
    tag="$TOOLWRITE_VERSION"
else
    # Not /releases/latest: GitHub leaves pre-releases (betas) out of it.
    tag=$(curl -fsSL "https://api.github.com/repos/$repo/releases?per_page=1" 2>/dev/null |
        sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1) || true
    [ -n "$tag" ] || fail "could not find the newest release at github.com/$repo (check the internet connection)."
fi

name="toolwrite-$tag-$target"
base="${TOOLWRITE_BASE_URL:-https://github.com/$repo/releases/download/$tag}"
temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT INT TERM

echo "  downloading $name.tar.gz"
curl -fsSL "$base/$name.tar.gz" -o "$temp/$name.tar.gz" || fail "could not download $name.tar.gz from $base."
curl -fsSL "$base/$name.tar.gz.sha256" -o "$temp/$name.tar.gz.sha256" || fail "could not download the checksum."

expected=$(cut -d ' ' -f 1 "$temp/$name.tar.gz.sha256")
if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$temp/$name.tar.gz" | cut -d ' ' -f 1)
else
    actual=$(shasum -a 256 "$temp/$name.tar.gz" | cut -d ' ' -f 1)
fi
[ "$actual" = "$expected" ] || fail "the download is damaged or was changed (checksum $actual, expected $expected)."
echo "  checksum verified"

tar -xzf "$temp/$name.tar.gz" -C "$temp"
mkdir -p "$install_dir"
cp "$temp/$name/toolwrite" "$install_dir/toolwrite"
chmod +x "$install_dir/toolwrite"
# macOS blocks an unsigned download the first time; this copy was verified above.
if [ "$(uname -s)" = "Darwin" ]; then
    xattr -d com.apple.quarantine "$install_dir/toolwrite" 2>/dev/null || true
fi

version=$("$install_dir/toolwrite" --version)

cat <<'BANNER'

  _____ ___   ___  _     __        ______  ___ _____ _____
 |_   _/ _ \ / _ \| |    \ \      / /  _ \|_ _|_   _| ____|
   | || | | | | | | |     \ \ /\ / /| |_) || |  | | |  _|
   | || |_| | |_| | |___   \ V  V / |  _ < | |  | | | |___
   |_| \___/ \___/|_____|   \_/\_/  |_| \_\___| |_| |_____|

        /\        Treehouse plans. Betty and Eugenia build.
       /  \       Eunice checks every file before you get it.
      /\  /\
     /  \/  \
        ||

BANNER
echo "Installed $version to $install_dir"

case ":$PATH:" in
    *":$install_dir:"*) ;;
    *)
        echo ""
        echo "Add Toolwrite to your PATH by adding this line to ~/.zshrc or ~/.bashrc:"
        echo "  export PATH=\"$install_dir:\$PATH\""
        ;;
esac

echo ""
echo "Next:"
echo "  toolwrite setup          choose your AI model (once)"
echo "  toolwrite \"Create a landing page for a bakery\""
