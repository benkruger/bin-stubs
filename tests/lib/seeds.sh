#!/usr/bin/env bash

leaf() {
  local app="$1" lang="$2" script="$3"
  shift 3
  (cd "$app" && APP_DIR="$app" "$(git -C "$app" rev-parse --show-toplevel)/bin/_$lang/$script" "$@")
}

fixed_picomatch() {
  local dir="${PICOMATCH_DIR:-$WORK/picomatch}"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    (cd "$dir/.." && npm pack picomatch@4.0.7 --silent >/dev/null)
    tar -xzf "$dir/../picomatch-4.0.7.tgz" -C "$dir" --strip-components=1
    patch -s -p1 -d "$dir" -i "$HERE/picomatch-ghsa-fc5q-39xc-vjpf.patch"
  fi
  printf '%s\n' "$dir"
}

seed_typescript() {
  local app="$1"
  mkdir -p "$app"
  node --version | sed 's/^v//' >"$app/.nvmrc"
  mkdir -p "$app/src" "$app/tests"
  cat >"$app/package.json" <<'EOF'
{
  "name": "app",
  "private": true,
  "type": "module",
  "devDependencies": {
    "@eslint/js": "latest",
    "@eslint/json": "latest",
    "@vitest/coverage-v8": "latest",
    "eslint": "latest",
    "prettier": "latest",
    "typescript": "~6.0.0",
    "typescript-eslint": "latest",
    "vitest": "latest"
  },
  "overrides": {
    "minimatch": "latest"
  }
}
EOF
  (cd "$app" && npm pkg set "packageManager=npm@$(npm --version)")
  (cd "$app" && npm pkg set "overrides.picomatch=file:$(fixed_picomatch)")
  cat >"$app/eslint.config.js" <<'EOF'
import js from "@eslint/js";
import json from "@eslint/json";
import { defineConfig } from "eslint/config";
import tseslint from "typescript-eslint";

export default defineConfig([
  {
    files: ["**/*.ts", "**/*.tsx"],
    extends: [js.configs.recommended, tseslint.configs.recommended],
  },
  {
    files: ["**/*.js"],
    extends: [js.configs.recommended],
  },
  {
    files: ["**/*.json"],
    plugins: { json },
    language: "json/json",
    extends: ["json/recommended"],
  },
]);
EOF
  cat >"$app/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "strict": true,
    "noEmit": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "target": "esnext",
    "skipLibCheck": true,
    "jsx": "react-jsx",
    "types": []
  }
}
EOF
  printf '# App\n' >"$app/README.md"
  cat >"$app/src/add.ts" <<'EOF'
export function add(a: number, b: number): number {
return a+b
}
EOF
  cat >"$app/tests/add.test.ts" <<'EOF'
import { expect, test } from "vitest";
import { add } from "../src/add";

test("add", () => {
  expect(add(1, 2)).toBe(3);
});
EOF
}

seed_javascript() {
  local app="$1"
  mkdir -p "$app"
  node --version | sed 's/^v//' >"$app/.nvmrc"
  mkdir -p "$app/src" "$app/tests"
  cat >"$app/package.json" <<'EOF'
{
  "name": "app",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test"
  },
  "devDependencies": {
    "@biomejs/biome": "latest",
    "c8": "latest"
  },
  "overrides": {
    "glob": "latest",
    "minimatch": "latest"
  }
}
EOF
  (cd "$app" && npm pkg set "packageManager=npm@$(npm --version)")
  printf '%s\n' '{' '  "formatter": {' '    "indentStyle": "space"' '  }' '}' >"$app/biome.json"
  printf '# App\n' >"$app/README.md"
  cat >"$app/src/index.js" <<'EOF'
export function add(a, b) {
return a+b
}
EOF
  cat >"$app/tests/index.test.js" <<'EOF'
import assert from "node:assert/strict";
import test from "node:test";
import { add } from "../src/index.js";

test("add", () => {
  assert.equal(add(1, 2), 3);
});
EOF
}

seed_python() {
  local app="$1" python
  mkdir -p "$app"
  python="$(cd "$app" && uv python find)"
  "$python" -c 'import sys; print("%d.%d" % sys.version_info[:2])' >"$app/.python-version"
  mkdir -p "$app/src" "$app/tests"
  cat >"$app/pyproject.toml" <<'EOF'
[project]
name = "app"
version = "0.1.0"
requires-python = ">=3.12"

[dependency-groups]
dev = ["ruff>=0.8", "mypy>=2.4", "pytest>=8", "pytest-cov>=6"]

[tool.uv]
default-groups = ["dev"]

[tool.pytest.ini_options]
pythonpath = ["src"]
EOF
  cat >"$app/src/add.py" <<'EOF'
def add(a: int, b: int) -> int:
    return a+b
EOF
  cat >"$app/tests/test_add.py" <<'EOF'
from add import add


def test_add() -> None:
    assert add(1, 2) == 3
EOF
}

seed_rails() {
  local app="$1"
  mkdir -p "$app"
  (cd "$app" && ruby -e 'print RUBY_VERSION') >"$app/.ruby-version"
  mkdir -p "$app/app/models" "$app/bin" "$app/config" "$app/test/models"
  printf '# App\n' >"$app/README.md"
  cat >"$app/.gitignore" <<'EOF'
/coverage/
/log/
/tmp/
EOF
  cat >"$app/Gemfile" <<'EOF'
# frozen_string_literal: true

source 'https://rubygems.org'

gem 'brakeman'
gem 'bundler-audit'
gem 'minitest'
gem 'railties'
gem 'rubocop'
gem 'simplecov'
EOF
  cat >"$app/.rubocop.yml" <<'EOF'
AllCops:
  NewCops: enable
  SuggestExtensions: false
Style/Documentation:
  Enabled: false
EOF
  cat >"$app/Rakefile" <<'EOF'
# frozen_string_literal: true

require_relative 'config/application'
Rails.application.load_tasks
EOF
  cat >"$app/bin/rails" <<'EOF'
#!/usr/bin/env ruby
# frozen_string_literal: true

APP_PATH = File.expand_path('../config/application', __dir__)
require_relative '../config/boot'
require 'rails/commands'
EOF
  chmod +x "$app/bin/rails"
  cat >"$app/config/boot.rb" <<'EOF'
# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'bundler/setup'
EOF
  cat >"$app/config/application.rb" <<'EOF'
# frozen_string_literal: true

require_relative 'boot'
require 'rails'
require 'action_controller/railtie'

module Fixture
  class Application < Rails::Application
    config.load_defaults 8.1
    config.eager_load = false
  end
end
EOF
  cat >"$app/config/environment.rb" <<'EOF'
# frozen_string_literal: true

require_relative 'application'
Rails.application.initialize!
EOF
  cat >"$app/app/models/add.rb" <<'EOF'
# frozen_string_literal: true

module Add
  module_function

  def call(left, right)
    left+right
  end
end
EOF
  cat >"$app/test/test_helper.rb" <<'EOF'
# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100
end

require_relative '../config/environment'
require 'rails/test_help'
EOF
  cat >"$app/test/models/add_test.rb" <<'EOF'
# frozen_string_literal: true

require 'test_helper'

class AddTest < ActiveSupport::TestCase
  test 'adds two numbers' do
    assert_equal 3, Add.call(1, 2)
  end
end
EOF
}

seed_rust() {
  local app="$1"
  mkdir -p "$app"
  printf '[toolchain]\nchannel = "%s"\ncomponents = ["llvm-tools-preview"]\n' "$(rustc --version | cut -d' ' -f2)" >"$app/rust-toolchain.toml"
  mkdir -p "$app/src"
  cat >"$app/Cargo.toml" <<'EOF'
[package]
name = "app"
version = "0.1.0"
edition = "2021"
EOF
  cat >"$app/src/lib.rs" <<'EOF'
pub fn add(a: i32, b: i32) -> i32 { a+b }

#[cfg(test)]
mod tests {
    use super::add;

    #[test]
    fn adds() {
        assert_eq!(add(1, 2), 3);
    }
}
EOF
}

seed_ios() {
  local app="$1"
  mkdir -p "$app"
  xcodebuild -version | awk 'NR == 1 { print $2 }' >"$app/.xcode-version"
  mkdir -p "$app/Sources/App" "$app/Tests/AppTests"
  cat >"$app/Package.swift" <<'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "App",
    targets: [
        .target(name: "App"),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
EOF
  cat >"$app/Sources/App/Add.swift" <<'EOF'
public func add(_ a: Int, _ b: Int) -> Int { a+b }
EOF
  cat >"$app/Tests/AppTests/AddTests.swift" <<'EOF'
import Testing
@testable import App

@Test func adds() {
    #expect(add(1, 2) == 3)
}
EOF
}

seed_shell() {
  local app="$1"
  mkdir -p "$app/test"
  cat >"$app/add" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
a="$1"
b="$2"
echo "$((a+b))"
EOF
  cat >"$app/test/run" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for check in "$here"/*; do
  [ "$check" = "$here/run" ] || "$check"
done
EOF
  cat >"$app/test/add" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ "$("$here/../add" 1 2)" = 3 ]
EOF
  chmod +x "$app/add" "$app/test/run" "$app/test/add"
}

source_of() {
  case "$1" in
    typescript) printf '%s\n' src/add.ts ;;
    javascript) printf '%s\n' src/index.js ;;
    python) printf '%s\n' src/add.py ;;
    rails) printf '%s\n' app/models/add.rb ;;
    rust) printf '%s\n' src/lib.rs ;;
    ios) printf '%s\n' Sources/App/Add.swift ;;
    shell) printf '%s\n' add ;;
  esac
}

formatted() {
  local want="a + b"
  [ "$2" = "rails" ] && want="left + right"
  grep -q "$want" "$1/$(source_of "$2")"
}

unformat() {
  local file
  file="$1/$(source_of "$2")"
  sed 's/ + /+/g' "$file" >"$file.raw"
  cat "$file.raw" >"$file"
  rm "$file.raw"
}

seed_of() {
  case "$1" in
    typescript) seed_typescript "$2" ;;
    javascript) seed_javascript "$2" ;;
    python) seed_python "$2" ;;
    rails) seed_rails "$2" ;;
    rust) seed_rust "$2" ;;
    ios) seed_ios "$2" ;;
    shell) seed_shell "$2" ;;
  esac
}

red_file() {
  local app="$1" lang="$2"
  case "$lang" in
    typescript)
      cat >"$app/tests/red.test.ts" <<'EOF'
import { expect, test } from "vitest";

test("red", () => {
  expect(1).toBe(0);
});
EOF
      ;;
    javascript)
      cat >"$app/tests/red.test.js" <<'EOF'
import assert from "node:assert/strict";
import test from "node:test";

test("red", () => {
  assert.equal(1, 0);
});
EOF
      ;;
    python)
      cat >"$app/tests/test_red.py" <<'EOF'
def test_red() -> None:
    assert str(1) == "0"
EOF
      ;;
    rails)
      cat >"$app/test/red_test.rb" <<'EOF'
# frozen_string_literal: true

require 'test_helper'

class RedTest < ActiveSupport::TestCase
  test 'fails' do
    assert_equal 1, 0
  end
end
EOF
      ;;
    rust)
      mkdir -p "$app/tests"
      cat >"$app/tests/red.rs" <<'EOF'
#[test]
fn red() {
    assert_eq!(1, 0);
}
EOF
      ;;
    ios)
      cat >"$app/Tests/AppTests/RedTests.swift" <<'EOF'
import Testing

@Test func red() {
  #expect(1 == 0)
}
EOF
      ;;
    shell)
      printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'exit 1' >"$app/test/red"
      chmod +x "$app/test/red"
      ;;
  esac
}

orphan_file() {
  local app="$1" lang="$2"
  case "$lang" in
    typescript)
      printf '%s\n' 'import { expect, test } from "vitest";' '' 'test("orphan", () => {' \
        '  expect(1).toBe(1);' '});' >"$app/tests/orphan.test.ts"
      ;;
    javascript)
      printf '%s\n' 'import assert from "node:assert/strict";' 'import test from "node:test";' '' \
        'test("orphan", () => {' '  assert.equal(1, 1);' '});' >"$app/tests/orphan.test.js"
      ;;
    python)
      printf '%s\n' 'def test_orphan() -> None:' '    assert str(1) == "1"' >"$app/tests/test_orphan.py"
      ;;
    rails)
      printf '%s\n' '# frozen_string_literal: true' '' "require 'test_helper'" '' \
        'class OrphanTest < ActiveSupport::TestCase' "  test 'passes' do" '    assert true' \
        '  end' 'end' >"$app/test/orphan_test.rb"
      ;;
    *) return 1 ;;
  esac
}

twinless() {
  local app="$1" lang="$2" src twin body
  case "$lang" in
    typescript)
      src=src/extra.ts twin=tests/extra.test.ts
      body=$'export function extra(): number {\n  return 1;\n}'
      ;;
    javascript)
      src=src/extra.js twin=tests/extra.test.js
      body=$'export function extra() {\n  return 1;\n}'
      ;;
    python)
      src=src/extra.py twin=tests/test_extra.py
      body=$'def extra() -> int:\n    return 1'
      ;;
    rails)
      src=app/models/extra.rb twin=test/models/extra_test.rb
      body=$'# frozen_string_literal: true\n\nmodule Extra\n  def self.call\n    1\n  end\nend'
      ;;
    *) return 0 ;;
  esac
  printf '%s\n' "$body" >"$app/$src"
  expect_fail leaf "$app" "$lang" changed
  grep -qxF "bin/changed: no mirrored test for $src → $twin" "${LAST_LOG}" || die "$lang changed let a source with no test through"
  expect_fail leaf "$app" "$lang" test "$src"
  grep -qxF "bin/test: no mirrored test for $src → $twin" "${LAST_LOG}" || die "$lang test ran a source with no test"
  rm "$app/$src"
}

changed_scope() {
  local app="$1" lang="$2" src spec idle more half twin half_body twin_body gap
  src="$(source_of "$lang")"
  case "$lang" in
    typescript)
      spec=tests/add.test.ts
      idle=$'import { expect, test } from "vitest";\n\ntest("idle", () => {\n  expect(1).toBe(1);\n});'
      more=$'\ntest("adds again", () => {\n  expect(add(2, 2)).toBe(4);\n});'
      half=src/half.ts twin=tests/half.test.ts
      half_body=$'export function half(n: number): number {\n  return n > 0 ? n / 2 : 0;\n}'
      twin_body=$'import { expect, test } from "vitest";\nimport { half } from "../src/half";\n\ntest("half", () => {\n  expect(half(4)).toBe(2);\n});'
      gap="src/half.ts at "
      ;;
    javascript)
      spec=tests/index.test.js
      idle=$'import assert from "node:assert/strict";\nimport test from "node:test";\n\ntest("idle", () => {\n  assert.equal(1, 1);\n});'
      more=$'\ntest("adds again", () => {\n  assert.equal(add(2, 2), 4);\n});'
      half=src/half.js twin=tests/half.test.js
      half_body=$'export function half(n) {\n  return n > 0 ? n / 2 : 0;\n}'
      twin_body=$'import assert from "node:assert/strict";\nimport test from "node:test";\nimport { half } from "../src/half.js";\n\ntest("half", () => {\n  assert.equal(half(4), 2);\n});'
      gap="src/half.js at "
      ;;
    python)
      spec=tests/test_add.py
      idle=$'def test_idle() -> None:\n    assert str(1) == "1"'
      more=$'\n\ndef test_adds_again() -> None:\n    assert add(2, 2) == 4'
      half=src/half.py twin=tests/test_half.py
      half_body=$'def half(n: int) -> float:\n    if n > 0:\n        return n / 2\n    return 0.0'
      twin_body=$'from half import half\n\n\ndef test_half() -> None:\n    assert half(4) == 2'
      gap="src/half.py at "
      ;;
    rails)
      spec=test/models/add_test.rb
      idle=$'# frozen_string_literal: true\n\nrequire \x27test_helper\x27\n\nclass AddTest < ActiveSupport::TestCase\n  test \x27idles\x27 do\n    assert true\n  end\nend'
      more=''
      half=app/models/half.rb twin=test/models/half_test.rb
      half_body=$'# frozen_string_literal: true\n\nmodule Half\n  module_function\n\n  def call(number)\n    return 0 unless number.positive?\n\n    number / 2\n  end\nend'
      twin_body=$'# frozen_string_literal: true\n\nrequire \x27test_helper\x27\n\nclass HalfTest < ActiveSupport::TestCase\n  test \x27halves\x27 do\n    assert_equal 2, Half.call(4)\n  end\nend'
      gap="coverage"
      ;;
    *) return 0 ;;
  esac
  cp "$app/$spec" "$WORK/scope.keep"
  printf '%s\n' "$idle" >"$app/$spec"
  expect_fail leaf "$app" "$lang" changed
  grep -qF "$src" "${LAST_LOG}" || die "$lang changed let a changed test drop its source below the bar"
  cp "$WORK/scope.keep" "$app/$spec"
  printf '%s\n' "$half_body" >"$app/$half"
  printf '%s\n' "$twin_body" >"$app/$twin"
  git -C "$app" add -- "$half" "$twin"
  git -C "$app" commit -q -m "a source below the bar"
  if [ -n "$more" ]; then
    printf '%s\n' "$more" >>"$app/$spec"
  else
    perl -0pi -e "s/(\n  end\nend\n)\z/\n  end\n\n  test 'adds again' do\n    assert_equal 4, Add.call(2, 2)\n  end\nend\n/" "$app/$spec"
  fi
  expect_ok leaf "$app" "$lang" changed
  cp "$WORK/scope.keep" "$app/$spec"
  printf '%s\n' "$half_body" "" >"$app/$half"
  expect_fail leaf "$app" "$lang" changed
  grep -qF "$gap" "${LAST_LOG}" || die "$lang changed passed an edited source below the bar"
  git -C "$app" rm -qf -- "$half" "$twin"
  git -C "$app" commit -q -m "the source below the bar goes"
}

sourceless() {
  local app="$1" lang="$2" src spec check body
  src="$(source_of "$lang")"
  case "$lang" in
    typescript)
      spec=tests/add.test.ts check=check.spec.ts
      body=$'import { expect, test } from "vitest";\n\ntest("check", () => {\n  expect(1).toBe(1);\n});'
      ;;
    javascript)
      spec=tests/index.test.js check=check_test.js
      body=$'import assert from "node:assert/strict";\nimport test from "node:test";\n\ntest("check", () => {\n  assert.equal(1, 1);\n});'
      ;;
    python)
      spec=tests/test_add.py check=tests/check_test.py
      body=$'def test_check() -> None:\n    assert str(1) == "1"'
      ;;
    *) return 0 ;;
  esac
  mv "$app/$src" "$WORK/sourceless.src"
  mv "$app/$spec" "$WORK/sourceless.spec"
  printf '%s\n' "$body" >"$app/$check"
  expect_fail leaf "$app" "$lang" test --all
  grep -qxF "bin/test: --all found no source to hold at 100%" "${LAST_LOG}" || die "$lang bin/test --all passed measuring no source"
  rm "$app/$check"
  mv "$WORK/sourceless.src" "$app/$src"
  mv "$WORK/sourceless.spec" "$app/$spec"
}

whole_app() {
  local app="$1" lang="$2" lint_plant lint_body lint_find source_plant source_body
  case "$lang" in
    typescript)
      lint_plant=src/unused.ts
      lint_body='const unused = 1;'
      lint_find="'unused' is assigned a value but never used"
      source_plant=src/extra.ts
      source_body=$'export function extra(): number {\n  return 1;\n}'
      ;;
    javascript)
      lint_plant=src/dupe.js
      lint_body='export const dupe = { a: 1, a: 2 };'
      lint_find="noDuplicateObjectKeys"
      source_plant=src/extra.js
      source_body=$'export function extra() {\n  return 1;\n}'
      ;;
    python)
      lint_plant=src/unused.py
      lint_body=$'def unused() -> None:\n    value = 1'
      lint_find="F841"
      source_plant=src/extra.py
      source_body=$'def extra() -> int:\n    return 1'
      ;;
    rails)
      lint_plant=app/models/unused.rb
      lint_body=$'# frozen_string_literal: true\n\nmodule Unused\n  def self.call\n    unused = 1\n    2\n  end\nend'
      lint_find="Lint/UselessAssignment"
      source_plant=app/models/extra.rb
      source_body=$'# frozen_string_literal: true\n\nmodule Extra\n  def self.call\n    1\n  end\nend'
      ;;
    shell)
      lint_plant=loose
      lint_body="#!/usr/bin/env bash"$'\n'"set -euo pipefail"$'\n'"echo \$1"
      lint_find="SC2086"
      ;;
    *) return 0 ;;
  esac
  printf '%s\n' "$lint_body" >"$app/$lint_plant"
  [ "$lang" != shell ] || chmod +x "$app/$lint_plant"
  git -C "$app" add -- "$lint_plant"
  git -C "$app" commit -q -m "lint plant"
  expect_fail leaf "$app" "$lang" ci --force
  grep -qF "$lint_find" "${LAST_LOG}" || die "$lang ci did not lint a committed file"
  git -C "$app" rm -qf -- "$lint_plant"
  git -C "$app" commit -q -m "lint plant gone"
  [ -n "${source_plant:-}" ] || return 0
  printf '%s\n' "$source_body" >"$app/$source_plant"
  git -C "$app" add -- "$source_plant"
  git -C "$app" commit -q -m "source plant"
  expect_fail leaf "$app" "$lang" ci --force
  grep -qF "no mirrored test for $source_plant" "${LAST_LOG}" || die "$lang ci did not test a committed source"
  git -C "$app" rm -qf -- "$source_plant"
  git -C "$app" commit -q -m "source plant gone"
}

source_rules() {
  local app="$1" lang="$2"
  case "$lang" in
    typescript)
      printf 'export type Version = string;\n' >"$app/src/version.d.ts"
      expect_fail leaf "$app" "$lang" build
      grep -q "skipLibCheck skips the app's own src/version.d.ts" "${LAST_LOG}" ||
        die "$lang let skipLibCheck skip the app's own declarations"
      cp "$app/tsconfig.json" "$WORK/tsconfig.keep"
      jq 'del(.compilerOptions.skipLibCheck)' "$WORK/tsconfig.keep" >"$app/tsconfig.json"
      printf '%s\n' 'export function button(): string {' '  return "b";' '}' >"$app/src/Button.tsx"
      printf '%s\n' 'import { expect, test } from "vitest";' 'import { button } from "../src/Button";' '' \
        'test("button", () => {' '  expect(button()).toBe("b");' '});' >"$app/tests/Button.test.tsx"
      mkdir -p "$app/lib" "$app/tests/lib"
      printf '%s\n' 'export function twice(n: number): number {' '  return n * 2;' '}' >"$app/lib/twice.ts"
      printf '%s\n' 'import { expect, test } from "vitest";' 'import { twice } from "../../lib/twice";' '' \
        'test("twice", () => {' '  expect(twice(2)).toBe(4);' '});' >"$app/tests/lib/twice.test.ts"
      expect_ok leaf "$app" "$lang" changed
      expect_ok leaf "$app" "$lang" ci --force
      rm "$app/tests/lib/twice.test.ts"
      expect_fail leaf "$app" "$lang" ci --force
      grep -q "no mirrored test for lib/twice.ts" "${LAST_LOG}" || die "$lang let a source outside src/ go untested"
      rm -r "${app:?}/lib" "$app/tests/lib" "$app/src/version.d.ts" "$app/src/Button.tsx" "$app/tests/Button.test.tsx"
      mv "$WORK/tsconfig.keep" "$app/tsconfig.json"
      ;;
    javascript)
      printf '%s\n' 'export function mul(a, b) {' '  return a * b;' '}' >"$app/src/mul.js"
      printf '%s\n' 'import assert from "node:assert/strict";' 'import test from "node:test";' \
        'import { mul } from "./mul.js";' '' 'test("mul", () => {' '  assert.equal(mul(2, 3), 6);' '});' \
        >"$app/src/mul.spec.js"
      expect_ok leaf "$app" "$lang" changed
      rm "$app/src/mul.js" "$app/src/mul.spec.js"
      printf '%s\n' 'module.exports = {' '  one() {' '    return 1;' '  },' '  two() {' '    return 2;' '  },' '};' \
        >"$app/src/legacy.cjs"
      printf '%s\n' 'import assert from "node:assert/strict";' 'import test from "node:test";' \
        'import legacy from "../src/legacy.cjs";' '' 'test("one", () => {' '  assert.equal(legacy.one(), 1);' '});' \
        >"$app/tests/legacy.test.js"
      git -C "$app" add -- src/legacy.cjs tests/legacy.test.js
      git -C "$app" commit -q -m "legacy"
      printf '// edited\n' >>"$app/tests/legacy.test.js"
      expect_fail leaf "$app" "$lang" changed
      grep -qF "src/legacy.cjs" "${LAST_LOG}" || die "$lang test-only edit did not hold its .cjs source"
      git -C "$app" rm -qf -- src/legacy.cjs tests/legacy.test.js
      git -C "$app" commit -q -m "legacy gone"
      ;;
    python)
      mkdir -p "$app/src/pkg" "$app/tests/pkg" "$app/scripts"
      : >"$app/src/pkg/__init__.py"
      printf '%s\n' 'def mul(a: int, b: int) -> int:' '    return a * b' >"$app/src/pkg/mul.py"
      printf '%s\n' 'from pkg.mul import mul' '' '' 'def test_mul() -> None:' '    assert mul(2, 3) == 6' \
        >"$app/tests/pkg/test_mul.py"
      printf 'print("seed")\n' >"$app/scripts/seed.py"
      expect_ok leaf "$app" "$lang" changed
      expect_ok leaf "$app" "$lang" ci --force
      rm -r "$app/src/pkg" "$app/tests/pkg" "$app/scripts"
      ;;
  esac
}

coverage_gap() {
  local app="$1" lang="$2" file body report args=()
  case "$lang" in
    typescript)
      args=(--all)
      file=src/add.ts
      body=$'export function add(a: number, b: number): number {\n  return a > 0 ? a + b : b;\n}'
      report='at 100\.00 functions, 100\.00 lines, [0-9]{1,2}\.[0-9]{2} branches'
      ;;
    javascript)
      args=(--all)
      file=src/index.js
      body=$'export function add(a, b) {\n  return a > 0 ? a + b : b;\n}'
      report='at 100\.00 functions, 100\.00 lines, [0-9]{1,2}\.[0-9]{2} branches'
      ;;
    python)
      args=(--all)
      file=src/add.py
      body=$'def add(a: int, b: int) -> int:\n    if a > 0:\n        return a + b\n    return b'
      report='bin/test: src/add\.py at 3/4 stmts 1/2 branches \(need 100/100\)'
      ;;
    rails)
      file=app/models/add.rb
      body=$'# frozen_string_literal: true\n\nmodule Add\n  module_function\n\n  def call(left, right)\n'
      body+=$'    return right if left.negative?\n\n    left + right\n  end\nend'
      report='Branch coverage \(50\.00%\) is below the expected minimum coverage \(100\.00%\)'
      ;;
    rust)
      file=src/lib.rs
      body=$'pub fn add(a: i32, b: i32) -> i32 {\n    a + b\n}\n\npub fn untested() -> i32 {\n    1\n}\n\n'
      body+=$'#[cfg(test)]\nmod tests {\n    use super::add;\n\n    #[test]\n    fn adds() {\n'
      body+=$'        assert_eq!(add(1, 2), 3);\n    }\n}'
      report='src/lib\.rs( +[0-9.%-]+){6} +[0-9]+ +[1-9][0-9]* +[0-9.]+%'
      ;;
    ios)
      file=Sources/App/Add.swift
      body=$'public func add(_ a: Int, _ b: Int) -> Int { a + b }\n\npublic func untested() -> Int { 1 }'
      report='FAIL: line coverage is under 100%'
      ;;
    shell) return 0 ;;
    *) die "$lang has no coverage gap plant" ;;
  esac
  expect_ok leaf "$app" "$lang" test ${args[@]+"${args[@]}"}
  grep -qxF "bin/test: coverage bar held on 1 source(s)" "${LAST_LOG}" ||
    die "$lang bin/test did not report holding its one source to the coverage bar"
  cp "$app/$file" "$WORK/gap.keep"
  printf '%s\n' "$body" >"$app/$file"
  expect_fail leaf "$app" "$lang" ci --force
  grep -q "step 'test' failed" "${LAST_LOG}" || die "$lang passed a source below its coverage bar"
  grep -qE "$report" "${LAST_LOG}" || die "$lang did not report the source below its coverage bar"
  mv "$WORK/gap.keep" "$app/$file"
}

pin_file_of() {
  case "$1" in
    typescript) printf '%s\n' .nvmrc ;;
    javascript) printf '%s\n' .nvmrc ;;
    python) printf '%s\n' .python-version ;;
    rails) printf '%s\n' .ruby-version ;;
    rust) printf '%s\n' rust-toolchain.toml ;;
    ios) printf '%s\n' .xcode-version ;;
    *) return 1 ;;
  esac
}

brakeman_plant() {
  mkdir -p "$1/app/controllers"
  printf '%s\n' '# frozen_string_literal: true' '' 'class RunController < ActionController::Base' '  def index' \
    '    system("echo #{params[:name]}")' '  end' 'end' >"$1/app/controllers/run_controller.rb"
}

nvm_stub() {
  local dir="$1" node
  node="$(command -v node)"
  mkdir -p "$dir/bin"
  cat >"$dir/bin/node" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" = --version ]; then
  echo v1.0.0
  exit 0
fi
exec "$node" "\$@"
EOF
  chmod +x "$dir/bin/node"
  cat >"$dir/nvm.sh" <<EOF
nvm() {
  [ "\$*" = "use 1.0.0" ] && PATH="$dir/bin:\$PATH"
}
EOF
}

mode_file_of() {
  case "$1" in
    typescript | javascript) printf '%s\n' package.json ;;
    python) printf '%s\n' pyproject.toml ;;
    rails) printf '%s\n' Gemfile ;;
    rust) printf '%s\n' Cargo.toml ;;
    ios) printf '%s\n' Package.swift ;;
    shell) printf '%s\n' notes ;;
  esac
}

decoy_coverage() {
  local app="$1" ext="$2"
  mkdir -p "$app/lib/src" "$app/tests/lib/src"
  if [ "$ext" = ts ]; then
    printf '%s\n' 'export function orphan(): number {' '  return 1;' '}' >"$app/src/orphan.ts"
    cp "$app/src/orphan.ts" "$app/lib/src/orphan.ts"
    printf '%s\n' 'import { expect, test } from "vitest";' '' 'test("orphan", () => {' '  expect(1).toBe(1);' '});' \
      >"$app/tests/orphan.test.ts"
    printf '%s\n' 'import { expect, test } from "vitest";' 'import { orphan } from "../../../lib/src/orphan";' '' \
      'test("lib orphan", () => {' '  expect(orphan()).toBe(1);' '});' >"$app/tests/lib/src/orphan.test.ts"
  else
    printf '%s\n' 'export function orphan() {' '  return 1;' '}' >"$app/src/orphan.js"
    cp "$app/src/orphan.js" "$app/lib/src/orphan.js"
    printf '%s\n' 'import assert from "node:assert/strict";' 'import test from "node:test";' '' 'test("orphan", () => {' \
      '  assert.equal(1, 1);' '});' >"$app/tests/orphan.test.js"
    printf '%s\n' 'import assert from "node:assert/strict";' 'import test from "node:test";' \
      'import { orphan } from "../../../lib/src/orphan.js";' '' 'test("lib orphan", () => {' '  assert.equal(orphan(), 1);' \
      '});' >"$app/tests/lib/src/orphan.test.js"
  fi
  expect_fail leaf "$app" "$lang" ci --force
  grep -q "src/orphan.$ext has no coverage row" "${LAST_LOG}" || die "$lang matched a source to another file's coverage row"
  rm -r "${app:?}/lib" "$app/tests/lib" "$app/src/orphan.$ext" "$app/tests/orphan.test.$ext"
}
