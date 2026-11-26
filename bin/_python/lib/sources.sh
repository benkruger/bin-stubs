#!/usr/bin/env bash

is_source() {
  case "$1" in
    tests/* | .venv/* | conftest.py) return 1 ;;
    *.py) ;;
    *) return 1 ;;
  esac
  [ ! -d src ] || [ "${1#src/}" != "$1" ]
}

needs_twin() {
  [ "$(basename "$1")" != "__init__.py" ]
}

is_test() {
  case "$1" in
    tests/test_*.py | tests/*/test_*.py | tests/*_test.py) return 0 ;;
    *) return 1 ;;
  esac
}

test_for_source() {
  local rel="$1" dir base
  if [[ "$rel" == src/* ]]; then
    rel="${rel#src/}"
  fi
  dir="$(dirname "$rel")"
  base="$(basename "$rel" .py)"
  if [ "$dir" = "." ]; then
    echo "tests/test_${base}.py"
  else
    echo "tests/${dir}/test_${base}.py"
  fi
}

source_for_test() {
  local rel="${1#tests/}" dir base
  base="$(basename "$rel")"
  case "$base" in
    test_*) base="${base#test_}" ;;
    *_test.py) base="${base%_test.py}.py" ;;
  esac
  dir="$(dirname "$rel")"
  if [ "$dir" = "." ]; then
    if [ -f "src/${base}" ]; then
      echo "src/${base}"
    else
      echo "${base}"
    fi
  else
    if [ -f "src/${dir}/${base}" ]; then
      echo "src/${dir}/${base}"
    else
      echo "${dir}/${base}"
    fi
  fi
}
