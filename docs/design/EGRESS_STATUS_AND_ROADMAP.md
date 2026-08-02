# Egress — Status & Roadmap to Full End-to-End (engine + UI)

> **Paste this whole file into a new chat as the first message.** It is a mid-project
> handoff: what's done, exactly where we stopped, the engine↔app contract, and the full
> remaining work to a shippable, end-to-end-tested product (both `EgressEngine` and the app).
> Written 2026-08-01. Authority docs: `docs/design/EGRESS_BUILD_PLAN_v3.md` (the spec),
> `docs/design/EGRESS_HANDOFF_CONTEXT.md` (how-we-work rules), `Design.pdf`.

---

## 1. What Egress is

An **offline, 100% on-device iPhone crowd-evacuation simulator** for the **IndeHub Hackathon
2026** (Pocket Brain / Local-LLM track). You shape a furnished venue (rooms, exits, obstacles),
set a crowd, sound the alarm, and watch a physically-grounded crowd evacuate under fire/smoke.
The app gives a **verdict + safety score + reasons with real units**, and an on-device AI coach
("RALLY") **names one geometry fix** you can **Apply and re-run** for a visibly better score.

- **Submission is video-only** (no paid Apple account / TestFlight). The recording is the sole
  evidence. **Deadlines (IST):** submission **7 Aug 2026 11:59 PM**; finale 22 Aug 2026.
- **Two targets:** pure `EgressEngine` (Swift Package, Foundation + simd only) and the SwiftUI
  `Egress` app. Dev A = engine, Dev B = app, decoupled by the `SimulationRunning` protocol.

---

## 2. Where we are (stage map)

The plan is dependency-ordered stages **S0→S5**; **S2 ("the core journey") is the submission floor.**

| Stage | Engine (Dev A) | App / UI (Dev B) |
|---|---|---|
| **S0** foundation | ✅ done | ✅ TabView shell, design system; ⚠️ device spikes pending |
| **S1** walking skeleton | ✅ done | ✅ canvas renders live agents + density + hazards; basic HUD; play/pause/reset |
| **S2** core journey (floor) | ✅ **feature-complete** (one gap: panic dynamics, see §5A) | ⛔ **largely NOT built** (editor, results sheet, RALLY card, escalation banner, apply&re-run UI, presets) |
| **S3** evidence-grade | mostly pending (AI coach is Dev B) | ⛔ pending |
| **S4/S5** recording + submit | — | ⛔ pending |

**Net:** the **engine is ahead** (S2 complete, 125 tests / 26 suites green) and the **app is
behind** (~S1 + partial S2). The bulk of remaining work is **app-side S2/S3 UI**, plus a small
engine gap and the device/build tasks.

**Engine tests:** `swift test --package-path EgressEngine` → **125 tests / 26 suites, all green.**
Everything below `Simulation` is proven headless, including the money-loop (`ApplyRerunTests`).

---

## 3. What is COMPLETE

### 3A. `EgressEngine` (pure Swift) — the whole S2 spine

- **Geometry / core:** `Vec2`, `GridCoord` (now `Codable`), `GridSize`, `GridGeometry`, `SeededRNG`
  (SplitMix64, deterministic), `SpatialHash`.
- **Venue model:** `VenueModel`, `Exit`, `Obstacle` (`isRelocatable`), `Wall`, `VenueType`
  (+ per-type `clearanceTarget`, §2.9).
- **Navigation:** `FlowField` (4-connected BFS, wall-aware — *note: not yet 8-connected Dijkstra*),
  `BlockedCells`, `WallField` (distance + normal for soft wall force).
- **Agents:** `Agent`/`AgentTraits`/`EmotionalState`/`AgentStatus`, `AgentSpawner` (reachability-filtered, seeded).
- **`Simulation: SimulationRunning`** — Helbing social force (drive + pedestrian repulsion/body/friction
  + soft wall), semi-implicit Euler at H=1/120, dt clamp, hard wall-slide, Jacobi update ⇒ deterministic.
- **Density:** `DensityGrid.sampled` (bin → separable 7×7 box blur → p·m⁻²) + `peak`, `peakCell`.
- **Metrics:** `Metrics` — clearance latch, peak density (+location/time), at-risk person-seconds &
  fraction, casualties, `trappedCount`.
- **Hazards:** `FireAutomaton` (4-state CA), `SmokeField` (diffusion), `HazardField` (owns both, 15 Hz
  clock). Wired into `Simulation`: mid-run **reroute around fire**, **fire casualties** (injured→dead).
- **Scoring & verdict:** `SafetyScore` (C/D/R/T penalties; matches §2.8 worked examples),
  `VerdictRules.default.evaluate(_:)` → `Verdict{level, score, reasons}` with `VerdictReason`
  (metricKey + threshold + actual + unit + text), `VerdictConstants`, `SafetyStandards`.
- **RALLY (grounded):** `Fix` (widenExit/addExit/relocateObstacle, `.summary`/`.feasibility`/`.apply`),
  `RallyCoach.default.suggest(...)` → highest-impact feasible fix. `ApplyRerunTests` proves
  non-PASS → fix → apply → re-run → higher score + faster clearance.
- **Event log + live escalation (just completed, E1–E4):**
  - `RunEvent` / `RunEventKind` (11 kinds), `RunEventLog` (monotonic ids, `Codable`),
    `RunEventLog.summary() → RunSummary` (the **token-bounded digest** = the *only* run data the AI sees).
  - `Simulation` **emits** alarm / ignition / flow-recompute / injured / killed / simEnded as it runs.
  - `EscalationTracker` (§3.3): density bands ≥4/≥5/≥7 + exitBlocked + first-casualty, **once-per-crossing,
    6 s cooldown, 10 s re-arm, higher rung surpasses lower** — exposed on `Simulation.escalations` and
    mirrored into the log. All proven deterministic (pure observers, no physics feedback).

### 3B. `Egress` app (SwiftUI) — what already exists

- App shell: `EgressApp`, `AppRoot` (TabView: **Spaces / Simulate / Learn**), `AppDependencies`.
- **Design system:** `Color+Tokens`, `Typography`, `Materials` (Liquid Glass), `Motion`, `Symbols`, `Layout`.
- **Simulate tab (works):** `SimulationController` (`@MainActor @Observable`, drives the **real**
  `Simulation` via `TimelineView(.animation)`), `SimCanvasView` + `SimCanvasRenderer`
  (**renders grid → density bands → fire/smoke → exits → agents**), basic HUD (Inside/Elapsed/%Out),
  Play/Pause/Reset, `SampleVenue.hall()`.
- **Persistence:** `RunRecord` (SwiftData `@Model`) defined — **but not yet written to on run completion**.
- **Placeholders:** `SpacesRootView` (empty-state only), `LearnRootView` (stub).

---

## 4. The engine↔app integration contract (what the UI must consume)

The controller currently reads only `snapshot.live`. To finish S2 the app must additionally read:

```swift
let sim = Simulation(venue: venue, config: config)   // drive via step(dt:) / snapshot() / isComplete
sim.metrics        // Metrics: clearance, peakDensity, peakLocation, atRiskFraction, casualties, trappedCount, clearanceTarget, timeCap, spawnedCount
sim.eventLog       // RunEventLog: .events, .summary() -> RunSummary   (feeds AI + timeline)
sim.escalations    // [EscalationTracker.Escalation] (band + time)     (feeds the live banner)

SafetyScore(metrics: sim.metrics).value            // 0…100 + sub-penalties
VerdictRules.default.evaluate(sim.metrics)         // Verdict{level, score, reasons:[VerdictReason]}
RallyCoach.default.suggest(for: verdict, metrics: sim.metrics, in: venue)  // Fix?
fix.summary                                        // "Widen Exit 0 to 1.2 m"
fix.feasibility(in: venue).isFeasible
let improved = fix.apply(to: venue)                // new VenueModel → re-run with the SAME config/seed
```

`SimulationSnapshot` (per frame): `.time`, `.agents:[AgentRender]` (position/emotion/mobility/status),
`.hazards:HazardSnapshot` (fire/smoke cell maps), `.density:DensityGrid`, `.live:LiveMetrics`.
Map `EscalationBand` → banner text/colour/haptic (§3.3 table). Verdict reasons already carry
units — render them verbatim; the score is secondary (§3.2).

---

## 5. What is LEFT (roadmap to full end-to-end)

### 5A. `EgressEngine` — remaining

1. **Panic / emotion dynamics in the real `Simulation`** ⚠️ *(S2 gap — blocks the "faster-is-slower"
   exit criterion)*. Today agents stay `.calm`; `arousalFactor(emotion)` is read but never raised.
   Port the rule already proven in `MockSimulation`: near-fire **or** local density ≥ 5 → `.panicked`;
   density ≥ 1.8 → `.uneasy`. Panic raises desired speed → non-monotonic throughput. **Needs tests**
   (panic sweep shows non-monotonic clearance).
2. **Deferred log niceties** (optional for the floor, nice for the HUD curve): `jamFormed`,
   `evacuationProgress` (≤2 Hz), `hazardSpread` (≤1 Hz) events — share the same per-frame hook.
3. **Verdict rule 4d — aisle clear-width analysis** (§2.13.7): narrowest traversed aisle < minimum → WARN. (S3 #5)
4. **Smoke/crush casualty causes** (§2.7): smoke-toxicity and density≥7-sustained casualties (only fire wired today).
5. **Anticipatory dodge + stumble** (§2.13.4–5). (S3 #4)
6. *(Acceptable skeleton simplification, only if time)* upgrade `FlowField` 4-connected BFS → 8-connected Dijkstra, no corner-cutting.

### 5B. App / UI — remaining (the bulk, Dev B)

**S2 (submission floor):**
1. **Parametric editor** (Spaces → editor, §5.6): rooms/exits/props via handles + steppers + typed
   dimensions on the 0.25 m grid; **undo/redo**. *(Largest single item.)*
2. **Spaces library**: ~4 furnished presets + pre-run config chips (crowd size, seed, ignition points).
3. **Dimension overlay**: cyan measurements + the `1 PIXEL BLOCK = 0.25 m × 0.25 m` caption on the canvas.
   *(Density + hazard rendering already done.)*
4. **Results sheet**: score ring, PASS/WARN/FAIL badge, **reasons with units** (from `Verdict.reasons`),
   canned banner strings.
5. **Live escalation banner**: read `sim.escalations`, map `EscalationBand` → amber/red banner
   (+ symbol effect); non-blocking, repositions off the bottleneck.
6. **RALLY sprite + card** with canned lines; **Apply button** → `fix.apply` → re-run same seed →
   **before/after score side-by-side**. (This is the demo's climax — must be smooth.)
7. **Persist runs**: write `RunRecord` on completion (bridge `Verdict.level`/score/clearance/seed).

**S3 (evidence-grade — where 4s/5s come from):**
8. **States & recovery**: empty / loading / offline / unavailable-feature / failure (§E.2).
9. **Accessibility pass**: labels, values, canvas summary element, Dynamic Type, Reduce Motion,
   pattern fills (never colour-alone), 44 pt targets; VoiceOver completes the journey.
10. **On-device AI coach**: `CoachingService`, **3 `@Generable` schemas**, the **V1–V8 validation gate**
    (every emitted number checked against engine values; element-ids whitelisted), streaming UI, and
    **canned-fallback wiring** (forced-fallback run must produce an identical layout). Grounded on
    `RunEventLog.summary()` + `Verdict` + `RallyCoach` — **never** raw frames.
11. **Haptics**: `.sensoryFeedback` + 3 CoreHaptics patterns, ≤1 per 0.5 s (verdict > escalation > casualty > UI).
12. **3 SFX cues only**: alarm klaxon, threshold sting, verdict fanfare (`.ambient`, respects silent switch).
13. **Debug touch-indicator overlay** for the recording.

### 5C. Device / build (needs the physical iPhone 16 + Xcode 27)

- Archive against iOS-27 SDK / deploy-target iOS-26 → **install on device** (S0/S1 acceptance).
- Record **`SystemLanguageModel.availability`** result (retires R-03); confirm Apple Intelligence assets
  downloaded while online.
- **≥55 fps** sustained in Instruments at the shipped agent count (S1 exit).
- Tags as stages exit: `golden-skeleton` (S1) · `golden-core` (S2) · `golden-evidence` (S3) ·
  `release-candidate` (S4). 30-min soak: no crash / no memory growth / thermal < serious.
- **swiftlint is NOT installed on this Mac** — strict lint runs only via the pre-commit hook; keep
  identifiers out of the 1–2-char set (see `.swiftlint.yml`) and let swiftformat run.

---

## 6. Final end-to-end acceptance (the S2 exit gate — §6.5)

All true **on device, airplane mode, three consecutive runs, zero crashes**:

- [ ] Clean launch → open/shape a furnished venue → set crowd → alarm → fire + emotions →
      **live escalation banner** → **verdict + score + reasons with units**.
- [ ] **RALLY names a geometry fix → Apply → re-run → visibly better score** (side-by-side).
- [ ] Score reproduces §2.8 worked examples (Concert Crush = 7, Office = 98). *(engine ✅)*
- [ ] Verdict order correct across all 6 branches. *(engine ✅)*
- [ ] **Faster-is-slower reproduces** across a panic sweep. *(needs §5A.1)*
- [ ] Determinism: same seed → identical clearance. *(engine ✅)*
- [ ] Tag `golden-core` and archive.

Then S3 (coach + states + accessibility) → S4 (one unbroken take of the core journey) → S5 (submit
before the deadline).

---

## 7. How we work (keep this style)

Continue **step-by-step, one sub-step at a time** (see `EGRESS_HANDOFF_CONTEXT.md` §2 for the full rules):
lead with **WHERE (file + location) + WHY (rationale first), then the code**; **default is guidance-only**
(show the code block, the user hand-types) unless the user says "apply it / you do it / yes apply" — then
edit the files. Writing tests and running `swift test --package-path EgressEngine` (green before the next
step) is always the assistant's job. The user is learning the codebase — reasoning matters as much as code.

**Git:** ~21 tested engine steps currently sit uncommitted on `main`; commit only when the user asks
(they've chosen to keep building). The event-log subsystem is a clean checkpoint whenever they want one.
