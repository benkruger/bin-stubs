#!/usr/bin/env bash

toolchain_check() {
  local root="$1" channel active
  [ "${FLOW_CHECKED_APP:-}" != "$root" ] || return 0
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

packages_check() {
  local root="$1"
  [ "${FLOW_CHECKED_APP:-}" != "$root" ] || return 0
  if ! (cd "$root" && cargo fetch --offline --locked >/dev/null 2>&1); then
    echo "packages: crates are missing or Cargo.lock is out of date; run bin/dependencies" >&2
    return 1
  fi
}
