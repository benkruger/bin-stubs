# Rule Authoring

A rule states one constraint in positive form, in its own file, in the folder
it governs; every edit is reviewed and stamped.

## The Rule

- A rule leads with one H1 naming its topic and a one-line principle, then
  states its claim in positive form: a membership check against the allowed
  set, never a denylist. It names its failure mode and its trigger inline,
  and cites another rule by filename, stating only what that rule says.
- One constraint has one owner: its full statement lives in one file, and
  every other mention cites that file. A constraint spanning two concerns
  splits into two files that cite each other.
- Every H2 is a constraint, a scope, a trigger or `## The Rule`;
  `tests/guards` fails a narrating heading.
- Every rule edit lands through `bin/commit`: a separate Claude session
  reviews the edited rules against this file, Claude gets one try at fixing
  what it finds, a finding left after that refuses the commit, and a clean
  review stamps each file through `bin/stamp-rules`. `tests/guards` fails a
  rule whose stamp does not match its body.

## Scope by folder

A rule lives in the folder it governs: the root of `.claude/rules/` binds
the whole repo, and a folder named for a repo directory binds that subtree.
Place a rule, never annotate it: no frontmatter. Trigger: settle the folder
and the constraint first, or the rule binds files it never governs.

## Write forward-facing, imperative, terse

- **Forward-facing**: present tense, what is.
- **Imperative and testable**: do, never, when. A verbatim instruction uses
  only commands the repo's hooks and permissions allow, such as `bin/*`.
- **Terse**: a principle, not an essay. At most 40 lines and 8,000
  characters with the stamp excluded, which `tests/guards` enforces, and
  every line at most 80 characters. Name code by symbol, command or path,
  never by a location or line number.
<!-- audited: 3b6846a39c99 -->
