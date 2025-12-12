#!/bin/sh
set -e

OWNER="bab-sh"
REPO="babm"
BINARY="babm"

get_os() {
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
        darwin) echo "darwin" ;;
        linux) echo "linux" ;;
        *) echo "unsupported" ;;
    esac
}

get_arch() {
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) echo "x64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) echo "unsupported" ;;
    esac
}

get_latest_version() {
    curl -sSfL "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" | \
        grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'
}

hash_sha256_verify() {
    target=$1
    checksums=$2
    filename=$(basename "$target")

    want=$(grep "${filename}" "${checksums}" 2>/dev/null | cut -d ' ' -f 1)
    if [ -z "$want" ]; then
        echo "Warning: checksum not found for ${filename}"
        return 0
    fi

    if command -v sha256sum >/dev/null; then
        got=$(sha256sum "$target" | cut -d ' ' -f 1)
    elif command -v shasum >/dev/null; then
        got=$(shasum -a 256 "$target" | cut -d ' ' -f 1)
    else
        echo "Warning: no sha256 tool found, skipping verification"
        return 0
    fi

    if [ "$want" != "$got" ]; then
        echo "Checksum verification failed"
        echo "Expected: $want"
        echo "Got: $got"
        return 1
    fi
    echo "Checksum verified"
}

BINDIR="${BINDIR:-$HOME/.local/bin}"
VERSION="${1:-}"

OS=$(get_os)
ARCH=$(get_arch)

if [ "$OS" = "unsupported" ]; then
    echo "Unsupported OS: $(uname -s)"
    exit 1
fi

if [ "$ARCH" = "unsupported" ]; then
    echo "Unsupported architecture: $(uname -m)"
    exit 1
fi

if [ -z "$VERSION" ]; then
    echo "Fetching latest version..."
    VERSION=$(get_latest_version)
fi

echo "Installing ${BINARY} ${VERSION} for ${OS}/${ARCH}"

BINARY_NAME="${BINARY}-${OS}-${ARCH}"
DOWNLOAD_URL="https://github.com/${OWNER}/${REPO}/releases/download/${VERSION}/${BINARY_NAME}"
CHECKSUM_URL="https://github.com/${OWNER}/${REPO}/releases/download/${VERSION}/SHA256SUMS.txt"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "Downloading ${BINARY_NAME}..."
curl -sSfL -o "${tmpdir}/${BINARY_NAME}" "${DOWNLOAD_URL}"

echo "Downloading checksums..."
curl -sSfL -o "${tmpdir}/SHA256SUMS.txt" "${CHECKSUM_URL}" || echo "Warning: checksums not available"

if [ -f "${tmpdir}/SHA256SUMS.txt" ]; then
    hash_sha256_verify "${tmpdir}/${BINARY_NAME}" "${tmpdir}/SHA256SUMS.txt"
fi

mkdir -p "${BINDIR}"
install -m 755 "${tmpdir}/${BINARY_NAME}" "${BINDIR}/${BINARY}"

echo "Installed to ${BINDIR}/${BINARY}"

case ":${PATH}:" in
    *":${BINDIR}:"*) ;;
    *)
        echo ""
        echo "${BINDIR} is not in your PATH. Add it with:"
        echo "  export PATH=\"${BINDIR}:\$PATH\""
        ;;
esac

echo ""
echo "${BINARY} installed successfully!"
