#!/usr/bin/env bash

is_test() {
  case "$1" in
    e2e/*) return 1 ;;
    *.test.js | *.test.mjs | *.test.cjs | *.test.jsx) return 0 ;;
    *.spec.js | *.spec.mjs | *.spec.cjs | *.spec.jsx) return 0 ;;
    test-*.js | test-*.mjs | test-*.cjs | test-*.jsx) return 0 ;;
    */test-*.js | */test-*.mjs | */test-*.cjs | */test-*.jsx) return 0 ;;
    *) return 1 ;;
  esac
}

is_source() {
  case "$1" in
    */*) ;;
    *) return 1 ;;
  esac
  case "$1" in
    tests/* | e2e/* | node_modules/* | dist/* | public/* | coverage/* | */node_modules/*) return 1 ;;
  esac
  is_test "$1" && return 1
  case "$1" in
    *.js | *.mjs | *.cjs | *.jsx) return 0 ;;
    *) return 1 ;;
  esac
}

twin_names() {
  local rel="$1" dir stem strip ext
  dir="${rel%/*}"
  stem="${rel##*/}"
  stem="${stem%.*}"
  strip="${rel#src/}"
  strip="${strip%.*}"
  for ext in js mjs cjs jsx; do
    printf '%s\n' "tests/$strip.test.$ext" "tests/$strip.spec.$ext" \
      "$dir/$stem.test.$ext" "$dir/$stem.spec.$ext" "$dir/test-$stem.$ext"
  done
}

test_for_source() {
  local c strip
  while IFS= read -r c; do
    if [ -f "$c" ]; then
      echo "$c"
      return
    fi
  done < <(twin_names "$1")
  strip="${1#src/}"
  echo "tests/${strip%.*}.test.js"
}

source_candidates() {
  local t="$1" dir base stem rel ext
  dir="."
  [ "${t%/*}" = "$t" ] || dir="${t%/*}"
  base="${t##*/}"
  case "$base" in
    test-*)
      stem="${base#test-}"
      stem="${stem%.*}"
      ;;
    *)
      stem="${base%.*}"
      stem="${stem%.test}"
      stem="${stem%.spec}"
      ;;
  esac
  rel="${dir#tests}"
  rel="${rel#/}"
  for ext in js mjs cjs jsx; do
    printf '%s\n' "$dir/$stem.$ext"
    if [ "$dir" = tests ] || [ "${dir#tests/}" != "$dir" ]; then
      printf '%s\n' "src/${rel:+$rel/}$stem.$ext" "${rel:+$rel/}$stem.$ext"
    fi
  done
}

source_for_test() {
  local s n
  while IFS= read -r s; do
    if [ -f "$s" ] && is_source "$s"; then
      while IFS= read -r n; do
        if [ "$n" = "$1" ]; then
          echo "$s"
          return
        fi
      done < <(twin_names "$s")
    fi
  done < <(source_candidates "$1")
  echo ""
}
