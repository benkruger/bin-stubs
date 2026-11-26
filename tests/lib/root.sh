#!/usr/bin/env bash

root_rust() {
  local app="$1" tool_body='pub fn tool() -> i32 { return  "text"; }'
  seed_of rust "$app"
  printf '\n[workspace]\nmembers = ["member"]\nexclude = ["tool"]\n' >>"$app/Cargo.toml"
  mkdir -p "$app/member/src" "$app/tool/src"
  printf '[package]\nname = "%s"\nversion = "0.1.0"\nedition = "2021"\n' member >"$app/member/Cargo.toml"
  printf '[package]\nname = "%s"\nversion = "0.1.0"\nedition = "2021"\n' tool >"$app/tool/Cargo.toml"
  printf 'pub fn member() -> i32 {\n    1\n}\n' >"$app/member/src/lib.rs"
  printf '%s\n' "$tool_body" >"$app/tool/src/lib.rs"
  expect_ok leaf "$app" rust dependencies
  expect_ok leaf "$app" rust format --all
  [ "$(cat "$app/tool/src/lib.rs")" = "$tool_body" ] || die "a root rust app's format rewrote a sibling app's file"
  expect_ok leaf "$app" rust format --check --all
  expect_ok leaf "$app" rust lint --all
  expect_ok leaf "$app" rust build --all
  printf 'pub fn member() -> i32 { 1 }\n' >"$app/member/src/lib.rs"
  expect_fail leaf "$app" rust format --check --all
  grep -q "member/src/lib.rs" "${LAST_LOG}" || die "a root rust app's format skipped its workspace member"
  printf 'pub fn member() -> i32 {\n    return 1;\n}\n' >"$app/member/src/lib.rs"
  expect_fail leaf "$app" rust lint --all
  grep -q "member/src/lib.rs" "${LAST_LOG}" || die "a root rust app's lint skipped its workspace member"
  grep -q "tool/src/lib.rs" "${LAST_LOG}" && die "a root rust app's lint checked a sibling app's file"
  printf 'pub fn member() -> i32 {\n    "text"\n}\n' >"$app/member/src/lib.rs"
  expect_fail leaf "$app" rust build --all
  grep -q "member/src/lib.rs" "${LAST_LOG}" || die "a root rust app's build skipped its workspace member"
  grep -q "tool/src/lib.rs" "${LAST_LOG}" && die "a root rust app's build checked a sibling app's file"
  return 0
}

root_section() {
  local lang="$1" repo app own ext loose lint_body build_body
  repo="$(new_repo)"
  keep "$repo"
  app="$repo"
  copy_dir "$HERE/../bin" "$repo/bin"
  if [ "$lang" = rust ]; then
    root_rust "$app"
    return 0
  fi
  case "$lang" in
    typescript | javascript)
      cp -cR "$TEMPLATE/$lang/." "$app" 2>/dev/null || cp -R "$TEMPLATE/$lang/." "$app"
      [ ! -L "$app/node_modules/picomatch" ] || ln -sfn "$PICOMATCH_DIR" "$app/node_modules/picomatch"
      ;;
    rails)
      cp "$repo/.gitignore" "$WORK/root.gitignore"
      seed_of "$lang" "$app"
      cat "$WORK/root.gitignore" >>"$app/.gitignore"
      cp "$TEMPLATE/$lang/Gemfile.lock" "$app/Gemfile.lock"
      ;;
    python)
      seed_of "$lang" "$app"
      expect_ok leaf "$app" "$lang" dependencies
      ;;
    *) seed_of "$lang" "$app" ;;
  esac
  build_body=""
  case "$lang" in
    typescript | javascript)
      own=src ext=ts loose='export const loose = {a:1}' lint_body=$'const unused = 1;\nexport const kept = 2;'
      build_body='export const wrong: number = "text";'
      if [ "$lang" = javascript ]; then
        ext=js build_body='export const broken = (;'
      fi
      ;;
    python) own=src ext=py loose='x=1' lint_body='import os' build_body=$'def untyped(a):\n    return a' ;;
    rails) own=app/models ext=rb loose='loose = 1' lint_body='loose = 1' build_body=$'class Wrong\nend' ;;
    ios)
      own=Sources/App ext=swift loose='let  spaced=1' lint_body='let Bad_Name = 1'
      build_body='let wrong: Int = "text"'
      ;;
  esac
  mkdir -p "$app/web"
  printf '{ "name": "web", "private": true }\n' >"$app/web/package.json"
  printf '%s\n' "$loose" >"$app/web/loose.$ext"
  printf '%s\n' "$lint_body" >"$app/web/lint.$ext"
  [ -z "$build_body" ] || printf '%s\n' "$build_body" >"$app/web/build.$ext"
  printf '%s\n' '#Loose' >"$app/web/loose.md"
  if [ "$lang" = typescript ]; then
    mkdir -p "$app/node_modules/@types/plant"
    printf 'declare const plantGlobal: number;\n' >"$app/node_modules/@types/plant/index.d.ts"
    jq '.compilerOptions.types = ["plant"]' "$app/tsconfig.json" >"$WORK/tsconfig.plant"
    mv "$WORK/tsconfig.plant" "$app/tsconfig.json"
  fi
  run_log leaf "$app" "$lang" changed --files
  assert_rc 0 "a root $lang app's changed --files"
  grep -qxF "$(source_of "$lang")" "${LAST_LOG}" || die "a root $lang app's changed left out its own file"
  grep -q "^web/" "${LAST_LOG}" && die "a root $lang app's changed listed a sibling app's file"
  expect_ok leaf "$app" "$lang" format --all
  [ "$(cat "$app/web/loose.$ext")" = "$loose" ] || die "a root $lang app's format rewrote a sibling app's file"
  expect_ok leaf "$app" "$lang" format --check --all
  expect_ok leaf "$app" "$lang" lint --all
  if [ -n "$build_body" ]; then
    expect_ok leaf "$app" "$lang" build --all
    printf '%s\n' "$build_body" >"$app/$own/build.$ext"
    expect_fail leaf "$app" "$lang" build --all
    grep -qE "(^|[ /])$own/build.$ext" "${LAST_LOG}" || die "a root $lang app's build skipped its own file"
    grep -q "web/build" "${LAST_LOG}" && die "a root $lang app's build checked a sibling app's file"
    rm "$app/$own/build.$ext"
  fi
  case "$lang" in
    typescript | javascript)
      mkdir -p "$app/web/tests"
      printf 'throw new Error("a nested app test ran in the root app");\n' >"$app/web/tests/fail.test.$ext"
      expect_ok leaf "$app" "$lang" test --all
      grep -qxF "bin/test: coverage bar held on 1 source(s)" "${LAST_LOG}" || die "a root $lang app's test did not hold its own source"
      rm -r "$app/web/tests"
      ;;
  esac
  printf '%s\n' "$lint_body" >"$app/$own/lint.$ext"
  expect_fail leaf "$app" "$lang" lint --all
  grep -q "$own/lint.$ext" "${LAST_LOG}" || die "a root $lang app's lint skipped its own file"
  grep -q "web/lint" "${LAST_LOG}" && die "a root $lang app's lint checked a sibling app's file"
  return 0
}
