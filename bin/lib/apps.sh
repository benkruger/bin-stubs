#!/usr/bin/env bash

is_app_dir() {
  local d="$1" x
  [ -f "$d/package.json" ] && return 0
  [ -f "$d/Gemfile" ] && return 0
  [ -f "$d/pyproject.toml" ] && return 0
  [ -f "$d/Cargo.toml" ] && return 0
  [ -f "$d/Package.swift" ] && return 0
  for x in "$d"/*.xcodeproj "$d"/*.xcworkspace; do
    [ -e "$x" ] && return 0
  done
  [ -x "$d/test/run" ] && return 0
  return 1
}

app_language() {
  local d="$1" x
  if [ -f "$d/Gemfile" ]; then
    echo rails
  elif [ -f "$d/Cargo.toml" ]; then
    echo rust
  elif [ -f "$d/Package.swift" ]; then
    echo ios
  elif [ -f "$d/pyproject.toml" ]; then
    echo python
  elif [ -f "$d/package.json" ] && [ -f "$d/tsconfig.json" ]; then
    echo typescript
  elif [ -f "$d/package.json" ]; then
    echo javascript
  else
    for x in "$d"/*.xcodeproj "$d"/*.xcworkspace; do
      if [ -e "$x" ]; then
        echo ios
        return 0
      fi
    done
    if [ -x "$d/test/run" ]; then
      echo shell
      return 0
    fi
    return 1
  fi
}
