# Authored File Size

Every authored text file in the kit is at most 65,536 bytes, the same cap
the kit ships.

## The Rule

- `starter/tests/guards` fails any text file over 65,536 bytes.
- A script that would pass the cap is split into a helper it sources.
- The cap never rises.
