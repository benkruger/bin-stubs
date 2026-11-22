#!/usr/bin/env bash

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

packages_check() {
  local root="$1"
  if ! (cd "$root" && bundle check >/dev/null 2>&1); then
    echo "packages: gems are missing; run bin/dependencies" >&2
    return 1
  fi
}
