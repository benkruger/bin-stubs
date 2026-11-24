# No Comments

Code carries no comments; the code itself is the only account of what it
does.

## The Rule

- A file `comment_lines` classes holds no comment but the lines the next
  bullet allows. `tests/guards` runs
  `comment_lines` on
  every tracked or new text file except Markdown and the files `is_exempt`
  names, and fails each line with a comment outside a string, regex or
  heredoc: `//` or `/* */` in JavaScript, TypeScript, JSON, Rust and
  Swift, doc comments included; `/* */` in CSS; `#` in shell, Ruby (and
  `=begin`), Python, TOML, YAML, `.gitignore`, `.gitattributes` and
  `.shellcheckrc`; Ruby also by `.rake`, `.ru`, `.gemspec`, `Gemfile` and
  `Rakefile`. Any other file is classed by a Ruby, Python or shell
  shebang, and one with none is not scanned. Trigger: any new or edited
  code file.
- Only a line a tool reads stays: a line-1 shebang, a Ruby magic comment
  with a value Ruby accepts in the file's leading comment block, the
  shellcheck line `script-standards.md` allows and line 1
  `// swift-tools-version:` of a `Package.swift`. A lint rule only a
  comment can satisfy is handled as `no-lint-exceptions.md` states.
  `tests/guards` fails any other comment line in a file `comment_lines`
  classes. Trigger: any new or edited code file.
<!-- audited: 5cec57291fb8 -->
