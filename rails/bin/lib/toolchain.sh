#!/usr/bin/env bash
# Sourced by bin/ci. toolchain_check <root> passes when the Ruby active in
# <root> is the version pinned in <root>/.ruby-version (rbenv, chruby and
# asdf all read that file), and explains the fix otherwise.

toolchain_check() {
  local root="$1" pinned active
  if [ ! -f "$root/.ruby-version" ]; then
    echo "toolchain: .ruby-version is missing; pin Ruby with: ruby -e 'print RUBY_VERSION' > .ruby-version" >&2
    return 1
  fi
  pinned="$(tr -d '[:space:]' <"$root/.ruby-version")"
  pinned="${pinned#ruby-}"
  if ! active="$(cd "$root" && ruby -e 'print RUBY_VERSION' 2>/dev/null)"; then
    echo "toolchain: Ruby $pinned from .ruby-version is not installed; install it with: rbenv install $pinned" >&2
    return 1
  fi
  if [ "$active" != "$pinned" ]; then
    echo "toolchain: Ruby $active is active but .ruby-version pins $pinned; install it with: rbenv install $pinned" >&2
    return 1
  fi
}
