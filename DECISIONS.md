# Decisions log
One line per load-bearing decision (mirror the plan's PATCH log).

- A4: zero third-party runtime dependencies (offline-first).
- PATCH-01: `Simulation` is a plain `final class`, never `@MainActor`.
