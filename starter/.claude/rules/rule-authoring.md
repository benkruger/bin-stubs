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
  every other mention cites that file. A rule covers only the topic its H1
  names; a statement on another topic is cut. Trigger: any new or edited
  rule; the review refuses a restatement or an off-topic statement.
- A rule lives in the folder it governs: the root of `.claude/rules/` binds the
  whole repo and a folder named for a repo directory binds that subtree; the
  review refuses a rule outside the folder it governs. A rule opens with its one
  H1; `tests/guards` fails frontmatter, a missing or second H1, a cited rule
  file that does not exist and a rule whose real path, symlinks resolved, lies
  outside every `.claude/rules/` folder. Trigger: a new or moved rule.
- Every H2 is a constraint, a scope, a trigger or `## The Rule`;
  `tests/guards` fails one matching `NARRATIVE_HEADING`, and the review
  refuses the rest. Trigger: a new or edited heading.
- A rule is forward-facing, imperative and terse: present tense; do, never,
  when; a verbatim command only one the hooks and permissions allow, such
  as `bin/*`; at most 40 lines and 8,000 characters bar the stamp, 80
  characters a line; code named by symbol or path, not line number.
  `tests/guards` fails `BACKWARD_FACING` wording, either cap and a line
  over 80 characters, and the review refuses the rest.
  Trigger: any new or edited rule.
- Every rule edit lands through `bin/commit`, which refuses a rule over a cap
  above; a separate Claude session reviews edited rules against this file, and
  a file that passed before only on its changed lines; Claude fixes only
  flagged files for at most `MAX_FIX_ROUNDS` rounds, a fix over a cap is
  dropped, and the commit is refused while a finding stands; a passing review
  stamps each file with `bin/stamp-rules`; `tests/guards` fails a rule whose
  stamp does not match its body. Trigger: any change under `.claude/rules/`.
<!-- audited: 094df7d28f1d -->
