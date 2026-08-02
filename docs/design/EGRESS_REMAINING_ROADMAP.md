# EGRESS — REMAINING-WORK ROADMAP (S2 finish → S3 → S4 → S5)

> **Purpose.** A single working checklist of *what is done* and *what is left* to fully complete Egress
> for the IndeHub Hackathon 2026. Use this as the driving document in future sessions — tick boxes as you
> go. Authoritative spec is `EGRESS_BUILD_PLAN_v3.md`; this file is the progress ledger against it.
>
> **Last updated:** 2026-08-02. **Engine:** 134 tests / 29 suites green (all uncommitted on `main`).
> **App:** builds clean, core journey verified live on iPhone 17 Simulator.

---

## 0. Ground facts (don't re-derive these)

- **Product:** offline, 100%-on-device iPhone crowd-evacuation simulator. Pocket Brain / Local LLM track.
- **Submission is video-only** (no paid Apple account / TestFlight). **The recording is the sole evidence.**
- **Hard deadlines (IST):** submission **7 Aug 2026, 11:59 PM**; Bengaluru finale **22 Aug 2026**.
- **Two targets:** `EgressEngine` (pure Swift, Foundation+simd only) and `Egress` (SwiftUI app).
- **Test command:** `swift test --package-path EgressEngine`
- **swiftlint is NOT installed on this Mac.** swiftformat runs on pre-commit.
- **Simulator note:** haptics never fire on any simulator (silent-degrade is *correct*); audio does play;
  `control` tap coords are in **points (402×874)**, not screenshot pixels. iPhone-17 sims match the runtime.
- **Rubric reality (governs every trade):** criterion 06 (demonstration evidence) **gates** criteria 01–04.
  A feature nobody can see in the video scores as Weak. **After S2, evidence beats features.**

---

## 1. WHERE WE ARE

**S2 (the core journey / submission floor) is functionally complete and demoable end-to-end** — but two
exit criteria are not yet met (see §3), so S2 is not signed off. Everything in S3+ is still open.

```
S0 ─ S1 ─ [S2 built, not signed off] ─ S3 (open) ─ S4 (open) ─ S5 (open)
                     ▲ you are here
```

---

## 2. WHAT IS DONE ✅

### 2.1 Engine (`EgressEngine`) — 100% of the S2 engine scope, 134 tests green

- [x] Navigation: `FlowField` (4-connected BFS, wall-aware), `WallField` (soft wall force), `BlockedCells`,
      `AgentSpawner` (reachability-filtered, deterministic), `SpatialHash`.
- [x] Movement physics: Helbing social + wall force, driving force, semi-implicit Euler at H=1/120,
      A_MAX/V_MAX clamps, axis-separated hard wall-slide. Jacobi update ⇒ reproducible.
- [x] `DensityGrid` (bin + separable box-blur) and `Metrics` (clearance, peak density + location,
      at-risk person-seconds, casualties, trapped count).
- [x] Hazards: fire cellular automaton + smoke diffusion + casualty classification (injured→dead).
- [x] Scoring + verdict: `SafetyScore` (C/D/R/T sub-penalties), `VerdictRules` (6-branch, §3.3 order,
      reasons-with-units), `RunEventLog` + `RunSummary`, `EscalationTracker`.
- [x] RALLY engine side: `Fix` (widen/add/relocate), `.feasibility`, `.apply`, `RallyCoach.suggest`,
      `ApplyRerunTests` capstone (non-PASS → fix → apply → re-run same seed → better score).
- [x] Panic / emotion dynamics + **faster-is-slower** G2 sweep (walled-throat fixture, panicSpeed knob).
- [x] **Pocket-clog fix** (calibration-safe, via `VenuePreset.nightclub` bar/stage flush-to-top geometry;
      guarded by `SimulationTests.vaultLeavesNoOneFrozen`). Engine files reverted to HEAD-exact.

### 2.2 App (`Egress`) — core journey verified live on iPhone 17 sim

- [x] `SimulationController` holds the concrete `Simulation`; assembles `RunResult`
      (Metrics→Verdict→SafetyScore→RALLY Fix); `applyFixAndRerun` (widen + re-run same seed, before/after).
- [x] **Results money-shot** (`ResultsSheet`): animated Safety-Score ring + PASS/WARN/FAIL badge +
      reasons-with-units + RALLY coach card + **Apply & re-run** + improvement chip.
- [x] **Escalation banner** (`EscalationBanner`) — live amber/red, band-specific.
- [x] **Parametric editor** (`Editor/`): room W/H steppers, crowd slider with load-band, 4 draw tools
      (wall/exit/object/erase), drag-to-place with 0.25 m snapping, engine-faithful simulable gate,
      derives VenueModel + SimulationConfig. **Interior walls render in the live sim** (`VenueScenery`).
- [x] **Spaces presets** (`VenuePreset` ×5: office/nightclub/concertHall/transitHub/classroom) with real
      mini-plan thumbnails; `SpacesRootView` = preset scroller + Recent-runs history; `RunRecord` persists.
- [x] **AI coach (RALLY) scaffold**: canned path **live & demoable** (`CannedCoach` + `CoachFacts` grounding);
      FoundationModels path fully written (`FoundationModelsCoach`, 3 @Generable schemas, V1–V8 gate) but
      **behind `#if EGRESS_FM_COACH` — OFF by default** (needs on-device Xcode-27 verification).
- [x] **Feedback layer** (`Feedback/`): synthesized 8-bit SFX (confirmed real on sim), 3 CoreHaptics
      patterns (degrade silently on sim), `FeedbackSettings`, `SettingsSheet`.
- [x] **Partial accessibility**: canvas = one a11y element with live value; Results/score-ring/RALLY
      VoiceOver structure; verdict/escalation announcements (throttled); Reduce-Motion on banner + score ring.

---

## 3. OPEN ISSUES CARRIED FORWARD (block S2 sign-off) ⚠️

These were discovered while fixing the pocket-clog and are **deferred by explicit user decision**.
They must be resolved to finish S2's money-shot + reproducibility exit criteria.

- [ ] **Money-shot is not reliably dramatic.** The Vault never *legitimately* failed — its old FAIL was the
      clog bug. Fixed, it's a clean PASS ~90. The engine clears doors ~4× faster than real crowds, so preset
      tuning alone can't produce a robust FAIL→fix→better-score. **Pick one:** (a) fixed-dt stepping + a
      firmed-up crowd for a reliable FAIL [recommended]; (b) recalibrate engine door-flow (slower throat);
      (c) accept an honest WARN→PASS demo.
- [ ] **App is non-deterministic vs tests.** `SimulationController.advance(to:)` steps at *variable
      real-frame dt* while the engine samples emotions/density once per `step()`. Same seed ⇒ different
      outcome in-app vs fixed-dt tests. **Fix:** accumulator pattern — carry leftover time, step in fixed
      1/60 chunks. This is the prerequisite for option (a) above and for S2 criterion 6 (determinism).

---

## 4. REMAINING WORK BY STAGE

### 4.1 Finish S2 — sign off the submission floor (§6.5)

- [ ] Fix `SimulationController` to **step at fixed dt** (accumulator). *(unblocks determinism + money-shot)*
- [ ] Resolve the **money-shot** (choose a/b/c above; make FAIL→Apply→better-score reliable on device).
- [ ] Verify score formula reproduces worked examples (**Concert Crush = 7, Office = 98**).
- [ ] Verify **verdict order correct across all 6 branches**.
- [ ] Verify **faster-is-slower reproduces** (non-monotonic panic sweep) — engine test exists; confirm.
- [ ] Verify **determinism: same seed → identical clearance** (now unblocked by the dt fix).
- [ ] Run the whole journey **on device, airplane mode, 3 consecutive runs, zero crashes**.
- [ ] **Tag `golden-core`** and archive the build.

### 4.2 S3 — Evidence-grade (this is where 4s and 5s come from) (§6.6)

Ordered by points-per-hour (the plan's order). **Evidence items sit above features.**

**#1 — States & recovery matrix (§E.2)** — *highest value, cheap; criterion 02. The deliberate fallback is
the single most valuable 10 s in the video.*
- [ ] **Empty** — Simulate first-launch: dimmed blueprint grid + `NO SPACE LOADED` + one primary CTA to Spaces.
- [ ] **Loading** — determinate indicator during first flow-field solve / model warm-up (never a frozen canvas).
- [ ] **Unavailable feature** — canned coach on FM-unavailable, *identical card layout, different words* (done;
      verify it reads as a distinct on-screen state for the reel).
- [ ] **Failure / recovery** — thermal or frame-rate pressure → visible agent-count step-down notice + quiet
      mono HUD line when above budget.
- [ ] **Paused on return** — returning from background never auto-resumes; calm centred `PAUSED` panel.
- [ ] **Permission** — plainly state "asks for nothing, sends nothing" (no fabricated denial screen).
- [ ] **Offline** — airplane mode throughout (already true by construction; make sure it's *shown*).

**#2 — Accessibility pass on the primary path (§5.6)** — *criterion 04; the v3 inversion's whole point.*
- [ ] **Parametric editor primary path** — make element placement VoiceOver-operable (currently drag-only):
  - [ ] "Add exit on wall {N/E/S/W}" control.
  - [ ] Per-exit **clear-width stepper** (0.1 m increments).
  - [ ] **Obstacle list** — select to reposition/remove; structural props show a disabled `LOCKED — STRUCTURAL` row.
- [ ] **Colour-blind pattern fills** on the density canvas (`SimCanvasRenderer`): no-fill / sparse dots /
      diagonal hatch / cross-hatch per band (currently colour-only).
- [ ] Reduce-Motion full pass per the §5.6 table (audit every decorative animation).
- [ ] Dynamic Type: Results/RALLY/reasons uncapped to AX5 without truncation; HUD collapses to summary line.
- [ ] 44×44 pt hit targets everywhere; explicit focus order; every icon-only control has a label.
- [ ] **Accessibility Inspector clean** on Results, RALLY, Spaces; VoiceOver completes the journey with no dead end.

**#3 — On-device coach (§3.5)** — *criterion 03; device + Xcode-27 only.*
- [ ] Enable `EGRESS_FM_COACH`; verify @Generable/@Guide spellings compile on-device (Xcode 27).
- [ ] `SystemLanguageModel.availability` check drives the model→canned fallback.
- [ ] Prove **V1–V8 validation gate** green, each with a crafted malformed-output fixture.
- [ ] Streaming UI ("RALLY is thinking…" → text) on device; forced-fallback run yields identical layout.

**#4–#5 — Engine polish (optional, Dev A; only if time after evidence items)**
- [ ] Anticipatory dodge + stumble (§2.13.4–5) — criterion 02/05.
- [ ] Aisle clear-width analysis + verdict reason 4d (§2.13.7) — criterion 01/02.

**#6–#8 — Feedback + recording aids**
- [ ] Haptics feel-test on device (3 CoreHaptics patterns, 1-per-0.5 s budget) — built, unverifiable on sim.
- [ ] Confirm the 3 SFX cues on device.
- [ ] **Touch-indicator debug overlay** (`#if DEBUG`, 32 pt translucent circle on touch-down) — for the recording.

**S3 exit criteria (§6.6):**
- [ ] Every §E.2 state reachable and visually resolved.
- [ ] VoiceOver completes the primary journey end to end, no dead end.
- [ ] Accessibility Inspector clean; AX5 Dynamic Type without truncation.
- [ ] RALLY renders on-device model text in airplane mode; forced fallback = identical layout, canned lines.
- [ ] **Tag `golden-evidence`; PIN the toolchain** (record exact Xcode build + device OS build; no updates after).

### 4.3 S4 — Evidence production (§6.7 / §E.3)

- [ ] Device setup checklist (§E.5).
- [ ] **One unbroken take of the core journey** (0:15–2:15) — the only beat that must never be cut.
- [ ] Coach + deliberate-fallback beat.
- [ ] States reel + ~15 s **audible VoiceOver**.
- [ ] Limitations, spoken (time-compressed hazards; model writes words, engine supplies numbers; iPhone-only;
      "educational analysis, not certified engineering advice").
- [ ] Voiceover recorded separately and laid over (not live into the mic).
- [ ] On-screen `FUNCTIONAL` / `DEMO DATA` / `NOT BUILT` labels; fixed sim seed.
- [ ] 30-minute soak: no crash, no memory growth, thermal below `.serious`.
- [ ] **Tag `release-candidate`. CODE FREEZE.**

### 4.4 S5 — Lock and submit (§6.8)

- [ ] Submission form (§E.4): problem/user/product; platforms + technologies **that actually run on the demo
      device**; third-party + AI-tool disclosure; track evidence; known limitations + judging instructions with
      a timestamp index.
- [ ] Secret scan clean.
- [ ] Video uploaded; link verified from a **logged-out** browser.
- [ ] **Submitted before 7 Aug 11:59 PM IST — not at it.**

### 4.5 Device-only leftovers (S0/S1 — needs physical iPhone + Xcode 27; USER)

- [ ] Archive → install on device.
- [ ] Run `SystemLanguageModel.availability`, record result; confirm Apple Intelligence assets downloaded online.
- [ ] **≥55 fps Instruments** profile at shipped agent count (device, not sim).
- [ ] Tag `golden-skeleton` (if not already) + archive.

---

## 5. WHAT *NOT* TO BUILD (cut in v3 — §6.9; deleted, not deferred)

Do not spend time here — re-litigating the cut list under pressure is the failure mode it exists to prevent:

> widget / Siri · `.egress` export · AI heatmap · Monte Carlo · PDF report · **Learn quiz & case studies** ·
> flood hazard · replay-seek + ring buffer · Metal glow · audio bus graph · Liquid-Glass / reorderable-grid /
> symbol-effect polish · expressive emotes · obstacle memory · freehand drawing · SFX beyond 3 cues.

Consequence: **the Learn tab staying a stub is by design.** Space Detail screen, Pre-run config sheet, A/B
charts, and PDF export are all Should/Could or cut — ignore unless everything above is done.

**The floor — never cut:** parametric editor · fire & smoke · agent emotions · furnished venues · verdict
engine · Apply & re-run · RALLY (degrading to static sprite + canned text) · the states matrix · the
accessibility pass · the recording.

---

## 6. Reference tables (status snapshots)

### 6.1 Screen inventory (§4.2)

| Screen | Status | Note |
|---|---|---|
| Workspace Library (Spaces root) | ✅ done | presets + run history |
| Space Detail | ❌ not built | cut-zone; cards jump straight to editor |
| Editor | 🟡 partial | drag-place verified; parametric placement + undo/redo + scale caption missing |
| Pre-run Config | ❌ not built | cut-zone |
| Sim Canvas | 🟡 partial | canvas + HUD chips + banner; no scrubber / playback row |
| Results | ✅ done | A/B side-by-side + charts absent (charts cut) |
| Learn Home | ❌ stub | **by design — cut** |
| Case Study | ❌ not built | **by design — cut** |
| Settings | ✅ done | |

### 6.2 States matrix (§E.2 — floor, never cut)

| State | Status |
|---|---|
| Empty | 🟡 Spaces yes; Simulate first-launch no |
| Loading | ❌ |
| Offline | ✅ by construction |
| Unavailable feature | ✅ canned path |
| Failure / recovery | ❌ |
| Paused on return | ❌ |
| Permission | 🟡 stated in Settings only |

### 6.3 Accessibility (§5.6 — floor, never cut)

| Item | Status |
|---|---|
| Canvas = one a11y element | ✅ |
| Results / score-ring / RALLY VoiceOver | ✅ |
| Parametric editor primary path | ❌ **biggest gap** |
| Colour-blind pattern fills (canvas) | ❌ |
| Reduce Motion full pass | 🟡 |
| Accessibility Inspector audit | ❌ |

---

## 7. Housekeeping

- **⚠ ~22 tested steps are uncommitted on `main`.** The pocket-clog fix is a clean checkpoint — strongly
  consider `git branch` + commit before the next session for a safety net (user has been declining to keep
  building; do it when ready).
- **Conventions:** SwiftPM auto-includes engine files; the app uses file-system-synchronized groups (new
  files in synced folders auto-add). Lint is strict on device (`swiftlint lint --strict`) — short identifiers
  must be in `.swiftlint.yml`'s excluded list.

---

### One-line starting point for the next session

> *"Fix `SimulationController` to step at fixed dt (accumulator), make a reliable money-shot FAIL→Apply→
> better-score, run the §6.5 exit-criteria checks and tag `golden-core` — then start S3 with the states &
> recovery matrix."*
