# Egress
Offline, on-device crowd-evacuation simulator for iPhone.
Educational analysis, not certified engineering advice.

Toolchain (PIN before freeze): Xcode 27 · Swift 6.4 · iOS 27 SDK · deploy iOS 26 · iPhone-only.

## Development setup

One-command bootstrap after cloning:

```bash
./bin/setup
```

This installs the pinned toolchain (`swiftlint`, `swiftformat`, `lefthook` via Homebrew) and wires the git hooks. It is idempotent — safe to re-run.

**Automatic on every commit:**
- `swiftformat` auto-formats staged Swift files and re-stages them.
- `swiftlint --strict` blocks the commit on any violation.

**Automatic on every push:**
- `swift test` runs the `EgressEngine` suite when Swift files changed.
- Full `swiftlint --strict` sweep.

Emergency bypass: `git commit --no-verify` (avoid — CI should enforce the same rules).

Config lives in `.swiftlint.yml`, `.swiftformat`, and `lefthook.yml`.
