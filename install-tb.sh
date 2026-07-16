#!/usr/bin/env bash
set -euo pipefail

: "${TB_RELEASE_BASE_URL:?TB_RELEASE_BASE_URL is required}"
: "${TB_RELEASE_VERSION:=0.1.0}"

dotfiles="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
public_key="$dotfiles/tb/.config/tb/release-public-key.pub"
expected_key_fingerprint="d156574783264b07798ef19e4f0cd7cf617de5092d1c135bc078e47e9f5c73b6"

key_fingerprint="$(
  openssl pkey -pubin -in "$public_key" -outform DER 2>/dev/null \
    | openssl dgst -sha256
)"
if [[ "${key_fingerprint##* }" != "$expected_key_fingerprint" ]]; then
  printf 'Vendored tb release public key fingerprint mismatch\n' >&2
  exit 1
fi

case "$(uname -s)" in
  Darwin) release_os="macos" ;;
  Linux) release_os="linux" ;;
  *)
    printf 'Unsupported operating system: %s\n' "$(uname -s)" >&2
    exit 1
    ;;
esac

case "$(uname -m)" in
  arm64 | aarch64) release_arch="aarch64" ;;
  x86_64 | amd64) release_arch="x86_64" ;;
  *)
    printf 'Unsupported architecture: %s\n' "$(uname -m)" >&2
    exit 1
    ;;
esac

version="${TB_RELEASE_VERSION#v}"
name="tb-${version}-${release_os}-${release_arch}.tar.gz"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

for suffix in "" .sig .sha256; do
  curl --fail --location --proto '=https' --tlsv1.2 \
    --output "$work/${name}${suffix}" \
    "${TB_RELEASE_BASE_URL%/}/${version}/${name}${suffix}"
done

read -r expected_checksum checksum_name extra <"$work/$name.sha256"
if [[ ! "$expected_checksum" =~ ^[[:xdigit:]]{64}$ \
  || "$checksum_name" != "$name" \
  || -n "${extra:-}" ]]; then
  printf 'Invalid checksum manifest for %s\n' "$name" >&2
  exit 1
fi

actual_checksum="$(shasum -a 256 "$work/$name")"
if [[ "${actual_checksum%% *}" != "$expected_checksum" ]]; then
  printf 'Checksum mismatch for %s\n' "$name" >&2
  exit 1
fi

if ! openssl dgst -sha256 -verify "$public_key" \
  -signature "$work/$name.sig" "$work/$name" >/dev/null; then
  printf 'Signature verification failed for %s\n' "$name" >&2
  exit 1
fi

if [[ "$(tar -tzf "$work/$name")" != $'manifest\ntb' ]]; then
  printf 'Unexpected files in signed release archive %s\n' "$name" >&2
  exit 1
fi

expected_manifest="$(printf 'version=%s\nos=%s\narch=%s' \
  "$version" "$release_os" "$release_arch")"
if [[ "$(tar -xOzf "$work/$name" manifest)" != "$expected_manifest" ]]; then
  printf 'Signed release target mismatch for %s\n' "$name" >&2
  exit 1
fi

tar -xOzf "$work/$name" tb >"$work/tb"
chmod 0755 "$work/tb"
install -d "$HOME/.local/bin"
install -m 0755 "$work/tb" "$HOME/.local/bin/tb"
