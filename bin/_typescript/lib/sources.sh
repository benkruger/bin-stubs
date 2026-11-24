#!/usr/bin/env bash

is_test() {
  case "$1" in
    tests/*.test.ts | tests/*.test.tsx | tests/*.test.mts | tests/*.test.cts) return 0 ;;
    *) return 1 ;;
  esac
}

is_source() {
  case "$1" in
    */*) ;;
    *) return 1 ;;
  esac
  case "$1" in
    tests/* | node_modules/* | dist/* | public/* | coverage/* | */node_modules/*) return 1 ;;
    *.d.ts | *.d.mts | *.d.cts) return 1 ;;
    *.test.ts | *.test.tsx | *.test.mts | *.test.cts) return 1 ;;
    *.spec.ts | *.spec.tsx | *.spec.mts | *.spec.cts) return 1 ;;
    *.ts | *.tsx | *.mts | *.cts) return 0 ;;
    *) return 1 ;;
  esac
}

test_for_source() {
  local rel="${1#src/}" ext
  rel="${rel%.*}"
  for ext in ts tsx mts cts; do
    if [ -f "tests/${rel}.test.${ext}" ]; then
      echo "tests/${rel}.test.${ext}"
      return
    fi
  done
  echo "tests/${rel}.test.${1##*.}"
}

source_for_test() {
  local rel="${1#tests/}" base ext
  rel="${rel%.test.*}"
  for base in "src/${rel}" "${rel}"; do
    for ext in tsx mts cts ts; do
      if [ -f "${base}.${ext}" ] && is_source "${base}.${ext}"; then
        echo "${base}.${ext}"
        return
      fi
    done
  done
  echo "src/${rel}.ts"
}
