#!/usr/bin/env bash
# Sourced by bin/ci. toolchain_check <root> passes when <root> pins its
# toolchain in rust-toolchain.toml and, for a numbered channel, the active
# rustc is that version. rustup reads the same file; a channel such as
# "stable" is satisfied by whatever rustup or the system provides.

toolchain_check() {
  local root="$1" channel active
  if [ ! -f "$root/rust-toolchain.toml" ]; then
    echo "toolchain: rust-toolchain.toml is missing; pin Rust with a [toolchain] channel" >&2
    return 1
  fi
  channel="$(sed -nE 's/^[[:space:]]*channel[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$root/rust-toolchain.toml")"
  if [ -z "$channel" ]; then
    echo "toolchain: rust-toolchain.toml has no channel" >&2
    return 1
  fi
  case "$channel" in
    [0-9]*) ;;
    *) return 0 ;;
  esac
  if ! active="$(cd "$root" && rustc --version 2>/dev/null)"; then
    echo "toolchain: rustc is not installed; rust-toolchain.toml pins $channel" >&2
    return 1
  fi
  active="$(echo "$active" | cut -d' ' -f2)"
  case "$active" in
    "$channel" | "$channel".*) ;;
    *)
      echo "toolchain: rustc $active is active but rust-toolchain.toml pins $channel; install it with: rustup toolchain install $channel" >&2
      return 1
      ;;
  esac
}
