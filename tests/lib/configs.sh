#!/usr/bin/env bash

plant_ok_configs() {
  local cfg="$1"
  mkdir -p "$cfg/.cargo" "$cfg/table"
  printf '[package]\nname = "app"\n\n[lints.clippy.pedantic]\nlevel = "deny"\npriority = -1\n' >"$cfg/table/Cargo.toml"
  printf '{ "%sschema": "x", "files": { "maxSize": 2000000 }, "formatter": { "indentStyle": "space" }, "assist": { "actions": { "source": { "organizeImports": "on" } } }, "linter": { "enabled": true, "rules": { "preset": "all", "style": "error" } } }\n' "\$" >"$cfg/biome.json"
  printf '%s\n' 'import base from "@eslint/js";' '' 'export default [{ files: ["**/*.ts"], extends: [base], rules: {' \
    '  "no-console": "error", eqeqeq: "error", "@typescript-eslint/no-explicit-any": 2,' '} }];' \
    >"$cfg/eslint.config.js"
  printf 'plugins:\n  - rubocop-rails\nAllCops:\n  NewCops: enable\n  SuggestExtensions: false\nStyle/Documentation:\n  Enabled: false\nStyle/Copyright:\n  Enabled: true\n' >"$cfg/.rubocop.yml"
  printf 'max_width = 100\n' >"$cfg/rustfmt.toml"
  printf '[build]\nrustflags = ["-C", "target-cpu=native"]\n' >"$cfg/.cargo/config.toml"
  printf '#[derive(Debug)]\npub struct Probe;\n\n#[must_use]\npub fn probe() -> u8 {\n    1\n}\n' >"$cfg/probe.rs"
  printf '[package]\nname = "app"\n\n[lints.clippy]\npedantic = { level = "deny", priority = -1 }\n' >"$cfg/Cargo.toml"
  printf '[project]\nname = "app"\n\n[tool.ruff]\nline-length = 100\n\n[tool.ruff.lint]\nextend-select = ["ALL"]\n\n[tool.mypy]\npython_version = "3.12"\nplugins = ["pydantic.mypy"]\n' >"$cfg/pyproject.toml"
  printf '{ "lineLength": 100, "rules": { "AlwaysUseLowerCamelCase": true } }\n' >"$cfg/.swift-format"
  printf 'source-path=SCRIPTDIR\n' >"$cfg/.shellcheckrc"
}

plant_bad_configs() {
  local cfg="$1" repo="$2" dir mdtoken pytoken rbtoken
  for dir in files formatter assist variable shorthand member computed local package dynamic require config .cargo mypy \
    linked inline quoted levels plugin simplecov options overrides formatteroff linteroff linteropts allcops newcops \
    ruffkey; do
    mkdir -p "$cfg/$dir"
  done
  ln -s ../assist/biome.json "$cfg/linked/biome.json"
  printf '[tool]\nruff = { lint = { ignore = ["F"] } }\nmypy = { ignore_errors = true }\n' >"$cfg/inline/pyproject.toml"
  printf '[tool."ruff".lint]\n%signore%s = ["F"]\n' "'" "'" >"$cfg/quoted/pyproject.toml"
  printf '[lints]\nrust = { unsafe_code = "forbid", dead_code = "%s" }\n' allow >"$cfg/levels/Cargo.toml"
  printf '[tool.mypy]\nplugins = ["loosen"]\n' >"$cfg/plugin/pyproject.toml"
  printf 'LOOSE = 1\n' >"$cfg/plugin/loosen.py"
  printf 'SimpleCov.start do\n  minimum_coverage line: 100, branch: 100\n  skip %%w[/app/]\nend\n' >"$cfg/simplecov/test_helper.rb"
  printf 'SimpleCov.start\n' >"$cfg/.simplecov"
  rbtoken='$'
  rbtoken+='VERBOSE = nil'
  printf '%s\n' "$rbtoken" >"$repo/hush.rb"
  rbtoken='Warning[:deprecated] '
  rbtoken+='= false'
  printf '%s\n' "$rbtoken" >>"$repo/hush.rb"
  rbtoken='$'
  printf '%s\n' "$rbtoken-v = nil" "$rbtoken-w = false" >>"$repo/hush.rb"
  mkdir -p "$repo/skipmore/tests" "$repo/skipmore/test" "$repo/skipmore/ios/Tests"
  printf '%s\n' 'test.concurrent.skip("a", () => {});' 'test("b", { skip: "later" }, () => {});' >"$repo/skipmore/a.test.ts"
  printf '%s\n' 'import pytest' 'from pytest import mark' 'pytestmark = pytest.mark.skip' '' '' '@mark.xfail' 'def test_b():' \
    '    pass' '' '' 'collect_ignore = ["x.py"]' >"$repo/skipmore/tests/test_b.py"
  printf '%s\n' 'class BTest' '  def test_b' '    skip_until 2099, 1, 1, "later"' '  end' 'end' >"$repo/skipmore/test/b_test.rb"
  printf '%s\n' 'import Testing' '' '@Test(.enabled(if: false)) func b() {}' >"$repo/skipmore/ios/Tests/BTests.swift"
  printf '%s\n' 'import unittest' 'from unittest import skip' '' '' '@skip("later")' 'def test_c() -> None:' \
    '    raise unittest.SkipTest("later")' >"$repo/skipmore/tests/test_c.py"
  printf '%s\n' 'def pytest_ignore_collect(collection_path):' '    return "slow" in str(collection_path)' \
    >"$repo/skipmore/conftest.py"
  mkdir -p "$repo/skipmore/spec"
  printf '%s\n' 'xcontext "a" do' '  it "x", skip: true do' '  end' '  it "y", :focus do' '  end' 'end' \
    >"$repo/skipmore/spec/c_spec.rb"
  printf '%s\n' 'test("c", (c) => {' '  c.skip();' '});' >"$repo/skipmore/c.test.ts"
  printf 'echo %s1\n' '$' >"$repo/bin/plain.sh"
  printf 'x\n' >"$repo/sealed.txt"
  chmod 000 "$repo/sealed.txt"
  printf '{ "linter": { "enabled": true, "rules": { "preset": "all", "style": "warn" } } }\n' >"$cfg/biome.json"
  printf 'export default [{ rules: { "no-console": "error", eqeqeq: 0 } }];\n' >"$cfg/eslint.config.js"
  printf 'Style/StringLiterals:\n  EnforcedStyle: double_quotes\n' >"$cfg/.rubocop.yml"
  printf '[lints.clippy]\nall = "%s"\n' allow >"$cfg/Cargo.toml"
  printf '[tool.ruff.lint.per-file-ignores]\n"tests/*" = ["S101"]\n' >"$cfg/pyproject.toml"
  printf '{ "rules": { "AlwaysUseLowerCamelCase": false } }\n' >"$cfg/.swift-format"
  printf 'disable=SC2034\n' >"$cfg/.shellcheckrc"
  printf '{ "default": true }\n' >"$cfg/.markdownlint.json"
  printf '{}\n' >"$cfg/brakeman.ignore"
  printf 'src/\n' >"$cfg/.prettierignore"
  printf '{ "files": { "includes": ["**", "!src/legacy.js"] } }\n' >"$cfg/files/biome.json"
  printf '{ "formatter": { "includes": ["**", "!src/legacy.js"] } }\n' >"$cfg/formatter/biome.json"
  printf '{ "assist": { "enabled": false } }\n' >"$cfg/assist/biome.json"
  printf '{ "overrides": [{ "includes": ["src/**"], "linter": { "enabled": false } }] }\n' >"$cfg/overrides/biome.json"
  printf '{ "formatter": { "enabled": false } }\n' >"$cfg/formatteroff/biome.json"
  printf '{ "linter": { "enabled": false } }\n' >"$cfg/linteroff/biome.json"
  printf 'export default [{ linterOptions: { noInlineConfig: false } }];\n' >"$cfg/linteropts/eslint.config.js"
  printf 'AllCops:\n  Exclude:\n    - legacy/**/*\n' >"$cfg/allcops/.rubocop.yml"
  printf 'AllCops:\n  NewCops: disable\n' >"$cfg/newcops/.rubocop.yml"
  printf '[tool.ruff]\nexclude = ["legacy"]\n' >"$cfg/ruffkey/pyproject.toml"
  printf 'exclude = ["legacy"]\n' >"$cfg/ruff.toml"
  printf 'const strict = { "no-console": "error" };\n\nexport default [{ rules: strict }];\n' >"$cfg/variable/eslint.config.js"
  printf 'const rules = { "no-console": "error" };\n\nexport default [{ rules }];\n' >"$cfg/shorthand/eslint.config.js"
  printf 'const base = { rules: { "no-console": "error" } };\nbase.rules.eqeqeq = "error";\n\nexport default [base];\n' >"$cfg/member/eslint.config.js"
  printf 'export default [{ ["rules"]: { "no-console": "error" } }];\n' >"$cfg/computed/eslint.config.js"
  printf 'import base from "./base.js";\n\nexport default [base];\n' >"$cfg/local/eslint.config.js"
  printf 'import quiet from "eslint-config-prettier";\n\nexport default [quiet];\n' >"$cfg/package/eslint.config.js"
  printf 'const name = "x";\n\nexport default [(await import(name)).default];\n' >"$cfg/dynamic/eslint.config.js"
  printf 'export default [{ rules: { eqeqeq: ["error", "smart"] } }];\n' >"$cfg/options/eslint.config.js"
  printf 'require:\n  - ./loose.rb\n' >"$cfg/require/.rubocop.yml"
  printf -- '--except Style/StringLiterals\n' >"$cfg/.rubocop"
  printf -- '---\n:skip_checks:\n- CheckSQL\n' >"$cfg/config/brakeman.yml"
  printf 'too-many-arguments-threshold = 20\n' >"$cfg/clippy.toml"
  printf 'disable_all_formatting = true\n' >"$cfg/rustfmt.toml"
  printf '[build]\nrustflags = ["--cap-lints", "%s"]\n' allow >"$cfg/.cargo/config.toml"
  printf '%s\n' '#[cfg_attr(' '    all(),' '    allow(dead_code)' ')]' 'fn a() {}' '' '# [allow(dead_code)]' 'fn b() {}' '' \
    '#[rustfmt::skip]' 'fn c() {}' '' '#[cfg_attr(test, ignore)]' 'fn d() {}' '' '#[cfg(not(coverage))]' 'fn e() {}' '' \
    'fn f() -> bool {' '    cfg!(coverage)' '}' >"$cfg/quiet.rs"
  printf '[project]\nname = "app"\n\n[tool.mypy]\nignore_missing_imports = true\n' >"$cfg/mypy/pyproject.toml"
  printf '[mypy]\nstrict = False\n' >"$cfg/mypy.ini"
  printf '[mypy]\nignore_errors = True\n' >"$cfg/setup.cfg"
  mdtoken="markdownlint-"
  mdtoken+="configure-file"
  printf '# Configured\n\n<!-- %s {"MD018": false} -->\n' "$mdtoken" >"$repo/configured.md"
  pytoken="no_type_"
  pytoken+="check"
  printf 'from typing import %s\n' "$pytoken" >"$repo/unchecked.py"
}

check_bad_configs() {
  local msg
  for msg in "biome.json: Biome settings outside its list" \
    "eslint.config.js: sets an ESLint rule to anything but a bare error" \
    ".rubocop.yml: RuboCop settings outside its list" \
    "Cargo.toml: a lint level other than warn, deny or forbid" \
    "pyproject.toml: Ruff settings outside its list" \
    ".swift-format: turns a swift-format rule off" \
    ".shellcheckrc: holds a directive other than" \
    ".markdownlint.json: markdownlint runs with its default rules" \
    "brakeman.ignore: Brakeman ignores no warning" \
    ".prettierignore: Prettier formats every file, so it has no ignore file" \
    "files/biome.json: Biome settings outside its list" \
    "formatter/biome.json: Biome settings outside its list" \
    "assist/biome.json: Biome settings outside its list" \
    "overrides/biome.json: Biome settings outside its list" \
    "formatteroff/biome.json: Biome settings outside its list" \
    "linteroff/biome.json: Biome settings outside its list" \
    "linteropts/eslint.config.js: sets an ESLint rule to anything but a bare error" \
    "allcops/.rubocop.yml: RuboCop settings outside its list" \
    "newcops/.rubocop.yml: RuboCop settings outside its list" \
    "ruffkey/pyproject.toml: Ruff settings outside its list" \
    "ruff.toml: Ruff settings outside its list" \
    "variable/eslint.config.js: sets an ESLint rule to anything but a bare error" \
    "shorthand/eslint.config.js: sets an ESLint rule to anything but a bare error" \
    "member/eslint.config.js: sets an ESLint rule to anything but a bare error" \
    "computed/eslint.config.js: sets an ESLint rule to anything but a bare error" \
    "local/eslint.config.js: sets an ESLint rule to anything but a bare error" \
    "package/eslint.config.js: sets an ESLint rule to anything but a bare error" \
    "dynamic/eslint.config.js: sets an ESLint rule to anything but a bare error" \
    "options/eslint.config.js: sets an ESLint rule to anything but a bare error" \
    "require/.rubocop.yml: RuboCop settings outside its list" \
    ".rubocop: RuboCop takes its options from bin/lint" \
    "config/brakeman.yml: Brakeman runs with bin/lint's options" \
    "clippy.toml: Clippy runs with its default settings" \
    "rustfmt.toml: turns rustfmt off" \
    ".cargo/config.toml: sets a lint level in rustflags" \
    "quiet.rs:1: a Rust attribute or cfg! that" \
    "quiet.rs:7: a Rust attribute or cfg! that" \
    "quiet.rs:10: a Rust attribute or cfg! that" \
    "quiet.rs:13: a Rust attribute or cfg! that" \
    "quiet.rs:16: a Rust attribute or cfg! that" \
    "quiet.rs:20: a Rust attribute or cfg! that" \
    "mypy/pyproject.toml: mypy settings outside its list" \
    "mypy.ini: mypy takes its settings from [tool.mypy]" \
    "setup.cfg: mypy takes its settings from [tool.mypy]" \
    "linked/biome.json: Biome settings outside its list" \
    "inline/pyproject.toml: Ruff settings outside its list" \
    "inline/pyproject.toml: mypy settings outside its list" \
    "quoted/pyproject.toml: Ruff settings outside its list" \
    "levels/Cargo.toml: a lint level other than warn, deny or forbid" \
    "plugin/pyproject.toml: loads a mypy plugin from the app's own code" \
    "simplecov/test_helper.rb:3: leaves files out of coverage" \
    ".simplecov: SimpleCov starts in test/test_helper.rb"; do
    grep -qF "cfg/bad/$msg" "${LAST_LOG}" || die "lint configuration not checked: $msg"
  done
  for msg in "configured.md:3" "unchecked.py:1" "hush.rb:1" "hush.rb:2" "hush.rb:3" "hush.rb:4"; do
    grep -qF "$msg: suppression comment" "${LAST_LOG}" || die "a suppression was not caught: $msg"
  done
  for msg in a.test.ts:1 a.test.ts:2 tests/test_b.py:3 tests/test_b.py:6 tests/test_b.py:11 test/b_test.rb:3 \
    ios/Tests/BTests.swift:3 tests/test_c.py:5 tests/test_c.py:7 conftest.py:1 spec/c_spec.rb:1 spec/c_spec.rb:2 \
    spec/c_spec.rb:4 c.test.ts:2; do
    grep -qF "skipmore/$msg: a test that does not run" "${LAST_LOG}" || die "a test that does not run was not caught: $msg"
  done
  grep -qF "bin/plain.sh: entry point is not executable" "${LAST_LOG}" || die "a .sh file without a shebang escaped the script checks"
  grep -qF "a scan could not read every file" "${LAST_LOG}" || die "an unreadable file escaped the scans"
}
