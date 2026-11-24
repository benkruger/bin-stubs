#!/usr/bin/env bash

plant_ok_configs() {
  local cfg="$1"
  mkdir -p "$cfg/.cargo"
  printf '{ "%sschema": "x", "files": { "maxSize": 2000000 }, "formatter": { "indentStyle": "space" }, "assist": { "actions": { "source": { "organizeImports": "on" } } }, "linter": { "enabled": true, "rules": { "preset": "all", "style": "error" } } }\n' "\$" >"$cfg/biome.json"
  printf '%s\n' 'import base from "@eslint/js";' '' 'export default [{ files: ["**/*.ts"], extends: [base], rules: {' \
    '  "no-console": "error", eqeqeq: ["error", "always"], "@typescript-eslint/no-explicit-any": 2,' '} }];' \
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
  local cfg="$1" repo="$2" dir mdtoken pytoken
  for dir in files formatter assist variable shorthand member computed local package dynamic require config .cargo mypy; do
    mkdir -p "$cfg/$dir"
  done
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
  printf 'const strict = { "no-console": "error" };\n\nexport default [{ rules: strict }];\n' >"$cfg/variable/eslint.config.js"
  printf 'const rules = { "no-console": "error" };\n\nexport default [{ rules }];\n' >"$cfg/shorthand/eslint.config.js"
  printf 'const base = { rules: { "no-console": "error" } };\nbase.rules.eqeqeq = "error";\n\nexport default [base];\n' >"$cfg/member/eslint.config.js"
  printf 'export default [{ ["rules"]: { "no-console": "error" } }];\n' >"$cfg/computed/eslint.config.js"
  printf 'import base from "./base.js";\n\nexport default [base];\n' >"$cfg/local/eslint.config.js"
  printf 'import quiet from "eslint-config-prettier";\n\nexport default [quiet];\n' >"$cfg/package/eslint.config.js"
  printf 'const name = "x";\n\nexport default [(await import(name)).default];\n' >"$cfg/dynamic/eslint.config.js"
  printf 'require:\n  - ./loose.rb\n' >"$cfg/require/.rubocop.yml"
  printf -- '--except Style/StringLiterals\n' >"$cfg/.rubocop"
  printf -- '---\n:skip_checks:\n- CheckSQL\n' >"$cfg/config/brakeman.yml"
  printf 'too-many-arguments-threshold = 20\n' >"$cfg/clippy.toml"
  printf 'disable_all_formatting = true\n' >"$cfg/rustfmt.toml"
  printf '[build]\nrustflags = ["--cap-lints", "%s"]\n' allow >"$cfg/.cargo/config.toml"
  printf '%s\n' '#[cfg_attr(' '    all(),' '    allow(dead_code)' ')]' 'fn a() {}' '' '# [allow(dead_code)]' 'fn b() {}' '' \
    '#[rustfmt::skip]' 'fn c() {}' >"$cfg/quiet.rs"
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
    "eslint.config.js: sets an ESLint rule below error" \
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
    "variable/eslint.config.js: sets an ESLint rule below error" \
    "shorthand/eslint.config.js: sets an ESLint rule below error" \
    "member/eslint.config.js: sets an ESLint rule below error" \
    "computed/eslint.config.js: sets an ESLint rule below error" \
    "local/eslint.config.js: sets an ESLint rule below error" \
    "package/eslint.config.js: sets an ESLint rule below error" \
    "dynamic/eslint.config.js: sets an ESLint rule below error" \
    "require/.rubocop.yml: RuboCop settings outside its list" \
    ".rubocop: RuboCop takes its options from bin/lint" \
    "config/brakeman.yml: Brakeman runs with bin/lint's options" \
    "clippy.toml: Clippy runs with its default settings" \
    "rustfmt.toml: turns rustfmt off" \
    ".cargo/config.toml: sets a lint level in rustflags" \
    "quiet.rs:1: a Rust attribute that allows or expects a lint" \
    "quiet.rs:7: a Rust attribute that allows or expects a lint" \
    "quiet.rs:10: a Rust attribute that allows or expects a lint" \
    "mypy/pyproject.toml: mypy settings outside its list" \
    "mypy.ini: mypy takes its settings from [tool.mypy]" \
    "setup.cfg: mypy takes its settings from [tool.mypy]"; do
    grep -qF "cfg/bad/$msg" "${LAST_LOG}" || die "lint configuration not checked: $msg"
  done
  grep -qF "configured.md:3: suppression comment" "${LAST_LOG}" || die "an inline markdownlint config was not caught"
  grep -qF "unchecked.py:1: suppression comment" "${LAST_LOG}" || die "a function kept from mypy was not caught"
}
