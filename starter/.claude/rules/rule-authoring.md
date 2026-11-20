# Rule Authoring

A rule states one constraint in positive form, in its own file, in the folder
it governs; every new or edited rule is reviewed and stamped.

## The Rule

- A rule leads with one H1 naming its topic and a one-line principle, then
  states its claim in positive form: a membership check, never a denylist.
  It describes a check exactly as it works, even when it fails a named
  list, names its failure mode and trigger inline, and cites another rule
  by filename, stating only what that rule says. Trigger: any new or
  edited rule; the review refuses the rest.
- One constraint has one owner: its full statement lives in one file, and
  every other mention cites that file. A constraint spanning two concerns
  splits into two files that cite each other. Trigger: any new or edited
  rule; the review refuses a restatement.
- A rule lives in the folder it governs: the root of `.claude/rules/` binds
  the whole repo and a folder named for a repo directory binds that
  subtree; a misplaced rule binds files it never governs. A rule opens with
  its one H1; `tests/guards` fails frontmatter, a missing or second H1, and
  a cited rule file that does not exist. Trigger: a new or moved rule.
- Every H2 is a constraint, a scope, a trigger or `## The Rule`;
  `tests/guards` fails one matching `NARRATIVE_HEADING`, and the review
  refuses the rest. Trigger: a new or edited heading.
- A rule is forward-facing, imperative and terse: present tense; do, never,
  when; a verbatim command only one the hooks and permissions allow, such
  as `bin/*`; at most 40 lines and 8,000 characters bar the stamp, 80
  characters a line; code named by symbol or path, not line number.
  `tests/guards` fails `BACKWARD_FACING` wording and either cap,
  markdownlint fails a long line, and the review refuses the rest.
  Trigger: any new or edited rule.
- Every rule edit lands through `bin/commit`: a separate Claude session
  reviews the edited rules against this file, Claude gets one try at fixing
  what it finds, a fresh review of the fixed text must pass or the commit
  is refused, and a passing review stamps each file with `bin/stamp-rules`;
  `tests/guards` fails a rule whose stamp does not match its body. Trigger:
  any change to a file under `.claude/rules/`.
<!-- audited: 6b3cd77c4455 -->
