# Egress — Project Handoff Context (for a fresh chat)

> Paste this whole file into a new chat as the first message. It tells the new
> assistant **what we're building, how we work together, the full step map,
> where we stopped, and what to do next.** Written 2026-08-01.

---

## 0. How to use this document

If you are the assistant reading this: this is a mid-project handoff. Read all of
it before acting. The single most important sections are **§2 (how we work — the
rules)** and **§5 (where we are / what's next)**. Do not restart or re-plan the
project; continue it exactly in the established style.

---

## 1. What we are building

**Egress** — an **offline, 100% on-device iPhone crowd-evacuation simulator**,
built for the **IndeHub Hackathon 2026** (Pocket Brain / Local LLM track).

You place or shape a furnished venue (rooms, exits, obstacles), set a crowd,
sound the alarm, and watch a physically-grounded crowd simulation evacuate under
fire/smoke. The app then gives a **verdict + safety score + reasons with real
units**, and an on-device AI coach ("RALLY") **names one geometry fix** you can
**Apply and re-run** to get a visibly better score.

- **Design docs:** `docs/design/EGRESS_BUILD_PLAN_v3.md` (the authority — build
  ordering, physics §2.2, flow field §2.4, scoring §2.8), plus
  `EGRESS_CLAUDE_DESIGN_PROMPT_v3.md` and `Design.pdf`.
- **Submission is video-only** (no paid Apple account, no TestFlight). The
  recording is the *sole* evidence a judge sees; criterion 06 gates 01–04.

**Hard deadlines (IST):** registration closed 31 Jul 2026 · **submission
7 Aug 2026 11:59 PM** · Bengaluru finale 22 Aug 2026.

---

## 2. HOW WE WORK — the collaboration rules (do not lose these)

This is the working style the user wants preserved across chats. Follow it exactly.

1. **Step by step, one step at a time.** Never dump the whole stage at once.
2. **Always lead with WHERE + WHY.** For each step, first state (a) exactly where
   the change goes (file + location) and (b) the *reason* for it — rationale
   **first**, then the code.
3. **Guide vs. Apply is the user's call, per step.** Watch their cue each step:
   - Default = **guidance-only**: show the code block, they hand-type it, you do
     **not** touch their source files.
   - When they say "apply it" / "you do it" / "you fix this yourself" / "Apply +
     verify" → **you** run Edit/Write yourself.
   - When they say "GUIDE" → guidance-only for the source, but writing the test
     file and verifying is still yours if they say so.
4. **Verification is your job.** Whenever you apply code (or whenever they ask),
   you must run the tests and confirm green **before moving to the next step** —
   `swift test --package-path EgressEngine` for the engine.
5. Reading, testing, inspecting, and running builds are always fine.
6. The user is **learning the codebase** — the reasoning up front matters as much
   as the code. Keep explanations concrete and tied to the plan sections.

---

## 3. Architecture (the shape of the codebase)

Two targets, kept strictly separated:

- **`EgressEngine`** — a pure Swift library (**Foundation + simd only**, no
  SwiftUI). Headless, fully unit-tested with **Swift Testing** (`import Testing`,
  `@Suite`, `@Test`, `#expect`). This is "Dev A" territory: standards, venue &
  agent models, flow field, social force, hazards, metrics, score, verdict.
- **`Egress`** — the SwiftUI app (iOS 26 deploy target, iOS 27 SDK). "Dev B"
  territory: design system, canvas renderer, parametric editor, HUD, sheets,
  Spaces, the AI seam, haptics, accessibility.

**The contract that lets them build in parallel:** `SimulationSnapshot` is locked,
and the engine exposes a `SimulationRunning` protocol
(`step(dt:)`, `snapshot() -> SimulationSnapshot`, `isComplete`). The app was built
first against a fake `MockSimulation`; the real `Simulation` is a **drop-in swap**
behind that protocol — one line in `SimulationController` (init + reset).

**Build/lint conventions:**
- SwiftPM auto-includes engine source files; the Xcode app uses file-system
  synchronized groups (new files in synced folders auto-add).
- Lint is strict: `swiftlint lint --strict` fails on warnings; short identifiers
  must be whitelisted in `.swiftlint.yml`; pre-commit auto-runs swiftformat.
- **SwiftPM names object files by basename** → two files with the same basename
  in different folders = "multiple producers" build error. Keep basenames unique.
- New engine files go in the **singular** `Agent/` folder (an old empty `Agents/`
  plural folder caused a duplicate-basename clash; it was deleted).

---

## 4. The full step map — stages S0 → S5 (from plan §6)

The plan has **no calendar** — it is **dependency-ordered stages** with exit
criteria. Work them in order; don't start a stage until the previous one's exit
criteria hold. **S2 is the submission floor** (the minimum shippable product).

**Two governing rules (plan §6.1):**
- *Rule 1 — the core journey is the product.* Nothing above S2 starts until every
  row of S2 is true.
- *Rule 2 — once S2 exits, evidence outranks features.* States, accessibility, and
  the recording (S3–S4) come before any remaining feature.

### S0 — Foundation & risk retirement  ✅ code complete
Repo/package, `Vec2`/`GridCoord`/`GridGeometry`/`SeededRNG`, `SafetyStandards`,
`VenueModel`/`Exit`/`Obstacle`, **lock `SimulationSnapshot`**, ship
`MockSimulation`; app `TabView` shell on device; AI-availability spike;
color/motion tokens.
*Exit:* clean build + archive/install on device · ≥6 engine tests · record
`SystemLanguageModel.availability` · SF Symbols resolved · AI assets downloaded.
**Still open (device-only, USER):** archive→install on iPhone; run & record
`SystemLanguageModel.availability`; confirm Apple Intelligence assets downloaded.

### S1 — Walking skeleton  ✅ engine done & verified (see §5)
`FlowField` (multi-source, wall-aware, no corner-cutting) · `SpatialHash` ·
`AgentSpawner` · drive force + full Helbing social force (pedestrian
repulsion/contact/friction + wall force) · semi-implicit Euler substepping at
H=1/120 with dt clamp · **swap Mock→real `Simulation`** · Instruments profile.
*Exit:* flow field reaches all passable cells · 10 000-step integrator stability
(no NaN) · agents spawn→path→all evacuate · **≥55 fps in Instruments on device** ·
tag `golden-skeleton`.

### S2 — ★ THE CORE JOURNEY (the submission floor)  ⬅ **NEXT STAGE**
- **Engine (Dev A):** `DensityGrid` (bin + separable blur); `Metrics` (clearance,
  peak density, at-risk person-seconds); **fire cellular automaton + smoke
  diffusion** with dirty-flag flow-field recompute; casualty classification;
  `SafetyScore`; `VerdictRules`; `RunEventLog`; live-escalation predicates;
  **Apply & re-run** (deterministic engine-side geometry edit + before/after score).
- **App (Dev B):** ★ **parametric editor** (rooms/exits/props via handles,
  steppers, typed dimensions on the 0.25 m grid, undo/redo); hazard + density-glow
  rendering; results sheet + score ring + verdict badges + canned banner strings;
  Spaces library (~4 furnished presets); RALLY sprite + card with canned lines.
- *Exit (all on device, airplane mode, 3 consecutive runs, zero crashes):* full
  journey launch→shape venue→crowd→alarm→fire/emotions→escalation banner→verdict
  +score+reasons **with units** · **RALLY names a fix → Apply → re-run → better
  score** · score reproduces §2.8 worked examples (Concert Crush=7, Office=98) ·
  verdict correct across all 6 branches · **faster-is-slower reproduces** ·
  determinism (same seed → identical clearance) · tag `golden-core`.

### S3 — Evidence-grade (ordered by points-per-hour)
States & recovery (empty/loading/offline/unavailable/failure) → accessibility
pass (VoiceOver, Dynamic Type, Reduce Motion, 44 pt targets) → **on-device coach**
(`CoachingService`, `@Generable` schemas, V1–V8 validation gate, fallback wiring,
streaming UI) → anticipatory dodge + stumble → aisle clear-width analysis →
haptics → 3 SFX cues → debug touch-indicator overlay.
*Exit:* RALLY renders on-device in airplane mode + forced-fallback identical
layout · V1–V8 gate green · every state reachable · VoiceOver completes journey ·
tag `golden-evidence` + **pin the toolchain**.

### S4 — Evidence production (the recording)
Device setup → **one unbroken take of the core journey** → coach+fallback beat →
states reel + VoiceOver → spoken limitations → voiceover laid over → 30-min soak.
*Exit:* a complete, submittable video exists. Tag `release-candidate`. **CODE FREEZE.**

### S5 — Lock & submit
Submission form (§E.4) · secret scan · upload + verify link logged-out ·
**submit before 7 Aug 11:59 PM IST, not at it.**

**Cut order if time is short (§6.9), first to go:** widget/Siri → `.egress`
export → AI heatmap → Monte Carlo → PDF report → Learn quiz → flood → replay-seek
→ Metal glow → audio bus → Liquid Glass polish → emotes.
**Never cut (the floor):** parametric editor · fire & smoke · agent emotions ·
furnished venues · verdict engine · Apply & re-run · RALLY (degrades to static
sprite + canned text) · states matrix · accessibility pass · the recording.

---

## 5. WHERE WE ARE RIGHT NOW (as of 2026-08-01)

**S1 engine is complete, swapped in, and verified.** The app runs the *real*
engine, not the mock.

**Done & green:**
- Engine builds; **51 tests pass** across 11 suites (`swift test --package-path
  EgressEngine`).
- App builds (`xcodebuild -scheme Egress` for an iOS-26.5 simulator — the
  **iPhone 17** family sims match the runtime; iPhone 16 sims are on a
  non-matching runtime).
- Ran on **iPhone 17 Simulator**: 120 agents spawn → converge on the bottom-centre
  exit (visible jam cone) → **100% evacuated in 22.6 s.**

**S1 remaining (device-only — USER must do, needs a physical iPhone):**
1. **≥55 fps sustained Instruments profile** at the shipped agent count (it ran
   fine on the Simulator, but the exit criterion is a *device* Instruments run).
2. **Tag `golden-skeleton`** + archive the build.

**Also still open from S0 (device-only — USER):** archive→install on device; run
and record `SystemLanguageModel.availability`; confirm Apple Intelligence assets.

**➡ The next code work is S2 (the core journey).** Recommended starting point:
the engine side, in dependency order — `DensityGrid` → `Metrics` → hazards
(fire CA + smoke) → `SafetyScore` → `VerdictRules` → Apply & re-run — because the
score/verdict need density and metrics as inputs. (Or start the parametric editor
on the app side in parallel; both are S2 rows.) Confirm with the user which they
want first, and whether to guide or apply.

---

## 6. Engine internals already built (so a new chat knows the code state)

Key files in `EgressEngine/Sources/EgressEngine/`:

- **`Navigation/BlockedCells.swift`** — `BlockedCells.of(venue) -> Set<GridCoord>`.
  Rasterises **walls** (Bresenham grid-walk, 8-connected chain seals a
  4-connected flood) **+ ALL obstacles** (cell-range overlap) into the impassable
  set. Plan §2.4: impassable = walls + obstacle footprints + active fire cells.
  `isRelocatable` does **not** affect passability — it only controls whether RALLY
  may move an obstacle.
- **`Navigation/FlowField.swift`** — multi-source BFS from exit cells (cost 0),
  giving cost-to-nearest-exit + downhill direction (central-difference gradient),
  no corner-cutting. *Simplification:* currently **4-connected BFS**, not the
  8-connected diagonal Dijkstra §2.4 ultimately wants — acceptable for the
  skeleton, upgrade later.
- **`Navigation/WallField.swift`** — companion multi-source flood from blocked
  cells giving nearest-wall **distance (d_w)** + **outward normal (n_w)**. The grid
  boundary is **not** a wall (so exits on the edge aren't repelled). Feeds the soft
  wall force.
- **`Agent/Agent.swift`** — internal sim struct (position, velocity, mobility,
  emotion, status, radius, baseSpeed) with a `.render` computed property that
  bridges to the slim UI-facing `AgentRender`. Free speed varies by mobility class.
- **`Agent/AgentSpawner.swift`** — deterministic (`SeededRNG` shuffle),
  reachability-filtered spawn: keeps cells where
  `field.isReachable(cell) && field.cost(at: cell) > 0` (excludes walls, sealed
  pockets, and exit cells), distinct free cells.
- **`Spatial/SpatialHash.swift`** — uniform-grid bins for O(1) neighbour queries;
  search reach = `floor(radius/binSize) + 1` (**floor**, not ceil — the R==binSize
  boundary case can straddle two bins, so floor+1 avoids false negatives).
- **`Standards/SimConstants.swift`** — engine tuning knobs (§2.2): TAU 0.5,
  V_MAX 2.5, A_MAX 20, R_INT 1.2, A_PED 12, B_PED 0.20, K_BODY 60, K_FRIC 40,
  A_WALL 8, B_WALL 0.20, substep 1/120, maxFrame 1/30, plus `arousalFactor`.
  These are **tuning coefficients, not citable physical truth** — that's why they
  live here and not in `SafetyStandards` (which holds citable values the coach may
  quote).
- **`Simulation/Simulation.swift`** — `final class Simulation: SimulationRunning`.
  Builds static navigation once (blocked → flow field + wall field), spawns the
  crowd, then each frame:
  - Fixed-timestep accumulator (frame-rate independent + reproducible).
  - Per substep: snapshot `previous = agents` (**Jacobi update** → order-
    independent, deterministic), build `SpatialHash`.
  - Per active agent: if on a cost-0 cell → evacuated; else acceleration =
    drive term `(v0·ê − v)/τ` + `pedestrianAcceleration` (Helbing repulsion/body/
    friction over hash candidates) + `wallAcceleration` (same shape vs nearest
    wall), clamped to A_MAX; velocity clamped to V_MAX.
  - **Axis-separated hard wall slide**: move x and y independently, cancel any
    component that would enter a blocked cell.
  - `clampToWorld` keeps agents on the grid.

---

## 7. Gotchas learned (so we don't repeat them)

- Duplicate basenames across folders → SwiftPM "multiple producers" error. New
  engine files go in **singular `Agent/`**.
- Flow field's boundary gradient can push agents into walls; the **axis-separated
  wall slide** fixes agents freezing on blocked cells.
- Simulator: the app needs the **iOS 26.5 runtime**; target **iPhone 17** family
  sims, not iPhone 16 (non-matching runtime → "Unable to find a destination").
- zsh `${PIPESTATUS[0]}` came back empty when piping xcodebuild; write the build
  log to a file and check `echo "EXIT=$?"` instead.

---

## 8. Verification commands

```bash
# Engine — run every time engine code changes, must be green before next step
swift test --package-path EgressEngine
```

```bash
# App build (pick a matching iOS-26.5 iPhone 17 simulator id from `xcrun simctl list`)
xcodebuild -scheme Egress -destination 'platform=iOS Simulator,name=iPhone 17' build
```

---

## 9. First message to send in the new chat

Something like:
> "Continue Egress. S1 engine is done and verified (51 tests green, real engine
> swapped in, 100% evac on Simulator). Let's start **S2 — the core journey**,
> step by step, same as before: WHERE + WHY first, one step at a time, I'll tell
> you guide-vs-apply each step, and you verify with `swift test` before moving on.
> Start with the engine side: `DensityGrid` first."
