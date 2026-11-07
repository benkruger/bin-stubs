# No Lint Exceptions

The kit installs gates that ban silenced lint, so the kit itself carries no
silenced lint anywhere.

## The Rule

- No file in the repo contains a suppression comment or attribute for any
  tool the kit drives. `starter/tests/guards` holds the banned list.
- A lint finding is fixed in the code it flags.
- Rules and docs describe the banned tokens without spelling them out, so
  the guard never trips on its own description.
