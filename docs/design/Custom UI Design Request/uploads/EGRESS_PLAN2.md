# EGRESS — BUILD PLAN

> Canonical planning document. Assembled from Phases 0–8 of the Master Planning & Build Prompt v4, with **all PATCH blocks applied inline**. Provenance for every change is in **Appendix 1**; amendments that target the source prompt's requirement blocks rather than this file are in **Appendix 2**.
>
> **Product:** Egress — an offline, on-device crowd-evacuation simulator for iPhone.
> **Event:** IndeHub Apple-native hackathon · build window **22 July – 7 August 2026 (17 calendar days, D1–D17)** · 2 developers.
> **Disclaimer carried by the product:** *educational analysis, not certified engineering advice.*

---

## STATUS TRACKER

| Phase | Title | Status | Date |
|---|---|:--:|---|
| 0 | Understand + Commit | ✅ | 2026-07-22 |
| 1 | A. Architecture | ✅ | 2026-07-22 |
| 2 | Simulation Deep Spec (reqs 1–4) | ✅ | 2026-07-22 |
| 3 | Verdict + Mascot + Retro SFX (reqs 5–6) | ✅ | 2026-07-22 |
| 4 | C. UI/UX parts 1–3 | ✅ | 2026-07-22 |
| 5 | C. UI/UX parts 4–6 + accessibility | ✅ | 2026-07-22 |
| 6 | B. Day-by-day plan | ✅ | 2026-07-22 |
| 7 | D. Risk register · E. Demo script | ✅ | 2026-07-22 |
| 8 | F. Learning · Discipline · DoD · consistency | ✅ | 2026-07-22 |
| — | **PLANNING COMPLETE — build starts D1, Jul 22** | ✅ | — |

## STATE CAPSULE (final — ground truth for the build)

**Track:** Pocket Brain + Wellness overlay; 100% offline on-device Foundation Models.
**Platform:** iPhone-ONLY. Demo iPhone 16 on **stable iOS 26**; build toolchain Xcode 27 · Swift 6.4 · iOS 27 SDK; deployment target iOS 26; every iOS-27 API availability-gated, fallback-first.
**Targets:** `Egress` app; pure `EgressEngine` library (Foundation + simd only); Swift Testing.
**Engine:** `SafetyStandards` · `SimConstants` · `VerdictConstants`; `VenueModel`/`Exit`/`Obstacle`; `Agent`/`AgentTraits`/`EmotionalState`; `FlowField` (multi-source Dijkstra, no corner-cutting); `HazardField` (Fire CA / Smoke / Flood); `SpatialHash`; **`Simulation` = plain `final class`, NOT `@MainActor`** (PATCH-01 — app owns one instance on the main actor; each Monte Carlo task owns its own); `SimulationSnapshot` contract; `Metrics`/`DensityGrid`/`SafetyScore`; `MonteCarlo`; `RunEventLog`; `VerdictRules`. Social force τ 0.5 / A_PED 12 / K_BODY 60 / K_FRIC 40 / R_INT 1.2; H = 1/120 s, dt ≤ 1/30 s; hazards 15 Hz. Score = 100 − C(min 60, cas×25) − D(×25) − R(×20) − T(×15). Seeded RNG ⇒ reproducible demo.
**Verdict:** PASS 80 / FAIL 50 / PEAK 5 / CRUSH 7 / RISK 0.15; cap = clamp(3 × target, 300, 600) s; any occupant trapped ⇒ FAIL; **rules table = authority, Safety Score = communication**; escalation on first crossing, 6 s cooldown.
**Obstacles & NPC intelligence (§2.13):** every venue **furnished by default** (no empty boxes); `Obstacle.isRelocatable` gates coach relocation fixes; **anticipatory dodge** raycast (`T_LOOK` 0.8 s, `A_DODGE` 10, `DODGE_COMMIT` 0.6 s) gated by `awareness_eff` — so smoke-blinded and panicked agents crash instead of swerving; **bump → stumble → obstacle memory**; **aisle clear-width analysis** reusing `FlowField.wallDist` → WARN reason 4d, **score-neutral by design**; expressive emote layer (astonished / confused / frustrated / distressed / relieved) is **display-only, zero physics**, suppressed on real-incident presets; fire and water are **editor-placeable hazard props** via the existing `HazardSeed`. **No LLM per agent — ever** (five orders of magnitude over budget; would break determinism). Kill-switch: `A_DODGE = 0`.
**Mascot:** RALLY (RP-25), 5 animation states, never colour-alone.
**AI:** three `@Generable` schemas, `joke` field on PASS only; model emits `MetricKey` enums, **never numerals**; V1–V8 validation gate → `CannedCoach`.
**UI:** canvas ignores safe area and stays dark in Light Mode; **hue = meaning, shape = affordance**; 1-finger draws when armed / **2-finger always pans** / 3–40 pt per cell; scrubber live = progress, post-run = seek via 10 Hz ring buffer ≤ 16 MB; `.sensoryFeedback` + exactly 3 CoreHaptics patterns, 1 haptic per 0.5 s; accessibility canvas = single element; **freehand drawing is NOT VoiceOver-operable → accessible path = presets + parametric form (disclosed)**.
**Plan:** Dev A = engine, Dev B = app, parallel via `MockSimulation`. **G0 D2 · G1 D5 · G2 D9 MUST `golden-must` · G3 D13 SHOULD + toolchain PIN · G4 D15 FREEZE · G5 D17 submit.** Explain-back review daily; golden build at every gate. Cut order: widget → `.egress` → heatmap/apply → Monte Carlo → PDF → quiz → A/B → flood → SFX. Floor never cut: editor + fire + emotions + verdict + RALLY.
**Risk:** R-01 engine overrun · R-02 60 fps · R-03 AI availability (**retire on D1**) · R-09 physics wow · R-15 disaster-content ethics (§D.1 binding). Demo 180 s, airplane mode throughout; contingency variant B if AI is unavailable.
**Cut / out of scope:** isometric sandbox · RoomPlan · notifications & daily-drill widget · iPad / macOS / Pencil.
**Verify 🔴 at G0:** SF Symbol strings · `ConcentricRectangle` · `@Generable`/`@Guide` spellings · Metal shader modifier names · Low Power Mode haptic suppression.

## TABLE OF CONTENTS

- [0. Phase 0 — Understand + Commit](#0-phase-0--understand--commit)
- [A. Architecture](#a-architecture)
- [Simulation Deep Spec (Reqs 1–4)](#simulation-deep-spec-reqs-14)
  - [§2.13 Obstacle interaction · NPC behavioural intelligence · expressive emotion](#213-obstacle-interaction--npc-behavioural-intelligence--expressive-emotion)
- [Verdict Engine + Mascot + Retro SFX (Reqs 5–6)](#verdict-engine--mascot--retro-sfx-reqs-56)
- [C. UI/UX — Layout · Colour · SF Symbols (Parts 1–3)](#c-uiux--layout--colour--sf-symbols-parts-13)
- [C. UI/UX — Gestures · Springs · Haptics/Audio + Accessibility (Parts 4–6)](#c-uiux--gestures--springs--hapticsaudio--accessibility-parts-46)
- [B. Day-by-Day Build Plan (Jul 22 – Aug 7)](#b-day-by-day-build-plan-jul-22--aug-7-2026)
- [D. Risk Register](#d-risk-register)
- [E. Demo, README & Recording](#e-demo-readme--recording)
- [F. Learning Notes · Discipline · Definition of Done](#f-swift-learning-notes--discipline--definition-of-done)
- [Appendix 1 — Applied patch log](#appendix-1--applied-patch-log)
- [Appendix 2 — Amendments to the Master Prompt](#appendix-2--amendments-to-the-master-prompt-requirement-blocks)
- [Appendix 3 — Verification register (resolve at G0)](#appendix-3--verification-register-resolve-at-g0)

---

# 0. PHASE 0 — UNDERSTAND + COMMIT

## 0.1 Existing-work summary

1. **No repository or Swift code exists — greenfield.** Verified: uploads, working directory and all mounts contain zero `.swift` / `.xcodeproj` / `Package.swift`. Nothing to preserve.
2. Accumulated work is **planning only**: the Master Prompt v4 plus a set of **approved mockups** (retro-pixel × blueprint; "Metro Platform B" isometric sandbox with labelled dimensions; mascot card; game-style scenario cards). The spec is mature and internally consistent.
3. **Concept locked:** Egress — offline, on-device crowd-evacuation simulator; loop **Design → Simulate → Verdict**. (Pivoted from earlier rainwater-harvesting and AI-widget-generator concepts, both dropped.)
4. **Team / constraints:** 2 developers, intermediate, new to Swift (learning Swift is an explicit goal); window **Jul 22 – Aug 7, 2026**; deliverable = flawless live demo **or** screen recording. No App Store or TestFlight requirement; production-grade quality bar still applies.
5. **Toolchain (✅ verified):** Xcode 27 beta ships **Swift 6.4** with the iOS/iPadOS/macOS/visionOS/tvOS **27** SDKs and **requires an Apple Silicon Mac on macOS Tahoe 26.4+**. Deployment target **iOS 26**; every iOS-27 API is availability-gated with a working iOS-26 path.
6. **What already works toward the primary journey: nothing (0% code).** The journey exists only on paper.
7. **What is missing (i.e. everything):** engine package, renderer, editor, verdict engine, mascot, AI layer, SFX, all UI. **Critical path = the deterministic engine**; nothing is demoable until it runs.
8. **Top-3 delivery risks** (expanded in §D):
   - **(a)** The AI showcase may not run on the demo device — on-device Foundation Models needs an Apple-Intelligence-capable iPhone; on older hardware the Pocket-Brain payoff degrades to canned text *in the actual demo*.
   - **(b)** Engine complexity versus Swift newcomers in a 17-day window — social force + flow field + hazards + 200–500 agents at 60 fps is hard, and could consume the whole timeline.
   - **(c)** 60 fps rendering of hundreds of sprites plus Metal shaders on-device is unproven for this team.
9. **Mitigation posture:** MoSCoW discipline (deterministic core + canned verdict is Must; AI / mascot / SFX are Should; RoomPlan / heatmap / widget are Stretch); engine-first vertical slice; performance spike and demo-device confirmation on days 1–2; fallback-first for every WWDC26 adoption; pin one known-good toolchain after Aug 3.
10. **Smaller version if too broad:** iPhone-only · one venue (Nightclub) · fire hazard only · 200 agents · touch-drawn rooms · **canned** verdict text (no AI) · no A/B, Monte Carlo or PDF. That is exactly the **Must tier** — a complete, honest, demoable Design → Simulate → Verdict loop. Everything else layers on without breaking it.

## 0.2 Track decision — **CONFIRMED**

| Track | Fit | Verdict |
|---|---|---|
| **Pocket Brain** (on-device LLM must be *essential*) | On-device Foundation Models powers the payoff: plain-language diagnosis, geometry-grounded fixes, cross-run memory and Learn quizzes — fully offline. | ✅ **Primary (confirmed)** |
| **Wellness Loop** (usefulness · safety · empathy · accessibility · responsible language) | Egress *is* a safety and preparedness tool; the Learn tab, real case studies and accessibility rigour ride free. No medical claims. | ✅ **Overlay (confirmed)** |
| **MRR Machine** (believable paywall / subscription) | A "Pro" tier is plausible but bolts monetisation onto a safety tool. | ⚪ Rejected |
| **Voice Layer** (functional ElevenLabs use) | ElevenLabs is a **cloud** service → breaks the 100%-offline promise and re-architects the audio layer. | 🔴 Rejected |

**Reconciliation (Section 4A).** The **deterministic core** (simulation + threshold verdict engine) always works and is the honest safety spine — the Must tier. The **intelligence layer** (natural-language diagnosis, grounded fixes, session memory, quizzes) is where the on-device model is *essential* and is the track's showcase. On unsupported devices it degrades to templated text, disclosed as graceful degradation and never presented as the intended experience.

## 0.3 Assumptions & resolved questions

**Assumptions in force:**

- **A1** iPhone is the sole target; iPad adaptivity and Pencil authoring are **out of scope** (resolved by Q3).
- **A2** No LiDAR on the demo device → RoomPlan is **cut** (see PATCH-04).
- **A3** The demo runs in **airplane mode** to prove offline / on-device operation.
- **A4** **Zero third-party dependencies** — offline-first is a product virtue and a clean privacy story.
- **A5** Target **200 agents** for a guaranteed-smooth demo; higher counts are a tuning goal exposed as a config chip, clamped per PATCH-02.
- **A6** SwiftData is the in-app source of truth; `.egress` document sharing is Stretch.

**Blocking questions — answered:**

| # | Question | Answer |
|:--:|---|---|
| **Q1** | Track confirmation | **Pocket Brain + Wellness Loop.** 100% offline, on-device Foundation Models, no cloud services. |
| **Q2** | Exact demo device | **iPhone 16** (A18 / 8 GB — supports Apple Intelligence locally, so the AI coach runs live rather than as a fallback). Base model ⇒ **no LiDAR, no ProMotion** ⇒ 60 fps target and RoomPlan out. |
| **Q3** | iPad scope | **iPhone-only.** iPad and Apple Pencil authoring are completely out of scope; the full 17 days go to a flawless iPhone vertical slice. |

## 0.4 BUILD BRIEF

**Problem.** Professional crowd-evacuation analysis is locked inside expensive consultancy software; a small-venue operator or event organiser has no fast way to test whether a layout gets people out alive in an emergency.

**Target user.** Primary: a **small-venue operator / event organiser** without access to egress-modelling tools. Secondary (Learn / Wellness overlay): **students and the safety-curious public**.

**Primary outcome.** A clear, trustworthy **PASS / WARN / FAIL** verdict on a specific layout, with concrete **geometry-grounded fixes** that measurably improve clearance — computed **entirely on-device, offline**.

**End-to-end demo journey (launch → outcome).**
Launch → pick or draw a venue (demo: "Nightclub" preset or a quick touch-drawn room) → place exits and props on the 0.25 m grid → set the crowd (count / mix / alarm-delay chips) → **trigger the emergency** (shake or on-screen button) → watch a physically-grounded evacuation (density glow, fire, smoke, panic, herding) → **live bottleneck banner + haptic + sound** the moment a threshold is crossed → sim ends → **Safety Score + verdict + at-risk count + clearance time** → **RALLY coach card** with a grounded fix ("Widen Exit A to 1.2 m") → **apply & re-run** → **A/B** improved result → export **PDF**.
*Proof beat:* airplane mode is on throughout — the coaching is on-device Foundation Models.

**Selected platform.** **iPhone only** — the sole target (the "in your pocket" positioning, the CoreMotion trigger, and the iPhone 16 demo device with on-device Apple Intelligence). iPad, Apple Pencil, macOS, visionOS, Watch and TV are all out of scope; no cross-platform faking. A macOS path is noted but not built. *(Applied: PATCH-P1a.)*

**Tech table.**

| Tech | Purpose | Availability risk | Fallback |
|---|---|---|---|
| Xcode 27 · Swift 6.4 · iOS 27 SDK · deploy iOS 26 | build toolchain | ✅ confirmed; beta instability; needs Apple Silicon + macOS 26.4+ | pin a known-good build; iOS-26 code paths |
| SwiftUI + Observation + `TabView` / `NavigationStack` | all UI (iPhone-only) | ✅ | — *(Applied: PATCH-P1b.)* |
| `EgressEngine` Swift package · strict concurrency · Swift Testing | pure sim engine, unit-tested | ✅ | — |
| `TimelineView(.animation)` + `Canvas` | 60 fps sim rendering | ✅ core; perf at high agent counts 🔴 | dot rendering; lower agent count |
| Metal shader modifiers (`.colorEffect` / `.layerEffect` / `.distortionEffect`) | heat haze, smoke, density glow | 🔴 verify symbols + perf | plain SwiftUI fills and gradients |
| Foundation Models on-device (`SystemLanguageModel`, `@Generable`) | coach diagnosis, fixes, quizzes | ✅ at iOS 26; needs an AI-capable device; 2nd-gen features iOS 27 🔴 | **canned / templated lines (Must tier)** |
| SwiftData | saved venues and runs (source of truth) | ✅ | — |
| Swift Charts | evacuation curves, density timelines | ✅ | — |
| PDFKit | exportable safety report | ✅ | share a score screenshot |
| CoreHaptics + `.sensoryFeedback` | felt safety feedback | ✅ | sound + visual only |
| AVAudioEngine (all-original 8-bit SFX) | retro sound system | ✅ | master toggle → silent |
| CoreMotion | shake-to-trigger; gyro parallax | ✅ | on-screen button; static camera |
| App Intents + WidgetKit | "rerun my last drill" / widget | 🔴 device & region | in-app only (Stretch) |
| **Third-party** | **none by default** | — | offline-first is the story |

*(Applied: PATCH-P1c — the PencilKit / PaperKit row was deleted; iPad authoring is out of scope. RoomPlan was subsequently cut entirely — see PATCH-04.)*

**Architecture + data flow (sketch).**
`EgressEngine` (pure Swift — `SafetyStandards`, `VenueModel`, `Agent`, `SocialForceSim`, `FlowField`, `HazardField`, `Metrics`, `MonteCarlo`, `RunEventLog`, `VerdictRules`) **→ per-tick snapshot →** SwiftUI app (tabs **Spaces / Simulate / Learn**) **→** `TimelineView` + `Canvas` renderer at 60 fps.
Persistence: `SwiftData ⇄ VenueModel / RunRecord`. Intelligence: `RunEventLog + Metrics → FoundationModels @Generable (every field validated against engine numbers) → RALLY card`.

> **Invariant.** The engine computes truth; the UI renders it; the AI only explains it — it never invents a number, dimension or standard.

**Privacy / accessibility / safety / offline decisions.** 100% on-device; no network; no data leaves the device (the AI runs on-device — airplane-mode demo). Accessibility from day one: VoiceOver on results and coach text, Dynamic Type, reduce-motion fallback, **colour-blind-safe density palette with shape and pattern redundancy**, captions and transcripts for audio cues. Safety framing: **"educational analysis, not certified engineering advice"**; supportive coach tone on WARN/FAIL, **humour only in PASS**, never jokes about simulated casualties. Offline means full function.

**Prioritised sequence to a working vertical slice (Must tier first).**

1. `EgressEngine` skeleton → `SafetyStandards` + `VenueModel` + `Agent` + BFS `FlowField` + basic social force + one venue, one exit.
2. `Canvas` renderer at dot scale → spawn N agents → they walk to the exit at 60 fps.
3. Fire cellular automaton + smoke → live flow-field recompute (the crowd reroutes).
4. `Metrics` (clearance, peak density, at-risk) + Safety Score + threshold `VerdictRules` → **canned** PASS/WARN/FAIL banners + in-sim escalation.
5. Touch draw and edit rooms, place exits on the 0.25 m grid → **complete demoable loop**.

*Then Should:* emotion polish, retro SFX, RALLY + AI coaching + jokes, A/B compare, Monte Carlo, PDF, Liquid Glass. *Then Stretch:* AI heatmap debrief, apply-&-re-run, widget / Siri, `.egress` sharing.

**Out of scope.** App Store release; any backend, cloud or multiplayer; visionOS / Watch / TV; iPad, Pencil and macOS; live purchases; certified engineering claims; foldable layout; Private Cloud Compute and third-party model providers; ElevenLabs.

**Track-specific proof the demo must show.** *Pocket Brain:* the on-device model produces the diagnosis, grounded fixes and cross-run memory ("clearance improved from 4:10 to 2:45 since you widened Exit A") with the device in airplane mode. *Wellness overlay:* the Learn tab, a real case-study preset handled per §D.1, accessibility rigour, and responsible non-alarmist language.

---

# A. ARCHITECTURE

## A.1 Modules & targets — one-directional dependency

```text
EgressEngine (Swift Package, library)  ──imported by──▶  Egress (iOS app)
      imports: Foundation, simd  ONLY                    imports: SwiftUI, SwiftData,
      (no SwiftUI / UIKit / SwiftData)                   FoundationModels, AVFoundation,
                                                         CoreHaptics, CoreMotion, PDFKit,
                                                         Charts, TipKit, + EgressEngine
```

| Unit | Kind | Imports | Contains | Tested by |
|---|---|---|---|---|
| **`EgressEngine`** | Swift Package library (local, in-repo) | `Foundation`, `simd` | Deterministic sim core: standards, venue and agent models, flow field, hazards, spatial hash, integrator, metrics, Monte Carlo, event log, verdict rules | `EgressEngineTests` (Swift Testing) |
| **`Egress`** | iOS app target (SwiftUI) | SwiftUI, SwiftData, FoundationModels, AVFoundation, CoreHaptics, CoreMotion, PDFKit, Charts, TipKit, `EgressEngine` | UI (Spaces / Simulate / Learn), Canvas renderer, editor, persistence, AI coach seam, audio, haptics, design system | light UI and preview tests only |

**Why the package boundary:** it makes the "zero UI imports" guarantee *mechanical* — the engine physically cannot import SwiftUI, so it stays pure, `Sendable`, testable in isolation, and is the honest safety spine that always works. Proportionate: **one** package, not a constellation. 🟡 A local package was chosen over a single-target folder for enforced isolation and fast headless tests; it is trivially collapsible if it fights the beta toolchain.

## A.2 Coordinate system & core scalar types

- **World space** — continuous, in **metres**: `public typealias Vec2 = SIMD2<Double>` (fast, `Sendable`, SIMD math for the social force). Origin top-left, +x right, +y down (matches SwiftUI `Canvas`).
- **Grid space** — integer cells: `public struct GridCoord: Sendable, Hashable, Codable { var x, y: Int }`, cell edge = `SafetyStandards.cellSize` (0.25 m). Used by the flow field, hazards, walls and spatial-hash buckets.
- **`GridGeometry`** centralises every conversion: `cell(for: Vec2) -> GridCoord`, `center(of: GridCoord) -> Vec2`, `worldBounds`, `contains`. No coordinate math lives anywhere else.
- **`SpatialHash`** — bucket edge ≈ the social-force interaction radius (~1.0–1.2 m); `neighbors(of: Vec2, radius:) -> [Int]` in roughly O(1). Rebuilt each tick from agent positions (cheap; agents move well under one bucket per tick).

## A.3 Public engine API surface (load-bearing signatures)

```swift
public enum SafetyStandards {              // single source of truth, R-REALISM
    public static let cellSize = 0.25       // m
    public static let bodyRadius = 0.22     // m
    public static func desiredSpeed(_ m: MobilityClass) -> ClosedRange<Double>   // sampled at spawn
    public static let exitSpecificFlow = 1.2                 // persons / s / m
    public static let densityBands: DensityBands            // 1.8 / 4 / 5 / 7 p·m⁻²
    public static let geometryMinimums: GeometryMinimums     // door .9 / exit 1.2 / corridor 1.2–2.4 m
    public static let panicSpeed: ClosedRange<Double> = 1.8...2.2
    public static var hazardRates: HazardRates              // tunable, §2.7
}

public struct VenueModel: Sendable, Codable, Identifiable {
    public var id: UUID
    public var type: VenueType
    public var gridSize: GridSize                 // cells wide × tall
    public var walls: [Wall]                      // impassable cell runs
    public var exits: [Exit]                      // each carries clearWidth (m)
    public var obstacles: [Obstacle]              // real footprints, block movement; isRelocatable per §2.13.3
    public var decor: [DecorTile]                 // sim-inert
}

public struct Agent: Sendable, Identifiable {
    public let id: Int
    public var position: Vec2
    public var velocity: Vec2
    public let traits: AgentTraits
    public var emotion: EmotionalState
    public var status: AgentStatus                // .active / .evacuated / .injured / .dead
}

public struct SimulationConfig: Sendable {
    public var agentCount: Int                    // 200 default
    public var maxValidatedAgents: Int = 200      // PATCH-02 — perf budget clamp
    public var crowdMix: CrowdMix                 // fractions per MobilityClass
    public var alarmDelay: TimeInterval
    public var scenario: Scenario                 // preset hazard / config
    public var seed: UInt64                       // deterministic + Monte Carlo
}

public struct SimulationSnapshot: Sendable {      // the render / concurrency contract
    public let time: TimeInterval
    public let agents: [AgentRender]              // slim: pos, emotion, mobility, status
    public let hazards: HazardSnapshot            // fire / smoke / flood cell states
    public let density: DensityGrid               // p·m⁻² per cell, for glow + chips
    public let live: LiveMetrics                  // HUD: counts, worst density, % out
}

public final class Simulation {          // NOT @MainActor — see the isolation rule in §A.7
    public init(venue: VenueModel, config: SimulationConfig)
    public func step(dt: Double)                  // dt clamped to ≤ 1/30 s internally
    public func snapshot() -> SimulationSnapshot
    public private(set) var metrics: Metrics
    public private(set) var eventLog: RunEventLog
    public var isComplete: Bool                    // all out | time cap | casualty stop
}

public struct VerdictRules: Sendable {
    public static let `default`: VerdictRules
    public func evaluate(_ m: Metrics, log: RunEventLog, venue: VenueModel) -> Verdict
}

public enum MonteCarlo {                           // off-main, TaskGroup — §A.7
    public static func predictClearance(
        venue: VenueModel, config: SimulationConfig, runs: Int = 30
    ) async -> ClearancePrediction               // p10 / median / p90 seconds
}
```

*(Applied: PATCH-01 — `Simulation` is no longer `@MainActor`; PATCH-02 added `maxValidatedAgents`.)*

## A.4 Data models (sub-types)

**Venue**

| Type | Fields | Notes |
|---|---|---|
| `VenueType` | enum: nightclub, gym, concertHall, office, metroPlatform, school | drives per-venue defaults (§2.9) |
| `Wall` | `cells: [GridCoord]` | fully blocks movement and the flow field |
| `Exit` | `id: UUID`, `cells: [GridCoord]` (doorway span), `clearWidth: Double` (m) | `clearWidth` is the flow-rating input; labelled in the UI |
| `Obstacle` | `id`, `footprint: [GridCoord]`, `kind: PropKind` (stage / bar / turnstile / desk / rack / bench …), `blocksMovement = true`, **`isRelocatable: Bool`** | a **true obstacle** with a real footprint; `isRelocatable = false` for structural elements (columns, stages), which RALLY may never propose moving — see §2.13.3 |
| `DecorTile` | `cells`, `kind` | **sim-inert**; visually distinct |

**Agent**

| Type | Fields / cases | Notes |
|---|---|---|
| `MobilityClass` | adult, child, elderly, wheelchair, staff | sets base speed range and body radius; wheelchair widens the footprint |
| `AgentTraits` | `mobility`, `desiredSpeed` (m/s), `patience` 0–1, `awareness` 0–1, `herding` 0–1 | sampled at spawn from `CrowdMix` + `SafetyStandards` |
| `EmotionalState` | calm → uneasy → panicked | transitions driven by local density, hazard proximity and alarm time (§2.6); panic raises desired speed → faster-is-slower |
| `AgentStatus` | active, evacuated, injured, dead | injured / dead set by hazard contact; removed from the force calculation but retained as soft obstacles |

## A.5 Event-log schema (feeds the AI debrief)

```swift
public struct RunEvent: Sendable, Codable {
    let id: Int; let time: TimeInterval; let kind: RunEventKind
    let location: GridCoord?; let magnitude: Double?
    let agentID: Int?; let detail: String
}
```

| `RunEventKind` | Emitted when | Payload |
|---|---|---|
| `alarmTriggered` | t == alarmDelay | — |
| `ignition` | hazard seeded | location |
| `hazardSpread` | throttled (≤ 1 Hz) | location, magnitude = cells affected |
| `exitBlocked` | a hazard reaches an exit cell | location (exit id in detail) |
| `flowFieldRecomputed` | after a geometry or hazard change | reason in detail |
| `densityThresholdCrossed` | a cell crosses a Fruin band | location, magnitude = p·m⁻² |
| `jamFormed` | at-risk density sustained ≥ N s in a region | location, magnitude = peak density |
| `agentInjured` / `agentKilled` | hazard contact | agentID, location, magnitude = cause code |
| `evacuationProgress` | throttled (≤ 2 Hz) | magnitude = fraction out (feeds the curve) |
| `simEnded` | all out \| time cap \| casualty stop | reason in detail |

**AI grounding rule.** The model never sees the raw per-frame stream. `RunEventLog.summary()` produces a **token-bounded structured digest** — counts by kind, worst jam {location, density, time}, casualties by hazard and location, clearance, per-exit throughput versus rating — and *that* is the `@Generable` context. This bounds tokens and keeps every cited number engine-sourced.

## A.6 Verdict-rules table (structure; final values in §3.1)

Constants live in one place (`VerdictConstants` / `SafetyStandards`), are tunable, and are surfaced in the results UI.

| Constant | Value | Meaning |
|---|---:|---|
| `PASS_SCORE_MIN` | 80 | at or above ⇒ PASS-eligible |
| `FAIL_SCORE_MAX` | 50 | below ⇒ FAIL regardless of casualties |
| `PEAK_DENSITY_WARN` | 5.0 p·m⁻² | Fruin at-risk band |
| `PEAK_DENSITY_FAIL` | 7.0 p·m⁻² | crush / casualty band |
| `AT_RISK_FRACTION_WARN` | 0.15 | fraction of agents above the at-risk band beyond the dwell time |
| `AT_RISK_DWELL` | 3.0 s | dwell that counts as "at risk" |
| `CLEARANCE_TARGET` | per `VenueType` | from the per-venue defaults (§2.9) |
| `JAM_UNRESOLVED_AT_CAP` | true ⇒ FAIL | agents still trapped at the time cap |

Full evaluation order, reason templates and live-escalation behaviour are in §3.3.

## A.7 Threading & concurrency (Swift 6 strict)

| Domain | Runs on | Data crossing the boundary |
|---|---|---|
| UI + render loop | `@MainActor` (`TimelineView(.animation)` → `Canvas`) | reads `SimulationSnapshot` (`Sendable`) |
| Sim step (v1) | the **main actor's own `Simulation` instance**, called inside the tick | mutates that instance in place |
| Monte Carlo batch | **off-main**, `TaskGroup`, one **private** `Simulation` per child task | takes `Sendable` `VenueModel` + `SimulationConfig` + seeds; returns `Sendable` `ClearancePrediction` |
| AI coaching | `async`, app actor | `Sendable` digest in, `@Generable` out |

> **Isolation rule (PATCH-01).** `Simulation` is a plain reference type that is *not* `Sendable` and must be used from exactly one execution context. The app creates and owns one instance **on the main actor**, so the render loop touches it without actor hops. Each Monte Carlo child task creates and owns its **own private instance** inside `withTaskGroup` and returns only `Sendable` values. **No `Simulation` instance is ever shared across contexts** — which is why no actor or lock is needed anywhere in the engine.

**Why step on the main actor in v1.** At 200 agents the per-tick cost on A18 is small: the social force is O(n·k) with k = neighbours within the interaction radius via the spatial hash, and the flow field is **not** recomputed per frame — only on a hazard or geometry change. The 16.6 ms budget is dominated by the `Canvas` draw, not the physics. Stepping on-main removes all cross-actor hops and is far simpler for Swift newcomers.
**Upgrade path (documented, not built unless profiling demands it):** move `step` to a background task producing **double-buffered** snapshots. The boundary type already exists, so this is a localised change, never a rewrite. All engine value types are `Sendable`; the seeded RNG is a value-type PRNG, so Monte Carlo runs are reproducible and parallel-safe.

## A.8 AI integration seam (app-side only)

```text
Metrics + RunEventLog.summary() + Verdict
        │
        ▼
protocol CoachingService { func advise(_:) async -> CoachAdvice }
   ├─ FoundationModelsCoach   → SystemLanguageModel session, @Generable output
   └─ CannedCoach             → deterministic templated lines (Must tier)
        ▲
   DeviceCapabilities.supportsOnDeviceModel  (SystemLanguageModel.availability)
```

- Schemas, the validation gate and canned fallbacks are specified in §3.5.
- **Tone:** humour only when `Verdict.level == .pass`; WARN and FAIL use a supportive coach tone, never jokes about simulated casualties.
- **iOS-27 gated (Stretch, fallback-first):** a multimodal density-heatmap image attached to the digest; agent apply-&-re-run tools. Both sit behind `if #available(iOS 27, *)` plus a capability check; the text-only path is the default.

## A.9 Persistence (app; the engine stays framework-free)

```swift
@Model final class SavedVenue {
    var id: UUID; var name: String
    var venueData: Data          // Codable VenueModel
    var venueType: String; var modifiedAt: Date; var thumbnail: Data?
}

@Model final class RunRecord {
    var id: UUID; var venueID: UUID
    var score: Double; var verdictLevel: String
    var metricsData: Data; var date: Date
}
```

Engine value types are the truth; SwiftData stores their `Codable` encodings. Consequence: `.egress` document export (Stretch) is trivial, because the payload is already `Codable VenueModel`. Score-history sparklines read `RunRecord` per venue.

## A.10 File / folder layout

```text
Egress/                         ← Xcode project root
├─ Packages/
│  └─ EgressEngine/
│     ├─ Package.swift
│     ├─ Sources/EgressEngine/
│     │  ├─ Standards/         SafetyStandards.swift, SimConstants.swift, VerdictConstants.swift,
│     │  │                     DensityBands.swift, GeometryMinimums.swift, HazardRates.swift
│     │  ├─ Model/             VenueModel.swift, GridGeometry.swift, Exit.swift, Obstacle.swift,
│     │  │                     DecorTile.swift, VenueType.swift
│     │  ├─ Agents/            Agent.swift, AgentTraits.swift, MobilityClass.swift,
│     │  │                     EmotionalState.swift, AgentSpawner.swift
│     │  ├─ Simulation/        Simulation.swift, SimulationConfig.swift, SimulationSnapshot.swift,
│     │  │                     SocialForce.swift, Integrator.swift, SpatialHash.swift
│     │  ├─ Pathfinding/       FlowField.swift
│     │  ├─ Hazards/           HazardField.swift, FireAutomaton.swift, SmokeField.swift,
│     │  │                     FloodAutomaton.swift
│     │  ├─ Metrics/           Metrics.swift, DensityGrid.swift, SafetyScore.swift, MonteCarlo.swift
│     │  ├─ Verdict/           VerdictRules.swift, Verdict.swift
│     │  ├─ Events/            RunEventLog.swift, RunEvent.swift
│     │  └─ Support/           Vec2.swift, SeededRNG.swift, Scenario.swift, CrowdMix.swift
│     └─ Tests/EgressEngineTests/   (Swift Testing: force, flow field, hazards, metrics,
│                                    verdict, determinism, faster-is-slower)
└─ App/Egress/
   ├─ App/                     EgressApp.swift, RootView.swift (TabView), DeviceCapabilities.swift
   ├─ Spaces/                  library, scenario cards, quick-config chips
   ├─ Editor/                  venue editor (draw walls, place exits, props, dimension overlay,
   │                           parametric edit form)
   ├─ Simulate/                SimScreen.swift, HUD, timeline scrubber / event log
   ├─ Rendering/               SimCanvasView.swift, SpriteAtlas, Shaders/ (Metal 🔴)
   ├─ Learn/                   quizzes, case studies
   ├─ Intelligence/            CoachingService.swift, CoachAdvice.swift, Validation.swift,
   │                           CannedCoach.swift
   ├─ Audio/                   AudioEngine.swift, SFX assets
   ├─ Haptics/                 HapticEngine.swift
   ├─ Persistence/             SavedVenue.swift, RunRecord.swift, ModelContainer+Egress.swift
   ├─ DesignSystem/            ColorTokens.swift, Motion.swift, Liquid Glass components, RALLY views
   └─ Support/                 shared SwiftUI utilities
```

## A.11 Availability-gating architecture (fallback-first)

`DeviceCapabilities` computes once at launch; feature flags gate optional paths so that cutting any single modern API never breaks the core.

| Capability flag | Source | Gated feature | Default fallback (built first) |
|---|---|---|---|
| `supportsOnDeviceModel` | `SystemLanguageModel.availability` | AI coach diagnosis, fixes, quizzes | `CannedCoach` templated lines |
| `supportsMultimodalFM` | `#available(iOS 27, *)` + availability | heatmap image in the coach prompt | text-only digest |
| `supportsAgentTools` | `#available(iOS 27, *)` | one-tap apply-&-re-run authored by the model | deterministic engine-side edit + re-run |
| `supportsAppIntentsSurface` | `#available(iOS 27, *)` | "rerun my last drill" / Spotlight | in-app only |

> **Rule.** The fallback is the *default code path*; the enhanced path is layered behind the flag. Nothing iOS-27-only ever enters the Must tier.

---

# SIMULATION DEEP SPEC (Reqs 1–4)

**Constants split.** `SafetyStandards` holds physically-grounded, citable values (speeds, densities, geometry minima, exit flow). `SimConstants` (sibling file) holds numerical model tuning coefficients (`A_PED`, `K_BODY`, `τ`, spread rates, score weights). The coach only ever cites `SafetyStandards`; `SimConstants` are engine internals. All stochastic draws pull from one injected value-type `SeededRNG` (SplitMix64), so every run is reproducible and Monte Carlo is parallel-safe. ✅ every algorithm is standard and pure Swift/simd; 🟡 every numeric constant is a tunable starting point.

## 2.1 Simulation loop & fixed-timestep integration (Req 1)

Semi-implicit (symplectic) Euler on a **fixed internal step** `H` with a frame accumulator; the render frame's `dt` never touches the physics directly.

```text
func advance(frameDt):
    accumulator += min(frameDt, DT_MAX)          // DT_MAX = 1/30 s — spiral-of-death guard
    while accumulator >= H:                       // H = 1/120 s → ~2 substeps per 60 fps frame
        substep(H); accumulator -= H
    updateDensityGrid()                           // once per frame, not per substep
    // hazards advance on their own 15 Hz clock, decoupled from H

func substep(h):
    rebuildSpatialHash()                          // O(n)
    for i: a_i = drive_i + Σ ped_i + Σ wall_i;  a_i = clampMag(a_i, A_MAX)
    for i: v_i = clampSpeed(v_i + a_i*h, V_MAX);  x_i += v_i*h
    resolveStatus()                               // evacuated? hazard contact? crush?
    updateEmotion(h)
```

**Why fixed-step with substeps:** contact and friction terms stiffen when agents pile at an exit; sub-stepping keeps them stable without an implicit solver (too heavy for this team). The `DT_MAX` clamp means a rendering hitch slows the sim rather than exploding it. If profiling shows headroom at 200 agents, `H` can relax to 1/60 (softer contacts) — a one-line change.

## 2.2 Movement — social force model, acceleration form (Req 1)

Total acceleration for agent *i* — mass and unit conversions are folded into the coefficients, so these are **tuning coefficients, not literal SI force constants**; calibrate empirically:

`a_i = a_drive + Σⱼ a_ped(i,j) + Σ_w a_wall(i)`, then `|a_i| ≤ A_MAX`

**Driving (goal) term**

```
a_drive = (v0_i · ê_i − v_i) / τ
  v0_i = desiredSpeed_i · emotionSpeedFactor_i   // base sampled speed, scaled by arousal (§2.6)
  ê_i  = herding-blended flow direction at the agent's cell (§2.4, §2.6)
         zero until the agent's reaction delay has elapsed
```

**Pedestrian repulsion** — neighbour *j*, `d = |xᵢ−xⱼ|`, `n = (xᵢ−xⱼ)/d`, `overlap = 2·bodyRadius − d`, tangent `t = (−n_y, n_x)`:

```
social   = A_PED · exp(overlap / B_PED) · n                       // always on; exp decays fast
if overlap > 0 {                                                  // bodies in contact
  body    = K_BODY · overlap · n
  Δv_t    = (vⱼ − vᵢ) · t
  friction= K_FRIC · overlap · Δv_t · t                           // tangential — drives clogging
}
a_ped = social + body + friction                                  // contact terms are 0 when apart
```

**Wall repulsion** — each cell caches its nearest-wall distance `d_w` and outward normal `n_w` (the obstacle distance transform is computed alongside the flow field, §2.4). With `overlap_w = bodyRadius − d_w`:

```
social  = A_WALL · exp(overlap_w / B_WALL) · n_w
if overlap_w > 0 { body = K_BODY·overlap_w·n_w
                   friction opposes tangential velocity along the wall }
```

**Tuning constants (`SimConstants`, 🟡 starting values):**

| Constant | Start | Effect / knob direction |
|---|---:|---|
| `TAU` (τ) | 0.5 s | ↓ = snappier, more aggressive acceleration |
| `A_PED` | 12 | ↑ = larger personal space |
| `B_PED` | 0.20 m | ↑ = begin avoiding from farther out |
| `A_WALL` | 8 | ↑ = keep off walls more |
| `B_WALL` | 0.20 m | — |
| `K_BODY` | 60 | ↑ = firmer bodies (stiffer → watch stability) |
| `K_FRIC` | 40 | governs clogging and faster-is-slower magnitude |
| `V_MAX` | 2.5 m/s | hard cap above panic speed |
| `A_MAX` | 20 | acceleration clamp for stability |
| `R_INT` | 1.2 m | neighbour query cutoff (the exponential is ~0 beyond) |
| `H` | 1/120 s | fixed physics step |
| `DT_MAX` | 1/30 s | frame-dt clamp |

**Faster-is-slower / clogging** is *emergent*, not scripted: panic raises `v0`, agents push harder into a bottleneck, contact and friction rise, and flow stutters.
**Validation target (a G2 gate criterion, not an afterthought):** in a one-room / one-exit fixture, sweeping the panic desired speed from 1.4 to 2.2 m/s must produce **non-monotonic (falling) exit throughput**. If it does not, raise `K_FRIC` and `K_BODY`.

## 2.3 Spatial hashing (Req 1)

Uniform bucket grid, bucket edge = `R_INT` (1.2 m). Rebuilt every substep from agent positions — agents move far less than one bucket per substep, so this is cheap and correct. A query covers the agent's bucket plus the 8 Moore neighbours, which guarantees all neighbours within `R_INT` because the bucket edge is at least the radius. Structure: a flat `[[Int]]` of agent indices in row-major buckets, cleared and re-inserted — O(n). This yields O(n·k) force evaluation with k = the local neighbour count.

## 2.4 Flow-field pathfinding (Req 1)

Two fields, recomputed together only when the geometry or the impassable set changes:

1. **Cost field** — multi-source **Dijkstra** seeded from all valid exit cells (cost 0). Edge costs: orthogonal `cellSize` (0.25 m), diagonal `√2 · cellSize`; **corner-cutting is forbidden** (a diagonal step is legal only if both shared orthogonal cells are passable). Impassable = walls, obstacle footprints, active fire cells; deep-flood cells carry a high cost. Binary min-heap, roughly O(cells · log cells) — sub-millisecond for the preset grids (≤ ~5 k cells).
2. **Direction field** — per cell, `ê = normalize(neighbourWithLowestCost.center − cell.center)`, stored as a `Vec2` per cell. Agents sample `ê` at their current cell.
3. **Obstacle distance field** — a companion Dijkstra from wall and obstacle cells giving `d_w` plus a gradient normal `n_w` per cell, feeding the §2.2 wall force. Same pass.

**Recompute triggers (dirty flag):** a venue edit; a hazard cell becoming impassable or passable; an exit being blocked or opened. Throttled to ≤ 4 Hz during a run (batched with hazard ticks); emits `flowFieldRecomputed` and, where relevant, `exitBlocked`. Agents pick up new directions on the next substep → **visible mid-run rerouting** (Req 3).

```swift
struct FlowField {
    let cols, rows: Int
    var cost: [Float]; var dir: [Vec2]
    var wallDist: [Float]; var wallNormal: [Vec2]
    var passable: [Bool]
}
```

## 2.5 Agent traits & spawning (Req 2)

At spawn each agent draws from the venue's `CrowdMix` (mobility fractions), then samples traits via `SeededRNG`:

| Trait | Source | Range |
|---|---|---|
| `mobility` | `CrowdMix` categorical | adult / child / elderly / wheelchair / staff |
| `desiredSpeed` | `SafetyStandards.desiredSpeed(mobility)` mean ± variance | m/s (see the realism table, §2.11) |
| `bodyRadius` | 0.22 m; wheelchair footprint wider (≈ 0.35 m effective) | m |
| `patience` | Beta-like sample | 0–1 |
| `awareness` | sample; staff = 1.0 | 0–1 |
| `herding` | sample | 0–1 |
| `reactionDelay` (pre-movement) | lognormal-like, inversely tied to awareness | 0 – ~15 s |

**Placement:** rejection-sample positions in walkable cells with no agent overlap and outside hazard seeds; deterministic given the seed. Agents idle (no drive term) until `t ≥ alarmTime + reactionDelay_i`, which spreads out egress start realistically (pre-movement time).

## 2.6 Emotional state machine — calm → uneasy → panicked (Req 2)

A continuous **arousal** value `s ∈ [0,1]` per agent approaches a target:

```
s_target = clamp( w_ρ·f_density(ρ_local) + w_h·f_hazard(distHazard, smokeLocal)
                  + w_t·f_time(t − alarmTime), 0, 1 ) · perceptionFactor(awareness_eff)

s ← s + (s_target − s) · (h / τ_emotion)        // τ_emotion ≈ 1.5 s — smooth, no flicker
```

`f_density` is 0 below 1.8 p/m² and ramps to 1 by about 5 p/m². `f_hazard` rises as the distance to the nearest active hazard cell falls. `f_time` ramps after the alarm. `awareness_eff = awareness · (1 − smokeLocal · SMOKE_AWARE_PENALTY)` — smoke blinds.

**State bands and behaviour coupling:**

| State | s | Speed factor | Patience | Herding weight | Extra behaviours |
|---|---|---|---|---|---|
| **calm** | < 0.33 | 1.0× base | high | low | follows the flow field cleanly |
| **uneasy** | 0.33–0.66 | 0.9–1.0× | medium | medium | brief **hesitation dwell** at decision cells (multiple similar-cost exits) |
| **panicked** | ≥ 0.66 | scales base → `panicSpeed` (1.8–2.2 sampled) | low | high | pushes into the crowd; small-probability **freeze**; follows the herd, possibly to the **wrong exit** |

**Herding blend:** `ê = normalize((1−λ)·ê_flow + λ·ê_neighbours)`, where `λ = herdWeight(state) · herding · (1 − awareness_eff)` and `ê_neighbours` is the normalised mean heading of neighbours within `R_INT`. High density + smoke + panic → `λ` rises → agents follow the pack, sometimes to a farther or wrong exit (the required herding failure mode).
**Freeze:** a rare per-tick chance when panicked and low-awareness sets the drive term to ≈ 0 briefly.
**Staff / guide:** `awareness = 1`, `λ = 0` (knows the exit), and lowers neighbours' `s_target` within `R_calm` by `CALM_STRENGTH` — a visible calming influence.

## 2.7 Hazards (Req 3) — physics the room reacts to

All hazards advance on a **15 Hz** clock, decoupled from `H`. All spread randomness uses `SeededRNG`.

**Fire — cellular automaton.** Flammable cells cycle `unburnt → igniting → burning → burnt`. Each hazard tick, every `burning` cell tries to ignite each flammable neighbour with `p = 1 − exp(−FIRE_SPREAD · Δt)` (orthogonal at full weight, diagonal × 0.7). `igniting → burning` after `IGNITION_DELAY`; `burning → burnt` after `BURN_DURATION`. Burning and igniting cells are **impassable** (marking the flow field dirty) and **harmful**.

**Smoke — diffusion field** in `[0,1]` per cell, deliberately **outrunning the flame**: burning cells add `SMOKE_PRODUCTION` per second, and each tick `smoke(c) += D · (mean(neighbours) − smoke(c)) − DECAY · smoke(c)`, clamped. Smoke **does not block** movement; it cuts `awareness_eff` (§2.6) → disorientation, wandering and stronger herding. Optional (Should) cumulative toxicity: `Σ smoke·Δt` past a threshold causes incapacitation.

**Flood — depth automaton.** A depth field (metres) fills from source cells at `FLOOD_FILL`, equalising into adjacent cells. Effects by depth: above `WADE_DEPTH` (0.3 m) the speed factor drops (wading); above `INCAP_DEPTH` (0.8 m) incapacitation follows. Deep cells are marked **high-cost** rather than impassable, so the flow field routes crowds around rising water → visible rerouting.

**Contact, casualties and classification.** An agent in a `burning` or `igniting` cell is injured immediately and dies after `FIRE_LETHAL_DELAY`; smoke toxicity injures (`.smoke`); sustained depth ≥ `INCAP_DEPTH` injures or kills (`.flood`); density ≥ 7 p/m² sustained for `CRUSH_DWELL` causes probabilistic injury (`.crush`). Casualties are recorded as `{hazard, location, time}` in the event log. Downed agents leave the drive loop but **remain as soft obstacles** — still contributing density and repulsion, because a fallen person worsens a jam, as in reality.

**Hazard constants (`SimConstants`, 🟡 tunable — time-compressed for a 1–4 minute demo; the ordering fire ≺ smoke is physically motivated, but this is an *educational* model, not validated fire simulation):**

| Param | Start | Param | Start |
|---|---:|---|---:|
| `FIRE_SPREAD` | 0.35 /s | `SMOKE_PRODUCTION` | 0.5 /s |
| `IGNITION_DELAY` | 1.0 s | `SMOKE_DIFFUSION D` | 0.25 |
| `BURN_DURATION` | 20 s | `SMOKE_DECAY` | 0.01 /s |
| `FIRE_LETHAL_DELAY` | 2.0 s | `SMOKE_AWARE_PENALTY` | 0.8 |
| `FLOOD_FILL` | 0.4 m/s | `WADE_DEPTH` | 0.3 m |
| `CRUSH_DWELL` | 3.0 s | `INCAP_DEPTH` | 0.8 m |

## 2.8 Metrics & prediction (Req 4)

**Density grid** (drives glow, chips, at-risk, crush and emotion): bin agent centres per cell → separable **box blur** over a kernel of radius `R_dens / cellSize` (`R_dens` = 0.75 m ≈ 1.77 m²) → divide by the kernel area → p/m². O(cells), smooth, and avoids single-cell noise.

**Clearance & curve:** clearance is the sim time when the last active agent evacuates, or the time cap. The evacuation curve is the fraction evacuated sampled over time, feeding Swift Charts and throttled `evacuationProgress` events.

**Peak density:** the maximum over cells of the already-smoothed density; reported with location and time, and drawn as a `jamFormed` timeline marker.

**People at risk:** per agent, accumulate seconds spent where local density ≥ 5 p/m². `atRiskAgents` counts those accruing ≥ `AT_RISK_DWELL` (3 s); `atRiskPersonSeconds` is the sum. The verdict uses `atRiskFraction = atRiskAgents / spawned`.

**Casualties:** `[Hazard: (count, [location])]` plus a total.

**Safety Score (0–100; weights in `SimConstants`, tunable, coupled to the §3.1 verdict thresholds):**

```
densNorm = clamp((peakDensity − 1.8) / (7.0 − 1.8), 0, 1)
riskFrac = atRiskAgents / spawned
timeOver = clamp((clearance − target) / target, 0, 1)   // if not cleared, clearance = timeCap

C = min(60, casualties · 25)   // casualties dominate → any 2 casualties force score ≤ 50
D = densNorm · 25
R = riskFrac · 20
T = timeOver · 15

Score = round(clamp(100 − C − D − R − T, 0, 100))
```

*Worked — Concert Crush:* 3 casualties → C = 60; peak 6.5 → D = 22.6; risk 0.40 → R = 8.0; 210 s against a 180 s target → T = 2.5 ⇒ **7 → FAIL**.
*Worked — Office (good):* 0 casualties; peak 2.2 → D = 1.9; risk 0.02 → R = 0.4; 120 s against 150 s → T = 0 ⇒ **98 → PASS**.

**Monte Carlo prediction (Should tier):** run 30 headless seeded sims varying spawn positions, traits, reaction delays and stochastic spread/freeze, with no rendering, stepped at `H` (or 1/60 for speed). Concurrency is bound to `activeProcessorCount` via `TaskGroup` and is cancellable; **each child task owns its own `Simulation` instance** (§A.7). Clearance times are collected and sorted into `ClearancePrediction { p10, median, p90 }`, shown as a predicted range. Deterministic per seed, therefore reproducible.

**Event emission throttles:** `hazardSpread` ≤ 1 Hz, `evacuationProgress` ≤ 2 Hz, `densityThresholdCrossed` debounced per region — so `RunEventLog.summary()` stays token-bounded for the AI digest.

## 2.9 Per-venue defaults 🟡

Occupant-load factors are code-derived approximations for the *preset* footprint, and clearance targets are reasoned egress goals — **not** certified standards; the educational disclaimer applies. Default agent counts may intentionally exceed nominal comfort to stress-test a layout; users can lower them via the config chip.

**PATCH-02 applied:** every preset default is clamped to `maxValidatedAgents` (default **200**) at load.

| Venue | Footprint | Load factor | Capacity est. | Spec default | **Loaded default (clamped)** | Target clearance | Default mix a/c/e/wc/staff |
|---|---|---:|---:|---:|---:|---:|---|
| Nightclub | 20 × 15 m (300 m²) | 0.65 m²/p | ~460 | 200 | **200** | 120 s | .88/.00/.02/.02/.08 |
| Gym | 25 × 20 (500) | 4.6 | ~108 | 90 | **90** | 120 s | .90/.00/.05/.02/.03 |
| Concert Hall | 30 × 24 (720) | 0.93 | ~774 | 300 | **200** | 180 s | .85/.05/.03/.02/.05 |
| Office | 24 × 18 (432) | 9.3 | ~46 | 80 | **80** | 150 s | .90/.00/.03/.03/.04 |
| Metro Platform | 60 × 6 (360) | 0.50 | ~720 | 250 | **200** | 240 s | .80/.05/.07/.03/.05 |
| School | 30 × 20 (600) | 1.9 | ~315 | 180 | **180** | 180 s | .82/.10/.00/.02/.06 |

Raising the agent chip above `maxValidatedAgents` is permitted but shows a one-line HUD notice: *"Above the validated performance budget — frame rate may drop."* **The demo never runs above `maxValidatedAgents`.**

## 2.10 Scenario presets (Req 3)

`Scenario { name, venue, hazards: [HazardSeed], alarmDelay, configOverrides, difficulty }`

| Scenario | Venue | Hazard (seed) | Alarm | Overrides (clamped per PATCH-02) | Difficulty |
|---|---|---|---|---|---|
| Kitchen Fire | Nightclub | fire at a kitchen-corner cell | 5 s | 200 agents | ●●○ |
| Burst Pipe | Metro Platform | flood at a wall source | 3 s | 250 → **200** agents | ●●○ |
| Blocked Main Exit | Concert Hall | main exit disabled at t₀ (no hazard) | 0 s | 300 → **200** agents | ●●● |
| Concert Crush | Concert Hall | fire at stage-left + narrow exits | 4 s | 350 → **200** agents, panic bias ↑ | ●●● |
| School Drill | School | none (orderly drill) | 0 s | 180 agents, calm | ●○○ |

## 2.11 Constants files (consolidation)

- **`SafetyStandards.swift`** (citable — the coach quotes these verbatim with units): `cellSize 0.25 m`; `bodyRadius 0.22 m`; desired speeds adult **1.35**, child **0.9**, elderly **0.8**, wheelchair **0.7**, staff **1.4** m/s; `panicSpeed 1.8…2.2` m/s; `exitSpecificFlow 1.2` persons/s/m; density bands **< 1.8** comfortable, **2–4** congested, **≥ 5** at-risk, **≥ 7** crush; geometry minima interior door **≥ 0.9 m**, final exit **≥ 1.2 m**, assembly corridor **≥ 1.2 m** (recommend **2.4 m** at high occupancy).
- **`SimConstants.swift`** (internal knobs): the §2.2 force coefficients, `H`, `DT_MAX`, `R_INT`, `R_dens`, `τ_emotion`, arousal weights, `AT_RISK_DWELL`, the §2.7 hazard rates, the §2.8 score weights, `R_calm`, `CALM_STRENGTH`, `SMOKE_AWARE_PENALTY`.

## 2.12 Cross-cutting — WWDC26 / AI

The engine is pure Swift and simd, **iOS-26-safe with no iOS-27 dependency** — the entire Must-tier simulation runs regardless of Apple Intelligence availability. Two engine outputs are the AI's *only* grounding: the smoothed **density grid** (optionally an iOS-27 multimodal heatmap, gated) and `RunEventLog.summary()` (the text digest). Monte Carlo uses Swift Concurrency `TaskGroup`, also iOS-26-safe. Nothing in this section enters the demo as an iOS-27-only path.

## 2.13 Obstacle interaction · NPC behavioural intelligence · expressive emotion

### 2.13.1 Scope check — what already existed, what this section adds

| Capability | Status before this section |
|---|---|
| Obstacles as real blocking footprints (`Obstacle`, `blocksMovement = true`) | ✅ already specified (§A.4) |
| Themed props per venue — stage, bar, turnstiles, desks, racks, benches | ✅ already specified |
| Decorative floor tiles that are sim-inert and visually distinct | ✅ already specified |
| Wall and obstacle repulsion force via a distance field | ✅ already specified (§2.2, §2.4) |
| Fire, smoke and flood hazards with rerouting | ✅ already specified (§2.7) |
| Three-state emotion machine (calm → uneasy → panicked) driving physics | ✅ already specified (§2.6) |
| Emote badges "?" and "!" | ✅ already specified |
| **Every venue furnished by default — no empty boxes** | 🆕 rule added below |
| **Anticipatory dodging — visible swerve before contact** | 🆕 |
| **Collision, stumble and obstacle memory** | 🆕 |
| **Obstacle-derived aisle clear-width analysis** | 🆕 (nearly free — reuses `FlowField.wallDist`) |
| **Expressive reaction emotes — astonished, distressed, frustrated, relieved** | 🆕 |
| **Fire and water as editor-placeable hazard props** | 🆕 (nearly free — reuses `HazardSeed`) |
| **Stall-triggered exit re-decision** | 🆕 (Stretch) |

### 2.13.2 What "intelligent NPC" means here — and what it does not

**It is not an LLM per agent.** Stating the arithmetic plainly, because this is the single most expensive wrong turn available: one on-device model call costs order *seconds*; the frame budget is 16.6 ms; there are 200 agents. That is roughly five orders of magnitude over budget, and it would additionally destroy the two properties the demo depends on — **determinism** (fixed seed, reproducible takes, §E.4) and **offline battery headroom**. It is off the table permanently, not deferred.

NPC intelligence in Egress is **deterministic behavioural intelligence** — four mechanisms that make agents *read* as thinking beings:

| Mechanism | What it produces on screen | Where |
|---|---|---|
| **Anticipatory avoidance** | agents swerve *early and decisively* around a table rather than mushing into it | §2.13.4 |
| **Obstacle memory** | an agent that clips a bench gives it a wider berth next time | §2.13.5 |
| **Stall-triggered re-decision** | an agent stuck in a non-moving queue reconsiders its exit | §2.13.8 |
| **Social influence** (already present) | herding, staff calming, wrong-exit following | §2.6 |

The on-device model's role is unchanged and remains the Pocket Brain proof: it **explains** the crowd's behaviour afterwards (RALLY), grounded in engine numbers. Agents behave; the model narrates. That division is what keeps both halves honest.

### 2.13.3 Furnished by default — no empty rooms

**Rule:** every System Preset ships with an authored prop layout. An empty rectangle is never a shippable venue, because an empty rectangle is not a room and its evacuation result is not interesting.

`Obstacle` gains one field:

```swift
public struct Obstacle: Sendable, Codable, Identifiable {
    public let id: UUID
    public var footprint: [GridCoord]
    public var kind: PropKind
    public let blocksMovement = true
    public var isRelocatable: Bool     // 🆕 false for structural elements
}
```

`isRelocatable` matters because it constrains the coach: RALLY may propose moving a standing table, but **never** a load-bearing column. Structural props get "route around" advice instead of "relocate" advice. Validation check V5 (§3.5.3) is extended to reject any fix that proposes relocating a non-relocatable obstacle.

| Venue | Authored prop set | Structural (non-relocatable) |
|---|---|---|
| Nightclub | bar run, stage block, standing tables, speaker stacks | stage block, bar run |
| Gym | rack rows, benches, treadmill bank | — |
| Concert Hall | stage, seating blocks, crowd barriers, merch stand | stage, seating blocks |
| Office | desk pods, meeting pod, printer bank, lockers | — |
| Metro Platform | benches, kiosk, turnstile bank, **columns** | columns, turnstile bank |
| School | desk rows, lockers, lab benches | lab benches |

> **Authoring constraint (load-bearing — see the G2 note in §2.13.7):** preset prop layouts must be authored so that every primary egress route clears the `SafetyStandards` minimum. The Office preset in particular must still produce **Score 98 / PASS**, because that is a G2 gate criterion.

### 2.13.4 Anticipatory dodging — the visible intelligence

The existing wall force is a *reactive* term: it grows as an agent nears a surface, which reads as mush. Dodging adds a *predictive* term, which reads as intent.

**Algorithm** (evaluated every `RAY_STRIDE` substeps, i.e. ~30 Hz, not every substep):

1. Lookahead distance scales with speed: `L = clamp(L_MIN + |v| · T_LOOK, L_MIN, L_MAX)`.
2. Walk grid cells along the velocity ray (DDA) up to `L`. Stop at the first impassable cell — walls, obstacle footprints, **and active hazard cells**.
3. If one is found at distance `d`, pick a side. Compare `FlowField.cost` at the two lateral offsets and choose the cheaper; ties break toward the agent's current lateral velocity.
4. Apply `a_dodge = A_DODGE_eff · (1 − d/L) · t̂`, where `t̂` is the chosen lateral unit vector — so urgency grows as the obstacle nears.
5. **Commit** the chosen side for `DODGE_COMMIT` seconds. This is what produces decisiveness; without commitment agents oscillate between sides and look broken.

**Awareness gating — the elegant coupling:**

```
A_DODGE_eff = A_DODGE · awareness_eff
```

`awareness_eff` is the *same* quantity that smoke degrades (§2.6). So a calm, clear-sighted agent dodges early; a panicked or smoke-blinded agent dodges late or not at all — **and therefore crashes**. Collisions are not scripted; they are what happens when perception fails. This also means clutter becomes measurably more dangerous as smoke spreads, which is both true and demoable.

**Cost:** at most ~10 cell tests per agent per evaluation at 30 Hz. Negligible against the 16.6 ms budget, and it touches only the already-resident passability grid.

### 2.13.5 Collision, stumble and obstacle memory

**Detection** (after integration, per substep): a bump registers if the agent's cell is impassable, or the wall-overlap term exceeded `BUMP_OVERLAP` this substep.

**Response, in order:**

1. **Positional correction** — push out along `n_w` to the surface. This prevents tunnelling, which is the real failure mode at panic speeds.
2. **Velocity** — zero the normal component; retain the tangential component × `BUMP_TANGENT_RETAIN`, so agents scrape along the obstacle rather than sticking to it.
3. **Stumble** — `stumbleTimer` sampled from `STUMBLE_RANGE` via `SeededRNG`; during it the speed factor drops to `STUMBLE_SPEED_FACTOR` and the drive weight is reduced. This is the visible hitch that sells the collision.
4. **Arousal spike** — `s += BUMP_AROUSAL`, feeding the existing emotion machine.
5. **Emote** — `frustrated` on a repeat bump, `astonished` on a first bump (§2.13.6).
6. **Obstacle memory** — raise a per-agent `avoidBias` for that obstacle, decaying over `MEMORY_DECAY`, which widens the agent's dodge margin on the next approach.
7. **Cooldown** — `BUMP_COOLDOWN` per agent, so an agent pinned against a table by crowd pressure registers one bump, not sixty.

**Sound:** `sfx_bump_soft` on the Agents bus, global maximum 2/s. **No haptic.** Haptics are reserved for events that concern the *analyst* — thresholds, casualties, verdicts — not individual agent contacts. At 200 agents, per-bump haptics would be exactly the fatigue failure §5.5 exists to prevent.

**Trip-and-fall — deliberately off by default.** Falls under crowd pressure are a real cascade mechanism in crush incidents, but modelling them here would attribute *casualties* to furniture on the basis of an unvalidated mechanism. `TRIP_FALL_ENABLED` therefore defaults to **false**, is exposed as a clearly-labelled experimental toggle in Settings, and when enabled is **excluded from the Safety Score and from the verdict**. It may be shown; it may not silently change a safety judgement.

### 2.13.6 Expressive emotion — a display layer, deliberately separate

**Two layers, and the separation is architectural, not cosmetic:**

| Layer | Drives physics? | Status |
|---|:--:|---|
| **Arousal spine** — calm / uneasy / panicked (§2.6) | **yes** | unchanged and untouched; already validated by the faster-is-slower test |
| **Reaction emotes** (new) | **no** | transient, display-only, cuttable without touching the engine |

Keeping expression out of the physics means richer characters cannot destabilise a simulation whose behaviour is a gate criterion — and means the whole layer can be cut on a bad day at zero engine risk.

| Emote | Glyph (shape, never colour-coded) | Trigger | Duration |
|---|---|---|---|
| `astonished` | wide-eye "!" | first hazard sighting within `SIGHT_HAZARD`, gated by `awareness_eff`; or first bump | 1.2 s |
| `confused` | "?" | at a decision cell with two or more similar-cost routes; or on exit re-decision | 1.0 s |
| `frustrated` | steam puff | two or more bumps within 4 s, or a queue stalled ≥ 6 s | 1.0 s |
| `distressed` | single teardrop | a casualty nearby, sustained ≥ 5 p/m² for ≥ 8 s, or trapped at the time cap | 1.5 s |
| `relieved` | exhale | crossing an exit threshold | 0.8 s |
| `resolute` | steady chevron | staff only, on calming a neighbour | 1.0 s |

**Budget and rendering:** at most `EMOTE_CONCURRENT` on screen at once, priority `distressed > astonished > frustrated > confused > relieved`; per-agent cooldown `EMOTE_COOLDOWN`; 2-frame 8 × 8 badge above the sprite using `motion.emote`; **hidden entirely below 8 pt per cell**, because at dot scale a field of badges is soup, not information.

**Tone rules (binding — these extend §D.1, and they are not stylistic preferences):**

1. **No gore, no screaming, no wailing.** `distressed` is a small teardrop badge. Its only audio is the existing restrained chirp vocabulary; no new distress sound is authored.
2. **Expressive emotes are suppressed entirely on real-incident presets.** The Itaewon and Astroworld recreations show dots, density and geometry — never crying cartoons. This matches the RALLY-silent rule in §D.1 and is non-negotiable.
3. Reduce Motion: emotes fade without overshoot; `distressed` does not pulse.
4. Accessibility: emote state joins the canvas VoiceOver value **in aggregate only** — "12 occupants showing distress" — never per agent, and never as a per-agent element.
5. Each emote is a distinct **shape**. No emotional state is signalled by colour, consistent with §4.8.

### 2.13.7 Obstacle-derived aisle clear-width analysis — where this earns its place

This is the mechanism that turns furniture from decoration into **analysis**, and it costs almost nothing because the engine already computes the hard part.

1. **Aisle width map — free.** `FlowField.wallDist` (§2.4) already holds the distance from every passable cell to the nearest impassable cell. Clear width at a cell ≈ `2 × wallDist`. No new pass, no new data structure.
2. **Constrictions.** Find local minima of aisle width along *traversed* routes, weighted by cumulative agent path counts, so an unused corner never generates a false finding.
3. **Compare** against `SafetyStandards.geometryMinimums` — interior door ≥ 0.9 m, final exit ≥ 1.2 m, assembly corridor ≥ 1.2 m (recommend 2.4 m at high occupancy).
4. **Report** a new metric: `narrowestTraversedAisle` (metres) with its location and the obstacle pair responsible.

**Verdict integration — additive, and deliberately score-neutral.** A new WARN sub-reason **4d** joins §3.3:

> "The aisle between the bar and the standing tables is 0.7 m — below the 1.2 m assembly-corridor minimum."

**No new Safety Score term is added.** Adding one would change the §2.8 worked examples (Concert Crush = 7, Office = 98), which are G2 gate criteria — so clutter surfaces as a verdict reason and a coach fix, not as a score penalty. If playtesting later argues for a score term, it must be introduced *with* new worked examples and a G2 criteria update, never silently.

**RALLY integration — zero schema change.** `FixTargetKind` already includes `.obstacle` (§3.5.2), so this slots straight into the existing fix vocabulary. `MetricKey` gains one case, `aisleClearWidth`. Only `isRelocatable` obstacles may be proposed for relocation; structural ones yield reroute advice.

> **G2 test note (load-bearing):** aisle analysis runs against furnished presets, so the six preset prop layouts must be authored to clear the minima on primary routes. A preset regression test asserts the §2.8 worked examples are unchanged — **Office must still be 98 / PASS**. Author the props first, then re-run the worked examples.

### 2.13.8 Fire and water as placeable hazard props

The editor palette gains a **Hazards** group, visually separated from Props and Decor to prevent accidental placement:

| Palette item | Places | Config chip | Symbol |
|---|---|---|---|
| Ignition source | `HazardSeed(.fire, cell)` | ignition delay (s) | `flame.fill` ✅ |
| Water source | `HazardSeed(.flood, cell)` | fill rate (m/s) | `water.waves` 🟡 |

**Zero new engine types:** editor placement writes into the venue's existing `Scenario.hazards: [HazardSeed]` (§2.10). Seeds are drawn with a warning-hatched footprint and are **inert until the alarm or their configured delay**, so the editor stays safe to browse and arrange.

**Reaction — how agents treat them:**

- Fire cells are impassable, so **the new dodge raycast already avoids flame fronts**: agents visibly swerve away from fire rather than discovering it on contact.
- Smoke degrades `awareness_eff`, which degrades dodging — so crowds get clumsier around furniture exactly as visibility drops.
- Flood cells are high-cost, so routes bend around rising water; above `WADE_DEPTH` agents wade and may show `distressed`.
- **Hazard flinch (new):** an agent within `FLINCH_RADIUS` of a *newly ignited* cell receives an arousal spike, an `astonished` emote, and a brief away-vector impulse. This is the visible startle response that makes danger feel dangerous.

### 2.13.9 Stall-triggered exit re-decision (Stretch)

Today the flow field routes everyone to the globally cheapest exit. Per-agent re-decision requires **one flow field per exit** (typically 2–4 fields over ≤ 5 k cells — memory is trivial, compute is a multiple of an already sub-millisecond pass).

An agent whose progress-toward-exit falls below `STALL_THRESHOLD` for `STALL_TIME` re-evaluates: high-awareness agents switch to a cheaper alternative exit and emit `confused`; low-awareness agents herd instead (existing behaviour). This is the most expensive item in this section and the least necessary for the demo, so it stays **Stretch** and is the first of this batch to be cut.

### 2.13.10 New constants (`SimConstants`, 🟡 all tunable starting values)

| Constant | Start | Governs |
|---|---:|---|
| `T_LOOK` | 0.8 s | lookahead time for the dodge raycast |
| `L_MIN` / `L_MAX` | 0.5 / 2.5 m | lookahead distance clamp |
| `A_DODGE` | 10 | dodge steering strength (before awareness gating) |
| `DODGE_COMMIT` | 0.6 s | side-commitment window — prevents oscillation |
| `RAY_STRIDE` | 4 substeps | dodge evaluation cadence (~30 Hz) |
| `BUMP_OVERLAP` | 0.06 m | penetration that counts as a collision |
| `BUMP_TANGENT_RETAIN` | 0.5 | tangential velocity kept on bump (scrape) |
| `BUMP_AROUSAL` | 0.15 | arousal spike per bump |
| `BUMP_COOLDOWN` | 1.0 s | per-agent anti-spam |
| `STUMBLE_RANGE` | 0.4–0.8 s | stumble duration sample |
| `STUMBLE_SPEED_FACTOR` | 0.35 | speed multiplier while stumbling |
| `MEMORY_DECAY` | 6.0 s | obstacle-memory decay |
| `SIGHT_HAZARD` | 4.0 m | hazard sighting radius for `astonished` |
| `FLINCH_RADIUS` | 2.0 m | hazard-flinch radius |
| `EMOTE_CONCURRENT` | 12 | on-screen emote budget |
| `EMOTE_COOLDOWN` | 2.5 s | per-agent emote cooldown |
| `STALL_THRESHOLD` / `STALL_TIME` | 0.15 m/s · 6 s | exit re-decision trigger (Stretch) |
| `TRIP_FALL_ENABLED` | **false** | experimental; excluded from score and verdict |

### 2.13.11 Tests (added to the engine suite)

| Test | Asserts |
|---|---|
| Dodge — clear sight | at `awareness = 1.0`, an agent with an obstacle dead ahead deviates **before contact**; zero bumps registered |
| Dodge — blinded | at `awareness = 0.1`, the identical fixture **does** register a bump — proving the awareness coupling is live, not decorative |
| No tunnelling | across 10 k substeps at panic speed, no agent ever ends a substep inside an impassable cell |
| Bump cooldown | an agent pinned against an obstacle registers ≤ 1 bump per second |
| Dodge stability | no side-oscillation: an agent changes committed side at most once per `DODGE_COMMIT` window |
| Aisle measurement | a fixture with an authored 0.7 m gap reports `narrowestTraversedAisle` = 0.70 ± 0.02 m |
| **Preset regression** | all six furnished presets reproduce their §2.8 worked examples — **Office = 98 / PASS**, Concert Crush = 7 / FAIL |
| Determinism preserved | identical seed → identical bump count, stumble timings and clearance |

### 2.13.12 Tiering and the honest cost

Nothing here is free, and this batch has to be paid for out of an already-tight plan.

| Item | Tier | Est. cost | Notes |
|---|:--:|---|---|
| Furnished presets + `isRelocatable` | **Must** | ~0.5 day (B) | authoring, not engineering; folds into D9 preset work |
| Editor hazard palette | **Should** | ~0.3 day (B) | reuses `HazardSeed`; folds into D6 editor work |
| Anticipatory dodge + commitment | **Should ★** | ~0.6 day (A) | highest wow-per-hour item in this section |
| Bump, stumble, obstacle memory | **Should ★** | ~0.5 day (A) | the visible consequence of failed perception |
| Hazard flinch | **Should** | ~0.2 day (A) | folds into D7 hazard work |
| Aisle clear-width analysis + reason 4d | **Should ★** | ~0.4 day (A) | reuses `wallDist`; the analysis payoff |
| Expressive emote layer | **Should** | ~0.5 day (B) | display-only; cuttable at zero engine risk |
| Stall-triggered exit re-decision | **Stretch** | ~1.0 day (A) | per-exit fields; first of this batch to be cut |

**Total ≈ 2.2 dev-days (A) + 1.3 dev-days (B).**

> **What funds it: Monte Carlo.** Monte Carlo's demo value is a predicted-range chip. This batch's demo value is a crowd that visibly thinks, dodges, collides and reacts — the difference between "dots drifting" (risk R-09) and a room full of people. That is not a close call. **Monte Carlo drops below this batch in the cut order and is the first casualty if D10–D11 run long.** PDF export and the Learn quiz follow it.

**The kill-switch, stated plainly:** if dodging destabilises the crowd (risk R-17), set `A_DODGE = 0`. The agents fall back to pure flow-field routing plus the existing wall force — which is the behaviour already validated at G1 and G2. One constant, zero code, no regression.

---

# VERDICT ENGINE + MASCOT + RETRO SFX (Reqs 5–6)

## 3.1 Verdict constants — final values

`VerdictConstants.swift` — one file, tunable, surfaced in the UI.

| Constant | Value | Source / rationale |
|---|---:|---|
| `PASS_SCORE_MIN` | 80 | at or above ⇒ PASS-eligible |
| `FAIL_SCORE_MAX` | 50 | below ⇒ FAIL (catches casualty-free catastrophes) |
| `PEAK_DENSITY_WARN` | 5.0 p/m² | `SafetyStandards` Fruin at-risk band ✅ |
| `PEAK_DENSITY_FAIL` | 7.0 p/m² | crush band ✅ (also drives crush casualties, §2.7) |
| `AT_RISK_FRACTION_WARN` | 0.15 | 🟡 15% of occupants held at risk indicates a layout problem |
| `AT_RISK_DWELL` | 3.0 s | 🟡 dwell that counts as "at risk" |
| `CLEARANCE_TARGET` | club 120 · gym 120 · hall 180 · office 150 · metro 240 · school 180 s | §2.9 🟡 |
| `SIM_TIME_CAP` | `clamp(3 × CLEARANCE_TARGET, 300, 600)` s → 360 / 360 / 540 / 450 / 600 / 540 | a run must terminate for a demo |
| `TRAPPED_FAIL_COUNT` | 1 | **any** occupant unevacuated at the cap ⇒ FAIL — in a safety product, one trapped person is a failure |
| `ESCALATION_COOLDOWN` | 6.0 s | anti-spam for the live banner, haptic and sound |
| `ESCALATION_REARM` | 10.0 s below the band | before the same band can fire again |

## 3.2 ⚠️ Score-versus-threshold coherence (resolved design decision)

The two systems **can disagree in a narrow band**, and that must be handled deliberately rather than discovered during the demo.

*Worked:* peak density of exactly 5.0 p/m², zero casualties, otherwise clean → `D = ((5.0 − 1.8)/5.2) × 25 = 15.4` → **Score 85** (PASS band) — yet rule 4 fires **WARNING**. The disagreement window is peak density **5.0 – 6.0 p/m²** on an otherwise-clean run. At 6.0, `D = 20.2` → score 80, and above that the score falls into the WARN band on its own.

**Resolution — three rules:**

1. **The rules table is the safety authority; the Safety Score is a communication device.** The verdict level is *never* derived from the score alone. This is documented in-app under "How scoring works."
2. **UI rule:** whenever `verdict.level` disagrees with the score's band, the results card and RALLY both **lead with the violated threshold**, not the number — "Peak density 5.4 p/m² at Exit A (caution band ≥ 5.0)" — with the score shown as secondary. This prevents the "Score 85 but WARNING?" confusion.
3. Not "fixed" by re-weighting: forcing agreement would require a `D` weight of at least 32.5, distorting the casualty and time balance. A narrow, explainable disagreement beats a contorted formula. 🟡 Tunable if playtesting says otherwise.

**Why rules 1 and 2 both exist:** rule 1 (casualties > 0) catches every casualty run — one casualty already costs 25 points and two hit the 50-point cap. Rule 2 is reachable only casualty-free: the maximum non-casualty penalty is `25 + 20 + 15 = 60` → score 40 (for example, mass entrapment at 7 p/m² over the target time). Both are live.

## 3.3 Verdict evaluation & reason templates

```swift
Verdict { level, score, reasons: [VerdictReason], firstEscalationTime, timeline: [EscalationEvent] }
VerdictReason { metricKey, thresholdValue, actualValue, unit, locationLabel, template }
```

Every reason renders **metric + threshold + value + units**. First match wins:

| # | Condition | Level | Rendered reason |
|---|---|:--:|---|
| 1 | `casualties > 0` | **FAIL** | "3 casualties at Exit A (fire)" |
| 2 | `score < 50` | **FAIL** | "Safety Score 41 below floor of 50" |
| 3 | `activeAgents ≥ 1` at `SIM_TIME_CAP` | **FAIL** | "7 occupants unable to reach an exit within 360 s" |
| 4a | `peakDensity ≥ 5.0` | **WARN** | "Peak density 6.8 p/m² at the north corridor (caution ≥ 5.0 p/m²)" |
| 4b | `atRiskFraction ≥ 0.15` | **WARN** | "31% of occupants held above 5.0 p/m² for over 3 s" |
| 4c | `clearance > CLEARANCE_TARGET` | **WARN** | "Clearance 168 s exceeds the 120 s target for a nightclub" |
| 4d | `narrowestTraversedAisle < geometryMinimum` (§2.13.7) | **WARN** | "The aisle between the bar and the standing tables is 0.7 m — below the 1.2 m assembly-corridor minimum" |
| 5 | `50 ≤ score < 80` | **WARN** | "Safety Score 72 in the caution band" |
| 6 | else | **PASS** | "Cleared in 94 s · peak 2.2 p/m² · zero casualties" |

All applicable WARN sub-reasons are collected so the card can list them; the **level** is decided by the first match.

**Live in-sim escalation** (`EscalationEvent`) — the same predicates evaluated per frame against live metrics:

| Trigger | Banner | Haptic | Sound |
|---|---|---|---|
| density ≥ 4.0 (approaching) | "CONGESTION BUILDING" amber | `.warning` light | `sfx_sting_soft` |
| density ≥ 5.0 (at risk) | "BOTTLENECK DETECTED" amber | `.warning` | `sfx_sting_warn` |
| density ≥ 7.0 (crush) | "CRUSH RISK" red | `.error` + custom curve | `sfx_sting_crit` |
| exit blocked by a hazard | "EXIT B BLOCKED" red | `.error` | `sfx_exit_blocked` |
| first casualty | "CASUALTY" red | heavy impact | `sfx_thud` |

Each band fires **once per run** (first crossing), with `ESCALATION_COOLDOWN` (6 s) between any two escalations and re-arming after 10 s below the band. All escalations are appended to `RunEventLog` and drawn as timeline-scrubber markers.

## 3.4 Mascot character sheet — **RALLY**

**Name:** RALLY · **Unit designation:** RP-25 (*Rally Point, 0.25 m grid*) · **Role:** safety coach, not an authority.
Deliberately *not* named "Marshal" or "Inspector" — the app gives educational analysis, not certified engineering advice, and the mascot must never imply certification.

**Silhouette (all original, no copyrighted characters):** a 16 × 16 px source rendered at 3–4× (48–64 pt). A chunky rounded-square head with a **single wide visor** (readable at dot scale, where two eyes would mush), a stubby antenna with a bulb, a boxy torso with a 3-pip chest grid, short arms, and a **hover base instead of legs** — which halves the animation work and makes the idle bob free. Palette of at most 6 colours drawn from the design tokens.

| State | Frames | fps | Trigger | Pose / tells |
|---|:--:|:--:|---|---|
| `idle` | 2 | 4 | default on the card | gentle hover bob; antenna bulb pulses slowly |
| `talk` | 4 | 8 | while text streams | visor waveform animates; antenna blinks per syllable; synced to `sfx_mascot_blip` |
| `concerned` | 3 | 4 | WARN | leans forward, antenna droops, visor narrows, one arm raised pointing |
| `alert` | 2 | 6 | FAIL / crush escalation | rigid posture, antenna bulb strobes (**Reduce Motion → static**) |
| `celebrate` | 4 | 10 | PASS | arms up, hover bounce, 6 pixel-confetti sprites |

**Colour semantics:** the antenna bulb and visor tint use green / amber / red **only** to express verdict state, never decoratively. **Never colour-alone:** each state also differs by pose, antenna shape, an SF Symbol badge on the card and the headline text, so the state is legible to colour-blind users and in greyscale.

**Card layout:** a Liquid Glass panel floating over the sim canvas.

```text
┌─────────────────────────────────────────────┐
│ ▣ RALLY   BOTTLENECK DETECTED          [×]  │  ← 56pt sprite left · bold headline · dismiss
│  (48pt)   Flow through Exit A is 0.6         │  ← ONE metric sentence, real numbers + units
│           agents/s per metre (standard 1.2)  │
│  ┌──────────────────────┐ ┌───────────────┐ │
│  │ Widen Corridor 2.4 m │ │ Move Obstacles│ │  ← primary green fix · secondary amber alt
│  └──────────────────────┘ └───────────────┘ │
└─────────────────────────────────────────────┘
```

**Behaviour:** non-blocking (the sim keeps running and the card never covers the bottleneck — it repositions to the opposite half of the canvas), **tap to expand** (full diagnosis, "show the numbers behind this", regenerate), **swipe to dismiss**, and auto-dismiss after 12 s for in-sim events but **never** for the final verdict. At most one card is on screen; a new event replaces the content with a `talk` transition rather than stacking.

## 3.5 AI layer — schemas, validation, canned fallbacks

### 3.5.1 Structural tone guarantee (humour only in PASS)

Three **separate** schemas and prompts, selected by verdict level. The `joke` field **exists only on the PASS schema**, so a joke about a run with simulated casualties is structurally impossible — not merely instructed against. This is the strongest form of the tone guardrail.

### 3.5.2 Anti-hallucination: the model never emits numerals

The model returns **metric *keys*, not values**; the app substitutes the engine's real number at render time. The model therefore *cannot* invent a metric.

```swift
// 🔴 Must-verify in Xcode 27: exact @Generable / @Guide constraint spellings.
public enum MetricKey: String, Codable, CaseIterable, Sendable {
    case peakDensity, clearanceTime, atRiskFraction, casualties
    case exitFlowRate, exitClearWidth, corridorWidth, occupantCount
    case aisleClearWidth                       // 🆕 §2.13.7 — obstacle-derived constriction
}

@Generable struct WarnFailAdvice {                    // WARN + FAIL — no joke field, by design
    @Guide(description: "One or two sentences naming WHERE and WHY the jam formed. Never write digits or numeric values.")
    let diagnosis: String
    @Guide(description: "Two or three concrete fixes.", .count(2...3))
    let fixes: [GeometryFix]
    @Guide(description: "One supportive line. No humour. Never write digits.")
    let encouragement: String
}

@Generable struct PassAdvice {                        // PASS only
    let summary: String
    @Guide(description: "One light, safety-themed joke. Never about casualties or injury.")
    let joke: String
}

@Generable struct GeometryFix {
    @Guide(description: "Which element to change.") let target: FixTarget
    @Guide(description: "Imperative instruction WITHOUT numbers, e.g. 'Widen the main corridor'.")
    let instruction: String
    @Guide(description: "The metric that justifies this fix.") let citedMetric: MetricKey
    @Guide(description: "Proposed new clear width in metres.", .range(0.9...6.0))
    let proposedMetres: Double?
}

@Generable struct FixTarget {
    @Guide(description: "Kind of element.") let kind: FixTargetKind   // exit | corridor | obstacle | wall
    @Guide(description: "Identifier copied verbatim from the supplied venue element list.")
    let elementID: String
}
```

**Prompt contract:** the system prompt supplies the `RunEventLog.summary()` digest, an explicit **list of valid element IDs**, and the `SafetyStandards` minima, and states: *use only the supplied element IDs; never write digits in prose; cite a metric by key.*

### 3.5.3 Validation gate (`Validation.swift`) — every check must pass or we fall back

| # | Check | Failure action |
|---|---|---|
| V1 | Session returned non-empty, well-formed, non-refusal output | → Canned |
| V2 | Every `elementID` exists in `VenueModel` (exit / obstacle / wall ID set) | → Canned |
| V3 | `citedMetric` is materially relevant (e.g. `exitFlowRate` only if that exit's measured flow is below its rating) | drop that fix; if fewer than 1 survives → Canned |
| V4 | **Numeral scan:** regex `\d` over `diagnosis` / `encouragement` / `instruction`; any digit not matching a whitelisted engine value within tolerance (0.05 m / 0.1 p·m⁻² / 1 s) | → Canned |
| V5 | **Geometry feasibility:** `proposedMetres` ≥ the `SafetyStandards` minimum for that element type (door 0.9 / exit 1.2 / corridor 1.2) **and** it physically fits the venue bounds without colliding with a fixed wall **and**, for a relocation fix, the target obstacle has `isRelocatable == true` (§2.13.3) | drop that fix |
| V6 | Fix count after drops is 2–3 | pad from the canned list, or → Canned |
| V7 | Latency budget of 4.0 s (streaming shown meanwhile) | timeout → Canned |
| V8 | PASS only: `joke` is present and contains no casualty or injury vocabulary (small blocklist) | drop the joke, keep the summary |

**Rendering:** the UI composes final strings by interpolating the engine's real value for `citedMetric` into the model's number-free prose — so what the user reads is *model phrasing plus engine arithmetic*. Every card offers **regenerate**, **dismiss**, and **"show the numbers behind this"** (which opens the metric with its threshold and source).

### 3.5.4 Canned fallback lines (Must tier — used on any validation failure or unsupported device)

Deterministic templates with engine-filled slots; the app is fully coherent with **zero** AI.

| Verdict | Headline | Body template | Fix chips |
|---|---|---|---|
| PASS | "EVACUATION SUCCESSFUL" | "Everyone cleared in {clearance} s, peak density {peak} p/m². Below the {target} s target." | "Save layout" · "Try a harder scenario" |
| WARN (density) | "BOTTLENECK DETECTED" | "Peak density reached {peak} p/m² at {location} — above the {5.0} p/m² caution band." | "Widen {element} to {min+0.6} m" · "Add an exit" |
| WARN (clearance) | "TOO SLOW" | "Clearance {clearance} s exceeded the {target} s target for this venue type." | "Widen main exit" · "Add an exit" |
| WARN (at risk) | "CROWD UNDER PRESSURE" | "{pct}% of occupants spent over {dwell} s above {5.0} p/m²." | "Widen {element}" · "Relocate obstacles" |
| FAIL (casualties) | "EVACUATION FAILED" | "{n} casualties at {location} ({hazard})." | "Add exit near {location}" · "Clear the route" |
| FAIL (trapped) | "OCCUPANTS TRAPPED" | "{n} occupants could not reach an exit within {cap} s." | "Add a second exit" · "Remove blocking obstacle" |
| Device unsupported | — | Silent degradation: cards still appear, sourced from this table. A single one-time note in Settings explains that on-device coaching is unavailable on this device. **Never** presented as the intended experience. | — |

### 3.5.5 Cross-run memory & gated extras (fallback-first)

- **Session memory (Should):** the last `RunRecord` for the same venue is included in the digest → "Clearance improved from 4:10 to 2:45 since you widened Exit A." The *comparison arithmetic is done by the engine*; the model only phrases it. Fallback: stateless per-run coaching.
- **Multimodal heatmap (Stretch, `supportsMultimodalFM`):** attach the density-grid snapshot image so the diagnosis can reason about *where*. Fallback: the text-only digest, which is the default path.
- **Agent tools / apply-&-re-run (Stretch, `supportsAgentTools`):** `readRunMetrics()` and `proposeGeometryFix(edit:)` drive one-tap apply. Fallback: the chip performs a **deterministic, engine-side** edit and re-runs — so "apply & re-run" still works without any agent API; only the *authoring* of the edit is AI-assisted.

## 3.6 Retro pixel sound system (Req 6)

**Session:** `AVAudioSession` category `.ambient` with `.mixWithOthers` — the **silent switch is respected** and the user's own music is never interrupted. No background-audio mode.

**Graph:** `AVAudioEngine` → 5 sub-mixers → main mixer. All assets are **all-original 8-bit-style** (square, triangle and noise oscillators rendered offline to short 22.05 kHz mono WAVs; no copyrighted audio). Runtime synthesis is used only for RALLY's voice.

| Bus | Priority | Voices | Contents |
|---|:--:|:--:|---|
| **Mascot** | 1 (highest) | 1 | RALLY blip speech |
| **Alerts** | 2 | 3 | klaxon, stings, verdict fanfares, casualty thud |
| **Hazard** | 3 | 2 | fire crackle loop, water rush loop (panned) |
| **Agents** | 4 | 6 | emotion chirps |
| **Ambience** | 5 | 1 | crowd murmur bed |
| **Budget** | — | **≤ 24 total** | 13 allocated plus headroom; the oldest lowest-priority voice is stolen on overflow |

**Vocabulary**

| Cue | Character | Bus | Trigger | Cooldown / behaviour |
|---|---|---|---|---|
| `amb_murmur` | filtered noise plus a low square bed, looped | Ambience | always after spawn | **volume ∝ mean density** (0.15 → 0.6); **pitch +0 … +3 semitones** with mean arousal — the room audibly tenses |
| `sfx_chirp_confused` | 2-note rising blip "?" | Agents | agent → `uneasy` | 0.4 s per agent; **global max 3/s**; on-screen agents only |
| `sfx_chirp_panic` | short descending squeak | Agents | agent → `panicked` | 0.6 s per agent; global max 2/s |
| `fire_crackle` | noise-burst loop | Hazard | any burning cell | **panned L/R by hazard x** relative to the viewport; gain ∝ burning-cell count |
| `water_rush` | filtered noise sweep loop | Hazard | flood active | panned; gain ∝ flooded area |
| `sfx_klaxon` | 2-tone square alarm, 3 repetitions | Alerts | alarm trigger | once per run; ducks everything by 10 dB |
| `sfx_sting_soft` / `_warn` / `_crit` | 2 / 3 / 4-note descending stings | Alerts | escalation bands (§3.3) | one per band per run, 6 s cooldown |
| `sfx_exit_blocked` | dull clang | Alerts | exit consumed by a hazard | once per exit |
| `sfx_thud` | **muffled** low thud — deliberately soft, never gory | Alerts | casualty | max 1/s; volume capped |
| `sfx_fanfare_pass` | ascending 5-note arpeggio | Alerts | PASS verdict | once |
| `sfx_motif_fail` | descending 4-note minor motif | Alerts | FAIL verdict | once; low, sombre, never comedic |
| `sfx_mascot_blip` | Animalese-**style** per-character blip | Mascot | RALLY talking | 1 blip per 33 ms, whitespace skipped, ±2 semitone jitter per character |
| `sfx_ui_confirm` | two-note rising square blip | Alerts | export / save complete | max 1 per 2 s *(Applied: PATCH-P5a.)* |
| `sfx_bump_soft` | short muted knock | Agents | agent collides with an obstacle (§2.13.5) | global max 2/s; **no haptic** — agent contacts concern the crowd, not the analyst |
| UI taps | soft square clicks | Alerts | tool select, chip tap | 0.05 s |

**Ducking controller** — priority-ordered gain ramps, 0.08 s attack and 0.25 s release:
*Mascot speaking* → Alerts −6 dB, Hazard −8, Agents −10, Ambience −12 · *Alert playing* → Hazard −4, Agents −8, Ambience −8 · *Klaxon* → all others −10. Never a full mute — the room keeps breathing under the coach.

**Controls & accessibility**

- A **master sound toggle** plus independent sub-toggles (Ambience / Agents / Alerts / Mascot voice) in Settings, persisted.
- **Reduce Motion** does not mute audio (they are orthogonal); a separate **"Reduce Audio Intensity"** halves agent-chirp rates, disables the pitch rise on the murmur bed, and caps stings at −6 dB. RALLY's `alert` strobe is disabled by Reduce Motion.
- **Never audio-alone:** every cue has a visual twin — escalations draw timeline markers and banners, casualties place timeline pins, and RALLY's speech is on-screen text. This *is* the caption strategy: the timeline scrubber doubles as a readable event log, and a plain-text **run transcript** is exportable with the PDF report.

## 3.7 Cross-cutting — WWDC26 / AI

Everything in §3.6 and the §3.5.4 canned table is **iOS-26-safe with zero AI dependency** — the Must-tier verdict experience (thresholds, the RALLY sprite, escalations, the full SFX vocabulary) demos identically on a device with no Apple Intelligence. Foundation Models enters only at §3.5.2–3.5.3 (Should), and the two iOS-27-only enhancements are gated behind `DeviceCapabilities` flags whose fallbacks are the default code path. On the iPhone 16 demo device the on-device model **runs live in airplane mode** — that is the Pocket-Brain proof beat.

---

# C. UI/UX — LAYOUT · COLOUR · SF SYMBOLS (Parts 1–3)

## 4.1 IA reconciliation — explicit mapping

The mockups' **Scenarios · Create · Profile** bar collapses into **Spaces · Simulate · Learn**. Rationale: the tab bar should mirror the core loop (Design → Simulate → Verdict) plus the Wellness overlay, not the object types.

| Mock element | Destination | Form |
|---|---|---|
| **Scenarios** tab (scenario cards, difficulty chip, capacity, personal best) | **Spaces** | the "System Presets" section of the Workspace Project Library |
| **Create** tab (new venue) | **Spaces** | toolbar `+` → pushes the **Editor** (a screen, not a tab — you always create *into* the library) |
| **Profile** tab (personal bests, history) | **Spaces** (per card) + **Settings** | score-history sparkline and "Modified 2h ago" on each card; an account-less Settings sheet from the Spaces toolbar |
| — | **Simulate** | run screen: HUD, canvas, timeline scrubber, RALLY, results |
| — | **Learn** | quizzes, preparedness tips, case studies (the Wellness-Loop overlay) |

**Simulate-with-no-context problem (a real design decision):** the tab can be tapped with nothing selected. Resolution — Simulate has three states: **(a)** resume the last run's results if one exists this session; **(b)** show the last-used venue, ready to arm; **(c)** first-launch empty state — a dimmed blueprint grid, "No space loaded", and a primary button to Spaces. Never a blank screen, and never a modal picker on tab tap.

## 4.2 Navigation architecture & screen inventory

`TabView` with 3 tabs; each tab owns an independent `NavigationStack` with its own `path`, so state is preserved when switching. **Maximum 2 push levels per tab** — hackathon discipline; deeper hierarchy is a smell.

| Screen | Tab | Presentation | Title style | Notes |
|---|---|---|---|---|
| Workspace Library | Spaces | root | `.large` "Spaces" | sectioned grid: System Presets / Custom Templates; searchable; drag-reorder (Should) |
| Space Detail | Spaces | push | `.inline` (venue name) | thumbnail, sparkline, capacity, Edit / Simulate / Duplicate / Export |
| **Editor** | Spaces | push | `.inline`, editable venue name | tool sheet; dimension overlay; scale caption "1 Pixel Block = 0.25 m × 0.25 m" |
| Pre-run Config | Simulate | `.sheet` `.medium` | inline | quick-config chips: agent count · crowd mix · alarm delay · scenario |
| **Sim Canvas** | Simulate | root | **hidden** | a custom Liquid Glass HUD replaces the nav bar entirely |
| Results | Simulate | `.sheet` `.medium` → `.large` | inline "Results" | score ring, verdict reasons, charts, A/B, PDF export |
| Learn Home | Learn | root | `.large` "Learn" | quiz card, tips, case-study list |
| Case Study | Learn | push | `.inline` | narrative plus "Play this scenario" → loads the preset |
| Settings | any | `.sheet` `.large` | inline | audio toggles, reduce-audio-intensity, units, "How scoring works", disclaimer, AI-availability note |

**Tab labels and symbols:** Spaces `square.grid.2x2.fill` ✅ · Simulate `play.rectangle.fill` 🟡 (fallback `play.fill` ✅) · Learn `graduationcap.fill` ✅.

## 4.3 Layout geometry & safe areas (iPhone 16 — 393 × 852 pt)

🟡 Insets to confirm in the Simulator: top 59 pt (Dynamic Island), bottom 34 pt (home indicator), tab bar ≈ 49 pt.

> **Rule: the canvas ignores the safe area; every control respects it.** The blueprint grid runs edge to edge (immersion, and the venue is spatial truth), while the HUD, tools and RALLY sit inside the safe insets — so nothing interactive ever hides under the Island or the home indicator.

```text
┌───────────────────────────────┐  ← canvas bleeds to all edges
│ ░ EGRESS │ Nightclub ▾ │ 60fps │  glass HUD bar, top inset +8, h 44, inset 12 side
│ ░ 200 agents │ t+ 42.7s │ ⏻    │  auto-minimizes during playback (Should)
│                               │
│        [ SIM CANVAS ]         │  free zone — never occluded
│                               │
│   ┌─────────────────────┐     │  RALLY card: opposite half from hotspot,
│   │ ▣ RALLY  BOTTLENECK │     │  max w 361, side inset 16
│   └─────────────────────┘     │
│ ▓▓▓ timeline scrubber ▓▓▓▓▓▓▓ │  h 56 — live: progress + event log (no seek);
│                               │  post-run: seek via snapshot replay
│  ◀◀   ▶   ⏸   ⟲   ⚙          │  playback row h 60 — thumb zone (§5.7)
├───────────────────────────────┤
│  Spaces    Simulate    Learn  │  tab bar 49 + 34 inset
└───────────────────────────────┘
```

*(Applied: PATCH-P5b — the scrubber annotation now states its two modes.)*

**Density chips** float over hotspots, clamped to stay at least 12 pt inside the canvas free zone, and never overlap the HUD, the RALLY card or the scrubber. The **Editor** replaces the playback row with the tool sheet (§4.5) and keeps the same HUD slot for the scale caption and dimension toggle.

## 4.4 Dynamic Type strategy

> **Principle: chrome scales, the map does not.** The sim canvas is a metric drawing at 0.25 m per cell — scaling it with text would break spatial truth. Agent sprites, the grid and dimension geometry are fixed to the world scale; only *labels* on the canvas scale, and those are capped.

| Region | Range | Behaviour at accessibility sizes |
|---|---|---|
| Results, verdict reasons, RALLY text, Learn | **full** `.xSmall … AX5` (uncapped) | this is the reading surface — never truncated; the card grows and the sheet expands to `.large` |
| HUD numerics | capped at `.xxLarge` | above the cap the HUD collapses to a **single summary line** (`t+42.7s · 200 · 6.8 p/m²`); full stats move to a tap-to-expand sheet |
| Canvas dimension labels | capped at `.large` | above the cap labels hide and the overlay switches to tap-to-reveal callouts |
| Tool chips / tab bar | system default | `ViewThatFits`: a 2-column chip row becomes stacked full-width rows |
| Buttons | full | minimum 44 × 44 pt touch target at every size |

A `ScrollView` wraps any content that can exceed one screen at AX5. The verdict headline uses `.minimumScaleFactor(0.8)` with `.lineLimit(2)` rather than truncating.

## 4.5 Bottom sheets & detents

| Sheet | Detents | Background interaction | Dismiss | Corner |
|---|---|---|---|---|
| **Editor tools** | `.height(140)`, `.medium` | **`.enabled`** — you must draw while it is open (load-bearing) | drag down to a `.height(56)` handle, never fully | 28 |
| Pre-run config | `.medium` | disabled | interactive ✅ | 28 |
| **Results** | `.medium` → `.large` | disabled | interactive ✅ (results persist in `RunRecord`) | 28 |
| RALLY expanded | `.medium` | `.enabled` (the sim keeps running) | interactive ✅ | 26 |
| Settings / How scoring works | `.large` | disabled | interactive ✅ | 28 |

All use `.presentationDetents`, `.presentationDragIndicator(.visible)`, `.presentationCornerRadius(28)`, and a Liquid Glass background (iOS 26 material; fallback `.ultraThinMaterial` plus `surface.glassTint`).

## 4.6 RALLY card placement — non-blocking rules

| Rule | Spec |
|---|---|
| Placement | the canvas half **opposite** the triggering hotspot (a peak-density cell in the top half puts the card in the bottom half); horizontally centred, 16 pt side insets, maximum width 361 pt |
| Never occludes | the hotspot cell plus a 44 pt halo, the HUD bar, the timeline scrubber, the tab bar |
| Instances | **maximum 1**; a new event replaces the content with a `talk` transition — cards never stack |
| Blocking | never modal; the sim continues; no dimming scrim |
| Interaction | tap → expand sheet (full diagnosis · show the numbers · regenerate) · swipe → dismiss · `×` → dismiss |
| Auto-dismiss | 12 s for in-sim events; **never** for the final verdict card |
| Z-order (bottom → top) | canvas → density glow → hazards → agents → dimension overlay → density chips → **RALLY card** → HUD / scrubber → escalation banner → sheets |
| Reduce Motion | entrance bounce becomes a cross-fade; the `alert` strobe becomes static |
| **Reachability** | if the card lands in the hard-reach zone (more than 520 pt from the bottom), a 44 pt "RALLY" pill appears in the natural thumb zone and re-opens the card as a bottom sheet *(Applied: PATCH-P5c.)* |

## 4.7 Corner smoothing & radius scale

Apple squircles everywhere: `RoundedRectangle(cornerRadius:_, style: .continuous)`. 🔴 Verify iOS 26's `ConcentricRectangle` / `.rect(corner:)` in Xcode 27; `.continuous` is the fallback and ships first.

| Token | Radius | Applied to |
|---|---:|---|
| `radius.xs` | 8 | chips, density pills, tool buttons |
| `radius.sm` | 12 | inline fields, sparkline tiles |
| `radius.md` | 16 | HUD bar, timeline container |
| `radius.lg` | 20 | library cards |
| `radius.xl` | 26 | RALLY card |
| `radius.sheet` | 28 | all sheets |

**Concentric rule:** a nested radius equals the outer radius minus the padding (e.g. 26 card − 10 pad = 16 inner), so corners stay optically parallel.

## 4.8 Semantic colour tokens & dark mode

**Two decisions stated up front.**

**(1) The sim canvas stays dark in Light Mode.** Density glow, fire, smoke and aura legibility all depend on a dark ground; inverting it would destroy the hazard semantics. Chrome (sheets, library, Learn, Settings) adapts fully to Light Mode; the canvas and its HUD are permanently dark. This is a deliberate, disclosed exception, not a missing feature.

**(2) Green conflict resolved — hue carries meaning, shape carries affordance.** The visual identity wants neon data-green for scores, sparklines and primary actions, while the UX rules reserve green / amber / red for density, hazard and verdict semantics. Resolution: **one** green token (`accent.dataGreen` = `verdict.pass`), used only where the meaning is genuinely "safe / improving / correct". Primary actions are distinguished from status by **shape** — a filled glass capsule, 44 pt, elevated — never by inventing a second green. Consequence: destructive and neutral actions are *never* green (Delete uses `verdict.fail` red; Cancel uses `text.secondary` plain). No green appears decoratively anywhere.

**Token table** — contrast ratios computed against `canvas.base` (#0A0E14); 🟡 verify in Accessibility Inspector.

| Token | Hex (dark) | Light mode | Ratio | Use |
|---|---|---|---:|---|
| `canvas.base` | `#0A0E14` | **unchanged** | — | blueprint ground |
| `canvas.grid` | `#1B2430` | unchanged | — | faint dot grid (0.25 m) |
| `canvas.gridMajor` | `#26323F` | unchanged | — | every 4 cells = 1.0 m |
| `surface.glass` | material + `#131A24` @72% | light material | — | Liquid Glass chrome |
| `surface.raised` | `#161E2A` | `#F5F7FA` | — | cards, sheets |
| `separator` | `#2A3644` | `#D8DEE6` | — | hairlines |
| `text.primary` | `#E8EEF5` | `#0E1620` | **16.6:1** ✅ | headlines, metrics |
| `text.secondary` | `#9AA9BA` | `#4A5766` | **8.1:1** ✅ | labels, captions |
| `text.tertiary` | `#74849A` | `#6B7889` | **5.1:1** ✅ | metadata ("Modified 2h ago") |
| `accent.dataGreen` | `#34E27A` | `#0F9D52` | **11.4:1** ✅ | scores, sparklines, primary actions, PASS |
| `accent.cyan` | `#4FD8FF` | `#0A7EA4` | **11.6:1** ✅ | **dimension lines and measurement callouts only — never semantic** |
| `density.comfortable` (<1.8) | `#1E5C46` @25% | unchanged | — | glow band |
| `density.congested` (2–4) | `#C98A2E` @45% | unchanged | — | glow band |
| `density.atRisk` (≥5) | `#E8632B` @65% | unchanged | — | glow band |
| `density.crush` (≥7) | `#FF2D4B` @85% | unchanged | — | glow band |
| `hazard.fire` / `fireCore` | `#FF6B1A` / `#FFD24A` | unchanged | — | flame sprite |
| `hazard.smoke` | `#8B95A3` @variable | unchanged | — | smoke veil |
| `hazard.flood` | `#1E63D6` | unchanged | — | **deepened** so water never reads as a dimension line |
| `verdict.pass` | `#34E27A` | `#0F9D52` | 11.4:1 ✅ | PASS badge, RALLY visor |
| `verdict.warn` | `#F5B93B` | `#9A6B00` | **10.9:1** ✅ | WARN badge, escalation banner |
| `verdict.fail` | `#FF3B5C` | `#C2001E` | **5.6:1** ✅ | FAIL badge, casualty markers |
| `agent.calm` | `#B8C6D6` | unchanged | — | dot / sprite tint |
| `agent.uneasy` | `#F5B93B` | unchanged | — | shares the caution ramp **deliberately** |
| `agent.panicked` | `#FF3B5C` | unchanged | — | shares the danger ramp deliberately |
| `agent.staff` | `#7B5CFF` | unchanged | — | violet — **outside every semantic ramp**, so staff read as "special", not "dangerous" |
| `rally.body` | `#C7D3E0` | unchanged | — | mascot chassis; visor and antenna tint use the verdict token |

**Colour-blind safety (palette level; full pass in §5.6):** the four density bands have **monotonically increasing luminance and saturation** — in greyscale or under deuteranopia, *brighter always means worse*. Redundancy: pattern fill (dot → hatch → cross-hatch → solid), the numeric chip ("6.8 p/m²"), and the banner text. **No state anywhere is signalled by hue alone.**

## 4.9 SF Symbols vocabulary (Part 3)

The deployment target is iOS 26, so SF Symbols 6-era names are available; **the risk is string accuracy, not availability**. Tags: ✅ confident · 🟡 verify spelling · 🔴 likely renamed, use the fallback first. Verify all in the SF Symbols 7 app bundled with Xcode 27. Every symbol ships with an `.accessibilityLabel`; **no icon-only control for a destructive or state-critical action.**

**Editor**

| Action | Symbol | Mode / weight | Tag |
|---|---|---|:--:|
| Draw wall | `pencil.and.ruler` | hierarchical · medium | ✅ |
| Place exit | `door.left.hand.open` | hierarchical · medium | ✅ |
| Freehand draw | `hand.draw` | monochrome · regular | ✅ |
| Place prop / obstacle | `cube.fill` (fallback `square.fill`) | hierarchical | 🟡 |
| Decor (sim-inert) tile | `paintbrush.fill` | monochrome | ✅ |
| Erase | `eraser.fill` | monochrome | ✅ |
| Dimension overlay toggle | `ruler.fill` | palette (cyan / off) | ✅ |
| Grid snap toggle | `square.grid.3x3.fill` | monochrome | ✅ |
| Undo / Redo | `arrow.uturn.backward` / `arrow.uturn.forward` | monochrome | ✅ |

*(`cube.transparent` — the isometric sandbox toggle — was removed: the isometric view is cut, see PATCH-03.)*

**Simulate / HUD**

| Action | Symbol | Mode | Tag |
|---|---|---|:--:|
| Play / Pause / Stop | `play.fill` · `pause.fill` · `stop.fill` | mono · semibold | ✅ |
| Restart run | `arrow.counterclockwise` | mono | ✅ |
| Step back / forward | `gobackward` · `goforward` | mono | ✅ |
| Agent count | `person.3.fill` | hierarchical | ✅ |
| Elapsed time | `timer` | mono | ✅ |
| Density readout | `gauge.medium` (fallback `gauge`) | hierarchical | 🔴 |
| Alarm trigger | `bell.fill` | palette (amber) | ✅ |
| Fire / Smoke / Flood | `flame.fill` · `smoke.fill` · `water.waves` | palette | ✅ / ✅ / 🟡 |
| Event log / scrubber | `waveform` | mono | ✅ |
| Frame-rate pill | *(text only, no symbol)* | — | — |

**Verdict & state**

| State | Symbol | Mode | Tag |
|---|---|---|:--:|
| PASS badge | `checkmark.seal.fill` | palette (green / white) | ✅ |
| WARN badge | `exclamationmark.triangle.fill` | palette (amber / dark) | ✅ |
| FAIL badge | `xmark.octagon.fill` | palette (red / white) | ✅ |
| Casualty marker | `cross.case.fill` | mono | 🟡 |
| Blocked exit | `door.left.hand.closed` | hierarchical | 🟡 |
| At-risk occupants | `figure.stand` / `figure.roll` / `figure.child` | mono | ✅ / 🟡 / 🟡 |
| AI coaching active | `sparkles` | mono | ✅ (avoid `apple.intelligence` 🔴) |

**Spaces / Learn / Settings**

| Action | Symbol | Tag |
|---|---|:--:|
| New space | `plus` (toolbar) / `plus.circle.fill` (empty state) | ✅ |
| Search · Duplicate · Delete · Share | `magnifyingglass` · `plus.square.on.square` · `trash` · `square.and.arrow.up` | ✅ |
| PDF report | `doc.richtext` | ✅ |
| Charts / A-B compare | `chart.xyaxis.line` · `arrow.left.arrow.right` | ✅ |
| Quiz · Tips · Case studies | `graduationcap.fill` · `lightbulb.fill` · `books.vertical.fill` | ✅ |
| Sound on/off · Settings | `speaker.wave.2.fill` / `speaker.slash.fill` · `gearshape.fill` | ✅ |

**Rendering modes and motion.** Default to **hierarchical** (single-tint depth, matching the blueprint aesthetic). Use **palette** wherever a symbol carries semantic state (verdict badges, hazard toggles, the dimension toggle), so the meaningful layer takes the semantic token and the chassis stays neutral. **Multicolour is never used** — it would import Apple's palette and break the reserved-hue rule. Weights: HUD numerics `.semibold`, toolbar `.regular`, empty-state hero glyphs `.light` at 48 pt.

**Variable colour — honest scope:** true `variableValue` only works on symbols authored with sequential layers (`speaker.wave.3.fill`, `cellularbars`). It is used for the **audio-level indicator** only. For live warning escalation — where variable colour would be the obvious choice — the symbol set has no genuine variable-layer equivalent, so we substitute **`.symbolEffect(.pulse)`** on `exclamationmark.triangle.fill`, escalating to `.bounce` at crush level, plus a palette tint change. Same communicative goal, real API. All symbol effects respect **Reduce Motion** (static plus tint change only).

## 4.10 Cross-cutting — WWDC26 / AI

| Adoption | Use here | Tier | Fallback (ships first) |
|---|---|:--:|---|
| Liquid Glass (iOS 26 automatic; iOS 27 refresh free) | HUD bar, sheets, RALLY card, tab bar | Should | `.ultraThinMaterial` plus `surface.glassTint` |
| Toolbar visibility priority / auto-minimising toolbars | the sim HUD minimises during playback and restores on interaction | Should | a manual show/hide chevron on the HUD bar |
| Reorderable grid plus swipe actions on any view | drag-reorder Custom Templates; swipe to Duplicate / Export / Delete | Should | static ordering plus `List` swipe actions |
| `ConcentricRectangle` / `.rect(corner:)` | corner concentricity | 🔴 verify | `RoundedRectangle(style: .continuous)` |
| Foundation Models | RALLY card text only — **no layout depends on it** | Should | the canned table, §3.5.4 |

> **AI layout invariant.** The RALLY card's geometry, placement rules and dismissal behaviour are identical whether the text came from the on-device model or the canned table. If Foundation Models is unavailable the user sees *different words*, never a different or degraded interface.

---

# C. UI/UX — GESTURES · SPRINGS · HAPTICS/AUDIO + ACCESSIBILITY (Parts 4–6)

## 5.1 Gesture conflict resolution (the load-bearing decision)

One canvas serves drawing, panning and zooming — the classic conflict. **Resolution: tool-modality on one finger, invariants on two.**

| Fingers | Editor, tool armed | Editor, Inspect mode | Sim canvas |
|---|---|---|---|
| **1-finger drag** | **draws** (wall run / exit span) | pans | pans the camera |
| **2-finger drag** | **pans** (always — never draws) | pans | pans |
| **Pinch** | zooms (always) | zooms | zooms |
| **Double-tap** | zoom to fit the venue | zoom to fit | zoom to fit |
| **Rotation** | **rejected** — the blueprint is axis-aligned; rotation conflicts with pinch and breaks dimension-label legibility | — | — |

Two-finger pan is the invariant escape hatch, so the user is never trapped in a tool. `SimultaneousGesture` composes pinch with two-finger pan; the one-finger `DragGesture` carries `minimumDistance: 4` to keep taps clean. Tool arming is always visible — the armed chip fills with `accent.dataGreen` and the HUD shows the tool name — so modality is never invisible.

**Zoom clamp:** 0.5×–4×, additionally clamped so that one 0.25 m cell renders between **3 and 40 pt**. Below 3 pt the grid aliases and dimension labels become unreadable; above 40 pt the venue loses context. Zoom-to-fit computes the scale that fits `venue.bounds` plus a 24 pt margin.

## 5.2 Gesture inventory

**Editor**

| Gesture | Target | Result |
|---|---|---|
| Tap | palette item | **arms** the tool (the primary placement model — reliable at 393 pt and VoiceOver-operable) |
| Tap | canvas cell (armed) | places a prop or decor tile at the snapped cell |
| Drag | canvas (wall or exit armed) | draws a run; a live length label in cyan, snapped to 0.25 m |
| **Drag from palette → canvas** | prop | drag-to-place (**Should** — an enhancement over tap-to-arm, never the only path) |
| Tap | element (Inspect) | selects; shows the dimension callout and clear-width label |
| Long-press | element | context menu: Edit width · Duplicate · Lock · **Delete** (destructive, red, confirmed) |
| Long-press | empty canvas | context menu: Paste · Zoom to fit · Toggle dimensions |
| Drag | selected element handle | resize; snaps to 0.25 m; the live cyan dimension updates |

**Simulate**

| Gesture | Result |
|---|---|
| Tap density chip | expands to metric detail (value · band · threshold · location) |
| **Shake** (CoreMotion) | triggers the alarm — a tactile "start the emergency"; **the on-screen `bell.fill` button is always present** as the fallback and the accessible path, never hidden |
| Tap RALLY card | expands to a `.medium` sheet (full diagnosis · show the numbers · regenerate) |
| Swipe RALLY card | dismiss (any direction; 44 pt threshold) |
| Drag scrubber | see §5.3 — behaviour differs live versus post-run |
| Long-press scrubber marker | jumps to that event and shows its tooltip |

**Spaces**

| Gesture | Result |
|---|---|
| Swipe leading | Duplicate |
| Swipe trailing | Export · **Delete** (confirmation dialog; never a single-swipe destroy) |
| Long-press card | context menu plus drag-reorder (Should) |
| Pull-to-refresh | **rejected** — there is no network and no remote state; it would be a lie |

## 5.3 Timeline scrubber — two modes (technical constraint, stated honestly)

A running physics simulation **cannot be scrubbed backwards**: state is produced forward by integration, and rewinding would require re-simulating from t = 0 every frame. So the control has two modes:

| Mode | Behaviour | Affordance |
|---|---|---|
| **During a run** | **Progress plus live event log only.** The waveform fills left to right; markers appear at ignition, jam formation, casualties and threshold crossings. Dragging does **not** seek. | Thumb hidden; markers tappable to *annotate* (tooltip), not to jump |
| **After a run** | **Full seek.** Replays from a recorded snapshot buffer; agents interpolate between frames. | Thumb visible; drag scrubs; markers jump |

**Snapshot ring buffer:** positions only, packed as `2 × Int16` per agent (4 bytes), captured at **10 Hz**. 200 agents × 300 s ≈ 2.4 MB; 500 agents × 600 s ≈ 12 MB. Capped at **16 MB** — on overflow, decimate to 5 Hz rather than dropping the tail, because the end of a run matters most. Emotion and hazard state are stored in a parallel byte lane. The buffer is discarded on a new run and is **not** persisted to SwiftData; only `RunRecord` metrics are.

**Scrub haptics:** a `.selection` tick **only at event markers**, never per frame — continuous ticking during a drag is the definition of haptic fatigue.

## 5.4 Spring physics — motion tokens

One `Motion` enum; no ad-hoc animation values anywhere in the codebase.

| Token | `spring(response:dampingFraction:)` | Applied to | Character |
|---|---|---|---|
| `motion.tap` | `0.25, 0.85` | button and chip press, tool arm | snappy, no overshoot |
| `motion.chip` | `0.30, 0.80` | config chips, density chip expand | slight life |
| `motion.sheet` | `0.45, 0.85` | tool, results and settings sheets | system-like |
| `motion.banner` | `0.35, 0.75` | escalation banner in and out | urgent but not jarring |
| `motion.card` | `0.50, 0.60` | **RALLY entrance bounce** | visible overshoot — the mascot has personality |
| `motion.emote` | `0.28, 0.55` | agent emote badge pop-in ("?", "!") | tiny playful overshoot, scale 0.6 → 1.0 |
| `motion.dismiss` | `0.30, 1.00` | any exit transition | critically damped — nothing bounces on the way out |
| `motion.toolSheet` | `0.40, 0.85` | tool sheet detent change | — |

**Score-ring reveal (results):** not a spring — a **1.2 s** `.easeOut` sweep from 0 to the score with a synchronised count-up numeral, then `motion.card` on the verdict badge. Haptics: light ticks at **at most 8 evenly-spaced points regardless of score** (an 8-tick ceiling, not one per point), then a single `.success` / `.warning` / custom-fail on completion.

**RALLY talk loop:** a frame cycle at 8 fps driven by `TimelineView(.periodic)`, *not* a spring; it runs only while text streams and stops on the last character. The entrance is `motion.card` plus a 12 pt upward offset and opacity.

**Scene-phase transitions**

| Phase | Action |
|---|---|
| `.inactive` | **pause the sim immediately** (no dt accumulation), duck audio to −18 dB, freeze haptics |
| `.background` | stop `AVAudioEngine`, stop `CHHapticEngine`, persist the in-progress `RunRecord`, **cancel the Monte Carlo `TaskGroup`** |
| `.active` (return) | **stay paused** with a "Paused — tap to resume" overlay (never auto-resume a run the user is not watching); restart the audio session and haptic engine before the first cue |

> **Engine restart discipline ✅.** `CHHapticEngine` stops on backgrounding — wire `stoppedHandler` and `resetHandler` to `try? engine.start()`, and lazily restart before any pattern plays. Do the same for `AVAudioEngine` plus session reactivation. This is a top source of "haptics and audio silently died after a phone call" bugs in demos.

**Adaptive degradation**

| Condition | Response |
|---|---|
| `ProcessInfo.isLowPowerModeEnabled` | target 30 fps, disable the Metal glow shader, halve the agent-chirp rate |
| `ProcessInfo.thermalState ≥ .serious` | disable shader effects, show a quiet HUD notice, suggest lowering the agent count |
| Sustained frame time above 20 ms for 2 s | auto-reduce visual effects before reducing the agent count |

> **Invariant.** Performance degradation only ever touches *rendering*. Agent count, `H` and hazard rates are never auto-adjusted — the simulation the user is judged on must stay the simulation they configured.

## 5.5 Haptic + audio event map (Part 6)

**Implementation split (proportionate):** SwiftUI `.sensoryFeedback` for all standard Taptic patterns, plus **exactly three** custom `CoreHaptics` patterns. Three is the entire CoreHaptics scope — enough for signature moments, small enough to build and test in a hackathon.

| Custom pattern | Shape |
|---|---|
| `haptic.klaxon` | 2 transients (intensity 1.0, sharpness 0.9) separated by 0.18 s, repeated 3× over 1.2 s — synced to `sfx_klaxon` |
| `haptic.crush` | 0.9 s continuous, intensity ramping 0.4 → 1.0, sharpness 0.3 — a rising swell, not a buzz |
| `haptic.fail` | 2 transients (intensity 0.7, sharpness 0.2) at 0 s and 0.5 s — low, slow, sombre; deliberately **not** `.error` |

| Event | Haptic | Sound | Both? | Anti-fatigue |
|---|---|---|:--:|---|
| Tool select / chip tap | `.selection` | `ui_tap` | both | — |
| Grid snap while drawing | `.selection` @0.4 | — | **haptic-only** | **only on 1.0 m major lines**, max 8/s |
| Element placed | `.impact(.light)` | `ui_tap` | both | — |
| Invalid placement | `.warning` | — | haptic-only | 1/s |
| Delete confirmed | `.impact(.rigid)` | `ui_tap` | both | — |
| Export / save complete | `.success` | `sfx_ui_confirm` | both | — |
| **Alarm trigger** | `haptic.klaxon` | `sfx_klaxon` | **both** | once per run |
| Congestion ≥ 4.0 | `.impact(.soft)` | `sfx_sting_soft` | both | first crossing only, 6 s cooldown |
| **Bottleneck ≥ 5.0** | `.warning` | `sfx_sting_warn` | **both** | first crossing only, 6 s cooldown |
| **Crush ≥ 7.0** | `haptic.crush` | `sfx_sting_crit` | **both** | first crossing only |
| Exit blocked | `.error` | `sfx_exit_blocked` | both | once per exit |
| **Casualty** | `.impact(.heavy)` | `sfx_thud` | both → **sound-only after 3** | **first 3 casualties only** — a mass-casualty run must not become a buzzing massacre |
| Agent emotion chirp | **none** | `sfx_chirp_*` | **sound-only** | with 200 agents, haptics here are unthinkable |
| Ambient murmur · fire · flood | **none** | loops | **sound-only** | — |
| RALLY appears | `.impact(.soft)` | — | haptic-only | 1 per card |
| RALLY talking | **none** | `sfx_mascot_blip` | sound-only | — |
| Scrub past an event marker | `.selection` @0.5 | — | haptic-only | markers only, never per frame |
| Score ring fill | light ticks ×≤8 | — | haptic-only | fixed 8 ceiling |
| **Verdict PASS** | `.success` | `sfx_fanfare_pass` | **both** | once |
| **Verdict WARN** | `.warning` | `sfx_sting_warn` | **both** | once |
| **Verdict FAIL** | `haptic.fail` | `sfx_motif_fail` | **both** | once |

**Global anti-fatigue rules**

1. **Budget:** at most **1 haptic per 0.5 s**; overflow is dropped by priority (verdict > escalation > casualty > UI), never queued — a haptic that fires late is worse than none.
2. **Intensity cap 0.7** during playback; only crush, casualty and verdict reach 1.0, so the peaks stay peaks.
3. Escalation haptics inherit the §3.3 first-crossing, 6 s cooldown and 10 s re-arm rules — one rule, one place.
4. A **"Reduce Haptic Intensity"** app toggle (mirroring Reduce Audio Intensity) halves all intensities and reduces `haptic.crush` to a single transient.
5. If `CHHapticEngine.capabilitiesForHardware().supportsHaptics` is false, every haptic degrades silently to its sound and visual twin. 🟡 Verify whether Low Power Mode suppresses haptics on iPhone 16; if it does, the visual twin already covers it.
6. **No haptic is ever the sole channel** for a safety-relevant event — every row above with a haptic also has a banner or marker.

## 5.6 Accessibility pass

### VoiceOver — the sim canvas

Two hundred agents cannot be 200 accessibility elements. The canvas is **one** element:

- **Label:** "Simulation canvas, {venue} — {n} occupants."
- **Value (live):** "{elapsed} seconds. {pct}% evacuated. Peak density {d} p/m² at {location}. {casualties} casualties." Updated via `.accessibilityValue` and re-read on demand.
- **Announcements:** escalations, exit blocks and the verdict post via `AccessibilityNotification.Announcement` 🟡, **throttled to at least 4 s apart** and priority-ordered — a crush announcement pre-empts a congestion one.
- **Custom actions** on the canvas: "Describe hotspots" · "Read event log" · "Pause".
- Density chips are individual elements with a label, value and band name ("At risk band").

### VoiceOver — results & RALLY

- **Score ring:** `.accessibilityValue("72 out of 100, caution band")`; the decorative sweep is `.accessibilityHidden`.
- **Verdict reasons:** a semantic list; each reason reads metric, threshold, value and units exactly as displayed.
- **RALLY card:** `.accessibilityElement(children: .contain)` — headline, then metric sentence, then each action chip as a `Button` with a hint ("Applies the fix and re-runs the simulation"). The mascot sprite is `.accessibilityHidden` (decorative); RALLY's *state* is conveyed by the headline text, never by the sprite alone.
- Reading order is set explicitly with `.accessibilitySortPriority` so it runs headline → metric → actions regardless of visual placement.

### ⚠️ Known limitation — freehand drawing is not VoiceOver-operable

Drag-to-draw on a spatial canvas has no honest VoiceOver equivalent, and faking one in 17 days would produce something unusable. **Disclosed limitation with a real alternative:** the *entire* core loop is reachable without drawing —

1. **Preset venues** (6 System Presets) are fully accessible.
2. **Parametric editing** — a form-based "Edit space" sheet: exit clear width (stepper, 0.1 m), add an exit on wall {N/E/S/W}, remove or reposition an obstacle from a list, agent count / mix / alarm delay.
3. That path covers design → simulate → verdict → apply a fix → re-run, i.e. every judged capability.

This goes in the README limitations section and the Settings accessibility note. Honest and scoped beats a broken rotor.

### Reduce Motion — data-motion versus decorative-motion

The key distinction: **motion that carries information stays; motion that carries only delight goes.**

| Motion | Reduce Motion | Why |
|---|---|---|
| Agent walk cycles, position updates | **kept** | *is* the simulation — removing it removes the product |
| Density glow, hazard spread, smoke | **kept** (crossfade instead of pulse) | conveys hazard state |
| Emote badge pop-in | kept, **no overshoot** (fade plus scale 1.0) | conveys emotion |
| RALLY entrance bounce | → cross-fade | decorative |
| RALLY `alert` antenna strobe | → **static** | decorative plus photosensitivity risk |
| `celebrate` confetti | → a single static burst frame | decorative |
| Gyro camera parallax | → **off** | decorative |
| Score-ring sweep | → the number cross-fades to its final value | decorative |
| Sheet and banner springs | → `.easeInOut(0.2)`, no overshoot | decorative |
| Symbol effects (`.pulse` / `.bounce`) | → static plus tint change | decorative |

**Reduce Transparency:** all Liquid Glass surfaces become solid `surface.raised` with a 1 pt `separator` border. Verified against the §4.8 contrast tokens — the text ratios hold, because they were computed against an opaque base.

### Colour-blind safety — shape and pattern redundancy

Pattern fill is **always on**, not a toggle, so the default experience is already accessible:

| Band | Colour | Pattern | Extra redundancy |
|---|---|---|---|
| Comfortable < 1.8 | dark green | **no fill** | — |
| Congested 2–4 | amber | **sparse dots** | chip shows the value |
| At risk ≥ 5 | orange | **diagonal hatch** | chip plus amber banner |
| Crush ≥ 7 | red | **cross-hatch** | chip plus red banner plus `exclamationmark.triangle.fill` |

`@Environment(\.accessibilityDifferentiateWithoutColor)` increases pattern opacity by 40%, gives agent emotion auras outline rings (calm none, uneasy dashed, panicked solid double), and adds inline text labels to verdict badges. Agent emotion is *already* multi-channel: aura colour **plus** emote glyph shape ("?" versus "!") **plus** gait jitter. Staff use `agent.staff` violet **plus** a distinct silhouette — deliberately outside every semantic ramp.

### Captions & transcripts

Every audio cue has a visual twin — that *is* the caption strategy:

| Audio | Visual twin |
|---|---|
| RALLY blip speech | on-screen text, streaming in sync |
| Escalation stings | banner plus timeline marker |
| Klaxon | "ALARM" HUD state plus banner |
| Casualty thud | timeline pin plus casualty counter increment |
| Fire and flood loops | visible hazard rendering |
| Crowd murmur (density-linked) | density chips plus glow |
| Verdict fanfare or motif | verdict badge plus headline |

Plus an **Event Log sheet** (scrollable, timestamped, VoiceOver-readable) mirroring the scrubber, and a **plain-text run transcript** exported alongside the PDF report.

### Targets, contrast, focus

- **44 × 44 pt minimum** on every control. The scrubber renders 20 pt tall but carries a 44 pt hit area. Direct canvas manipulation is exempt — it is spatial, not a control.
- Contrast ratios are verified in §4.8 (lowest text token 5.1:1, lowest semantic 5.6:1 — all at or above WCAG AA). 🟡 Re-verify with Accessibility Inspector on device.
- Focus order: HUD → canvas → RALLY → scrubber → playback → tab bar. Sheets trap focus and return it to the invoking control on dismissal.
- Every icon-only control has an `.accessibilityLabel`; no destructive or state-critical action is icon-only.

## 5.7 Thumb-zone mapping (iPhone 16, 393 × 852 pt)

Measured from the bottom edge for a right-handed one-handed grip 🟡:

| Zone | Range | Contents |
|---|---|---|
| **Natural** | 0–260 pt | tab bar, playback row, scrubber, tool sheet, primary CTA |
| **Stretch** | 260–520 pt | RALLY card action chips, density chips |
| **Hard** | 520–852 pt | HUD readouts (**display-only**), nav title, **destructive actions** (deliberately far from the thumb) |

**RALLY reachability rule:** when the card is placed in the hard-reach top half (because the hotspot is in the bottom half), a persistent **44 pt "RALLY" pill** appears in the natural zone; tapping it re-opens the card as a bottom sheet. No action is ever stranded out of reach.

## 5.8 Cross-cutting — WWDC26 / AI

| Adoption | Use here | Tier | Fallback (ships first) |
|---|---|:--:|---|
| `.sensoryFeedback` (iOS 17+) | all standard haptics | Must | `UIFeedbackGenerator` |
| Auto-minimising toolbars (iOS 27) | the HUD minimises on playback and restores on touch | Should | manual chevron |
| Symbol effects `.pulse` / `.bounce` | live warning escalation (substituting for unavailable variable colour) | Should | static tint change |
| Foundation Models | RALLY **text only** | Should | canned lines |

**Invariants:** no gesture, spring, haptic or accessibility affordance depends on Foundation Models — the entire interaction model is identical on a device with no Apple Intelligence. And no accessibility behaviour sits behind an iOS-27 API; the accessibility pass is fully iOS-26.

---

# B. DAY-BY-DAY BUILD PLAN (Jul 22 – Aug 7, 2026)

## 6.1 Capacity model & the honest headline

**17 calendar days (D1–D17), 2 developers, intermediate, new to Swift.** At roughly 9 h/day that is about 300 person-hours. Learning Swift is an explicit goal, so D1–D5 carry deliberate learning overhead and a lighter feature load.

> **Plainly: this is ambitious.** A social-force crowd simulation, a real-time renderer, an editor, an on-device LLM layer, audio, haptics and an accessibility pass in 17 days by two Swift newcomers is at the edge of feasible. Two things make it tractable: (1) Phases 1–5 already produced an implementation-grade spec, so almost no design work remains during the build; (2) the descope ladder in §6.6 is real and probably *will* be used — the Must tier is protected by design, and everything above it is negotiable.

## 6.2 Developer split & the parallelisation contract

| Dev | Owns | Rationale |
|---|---|---|
| **Dev A — Engine** | `EgressEngine`: standards, venue and agent models, flow field, social force, hazards, metrics, score, verdict, Monte Carlo, event log. Later: audio engine, charts, PDF. | Algorithm-heavy, pure Swift, headless-testable — the best surface for learning Swift *language* fundamentals without fighting SwiftUI at the same time. |
| **Dev B — App** | The SwiftUI app: design system, canvas renderer, editor, HUD, sheets, Spaces and Learn, RALLY, the AI seam, haptics, accessibility. | UI-heavy; learns SwiftUI and Observation. |

**The contract that makes parallel work possible:** `SimulationSnapshot` is **locked on D2**, and Dev A immediately ships `MockSimulation` — a roughly 40-line fake that emits agents orbiting toward a fake exit. Dev B builds the entire renderer, HUD, gestures and camera against the mock, then swaps in the real engine on D5. **Neither dev is ever blocked on the other.** If the engine slips, the UI still demos; if the UI slips, the engine still tests.

**Pairing windows (deliberate, not ad-hoc):** D5 (engine ↔ renderer integration), D9 (end-to-end wiring for G2), D14–D15 (bug bash). Everything else is parallel.

## 6.3 Gate definitions — compile & test criteria

A gate is passed only when **every** row is true, verified **on the physical iPhone 16** — the Simulator has no haptics, no real thermal or performance behaviour, and no Foundation Models parity.

| Gate | Day | Build | Tests | On-device | Artifact |
|---|---|---|---|---|---|
| **G0** Toolchain & risk retirement | D2 Jul 23 | `swift build` clean; the app archives with Xcode 27 against the iOS 27 SDK, deployment target iOS 26 | at least 6 engine tests green: grid↔world round-trip, `SeededRNG` determinism, `SafetyStandards` values | app installs and launches; **`SystemLanguageModel.availability` result recorded**; every 🔴 symbol resolved to ✅ or a chosen fallback | risk log in the README |
| **G1** Walking skeleton | D5 Jul 26 | green main | flow field reaches all passable cells · no corner-cutting · spatial-hash neighbour sets correct · 10 k-step integrator stability (no NaN or blow-up) | 200 agents spawn → path to the exit → all evacuate; **at least 55 fps sustained** (60 target, 55 floor) in Instruments; pan, zoom and fit all work | `golden-skeleton` tag |
| **G2** ★ **MUST TIER** | D9 Jul 30 | green main | density grid versus a hand-computed fixture · clearance and at-risk metrics · **score formula reproduces the §2.8 worked examples (Concert Crush = 7, Office = 98)** · verdict order, all 6 branches · **faster-is-slower: non-monotonic throughput across a panic sweep** · determinism (same seed → identical clearance) | clean launch → draw a room → 2 exits → 200 agents → alarm → fire and emotions → live escalation banner → verdict, score and reasons. **Airplane mode. 3 consecutive runs, zero crashes.** | **`golden-must` tag plus archived build** |
| **G3** Should tier | D13 Aug 3 | green main | Monte Carlo determinism · **V1–V8 validation gate, each with a crafted malformed-output fixture** · ring-buffer replay fidelity | RALLY renders on-device model text in airplane mode; **a forced-fallback run produces an identical layout with canned lines**; audio ducking, master toggle and silent switch all correct | `golden-should` tag; **toolchain pinned** |
| **G4** Polish & accessibility | D15 Aug 5 | green main | full suite green | Accessibility Inspector clean on Results, RALLY and Spaces · VoiceOver completes the accessible path (preset → parametric edit → simulate → verdict) with no dead end · Reduce Motion / Reduce Transparency / Differentiate Without Color verified · AX5 Dynamic Type with no truncation · 30-minute soak: no crash, no memory growth, thermal below `.serious` | **CODE FREEZE** · `release-candidate` tag |
| **G5** Submission | D17 Aug 7 | — | — | README complete (setup · architecture · technologies · limitations · demo steps) · AI-tool and zero-third-party disclosure · **secret scan clean** · recording covers problem → journey → technical proof → track proof → outcome with voiceover | submitted |

## 6.4 Stage 1 — foundations & Must tier (D1–D9)

| D | Date | Dev A — Engine | Dev B — App | End-of-day check |
|:--:|---|---|---|---|
| 1 | **Wed Jul 22** | Xcode 27 plus Apple Silicon / macOS 26.4 verified; repo, `EgressEngine` package and `.gitignore`; `Vec2`, `GridCoord`, `GridGeometry`, `SeededRNG` plus first tests. *Swift focus: structs, value semantics, optionals.* | App target and `TabView` shell (Spaces / Simulate / Learn) running **on the physical iPhone 16**; **⚠️ AI-availability spike** (`SystemLanguageModel.availability`); **beta-SDK build-acceptance spike** (archive → install). *Swift focus: SwiftUI view and state basics.* | both devs build and run on device |
| 2 | **Thu Jul 23** | `SafetyStandards`, `VenueModel` / `Exit` / `Obstacle` / `DecorTile`; **lock `SimulationSnapshot`**; ship `MockSimulation` to Dev B | `ColorTokens`, `Motion` and the radius scale (infrastructure, not polish); **resolve all 🔴 SF Symbol strings in the SF Symbols 7 app**; `ConcentricRectangle` check | **G0** |
| 3 | Fri Jul 24 | `FlowField`: multi-source Dijkstra, no corner-cutting, wall-distance and normal field; maze fixture tests | `SimCanvasView`: `TimelineView(.animation)` plus `Canvas`, dot grid, rendering **mock** agents; pan and zoom gestures plus clamps (§5.1) | mock agents animate at 60 fps |
| 4 | Sat Jul 25 | `SpatialHash`, `AgentSpawner`, drive force and semi-implicit Euler (no repulsion yet) — agents reach the exit | HUD bar, playback row, camera clamp 3–40 pt per cell, double-tap to fit, **manual HUD show/hide chevron** *(the fallback, built before the iOS-27 auto-minimising toolbar)* | engine agents evacuate headlessly |
| 5 | Sun Jul 26 | Full social force: pedestrian repulsion, contact and friction, wall force; substepping at H = 1/120 with the dt clamp | **Swap `MockSimulation` → real `Simulation`**; Instruments profile on device | **G1** — *pairing day* |
| 6 | Mon Jul 27 | `DensityGrid` (bin plus separable blur), `Metrics`: clearance, peak density, at-risk person-seconds | **Editor**: draw walls, place exits, 0.25 m snap, tool sheet, undo and redo; **prop palette plus the separated Hazards palette** (§2.13.8) | draw a furnished room → simulate it |
| 7 | Tue Jul 28 | Fire cellular automaton, smoke diffusion, and **dirty-flag flow-field recompute**; casualty classification (fire / smoke / crush); **hazard flinch** (§2.13.8) | Hazard and density-glow rendering; **cyan dimension overlay** plus the "1 Pixel Block = 0.25 m × 0.25 m" caption | the crowd visibly reroutes around fire |
| 8 | Wed Jul 29 | `SafetyScore`, `VerdictRules`, `RunEventLog`, live-escalation predicates | Results sheet, score ring, verdict badges, **canned banner strings**, escalation banner | the verdict computes and displays |
| 9 | **Thu Jul 30** | Tuning pass; **faster-is-slower validation test**; determinism test | Spaces library plus **6 furnished presets** (§2.13.3 — authored to clear the aisle minima) and pre-run config chips; **end-to-end wiring** | **G2 ★ MUST TIER — `golden-must`** *(pairing day)* |

## 6.5 Stage 2 — Should tier, polish, ship (D10–D17)

> **MoSCoW gate:** no work below starts until G2 is signed off. If G2 slips, §6.6 governs.

| D | Date | Dev A | Dev B | End-of-day check |
|:--:|---|---|---|---|
| 10 | Fri Jul 31 | Flood automaton; **anticipatory dodge + commitment**; **bump, stumble, obstacle memory** (§2.13.4–5) | **RALLY** sprite sheet, card and **canned lines**, plus haptics (`.sensoryFeedback` and the 3 CoreHaptics patterns) *(the canned coach ships a day before the AI coach — fallback first)* | agents visibly dodge furniture and stumble on contact; RALLY appears with canned text |
| 11 | Sat Aug 1 | Snapshot ring buffer (10 Hz, ≤ 16 MB); **aisle clear-width analysis plus verdict reason 4d** (§2.13.7); A/B compare support | **AI layer**: `CoachingService`, the `@Generable` schemas, the **V1–V8 validation gate**, fallback wiring; **expressive emote layer** (§2.13.6) | model text renders in airplane mode; the coach can cite a blocked aisle |
| 12 | Sun Aug 2 | **Morning only:** `AudioEngine` bus graph and ducking skeleton (SFX asset generation moves to D13) | **Morning only:** timeline scrubber live mode (replay-seek mode moves to D13) | **½-day rest — afternoon off, no exceptions** *(Applied: PATCH-08.)* |
| 13 | **Mon Aug 3** | SFX asset generation; Swift Charts (evacuation curve, density timeline); **Monte Carlo if time allows, else cut** (§2.13.12); PDFKit report | Scrubber replay-seek mode; Learn tab (quiz plus 3 case studies); Liquid Glass pass, auto-minimising toolbar, reorderable grid | **G3 · `golden-should` · TOOLCHAIN FREEZE** |
| 14 | Tue Aug 4 | **Parametric edit form** (the accessible authoring path) plus transcript export | VoiceOver labels, values and announcements; the Reduce Motion split; patterns; Dynamic Type; **debug touch-indicator overlay** for the recording | the accessible path completes end to end |
| 15 | Wed Aug 5 | Constant tuning from playtesting; performance and thermal degradation paths | Bug bash; empty, error and unavailable states; contrast audit | **G4 · CODE FREEZE · `release-candidate`** |
| 16 | Thu Aug 6 | README: setup · architecture · technologies · **limitations** · disclosure | **Record the demo** (§E script), multiple takes | recording in hand |
| 17 | **Fri Aug 7** | Final edit and voiceover; secret scan; submission | Buffer for the unexpected | **G5 · SUBMITTED** |

> **D16–D17 rule:** no new features. Only crash-level fixes, and only with both devs signing off on the diff.

## 6.6 Descope ladder — triggers and cut order

**Triggers — check at the named gate and act the same day; do not hope:**

| Trigger | Action |
|---|---|
| **AI-availability spike fails on D1** | The Pocket-Brain track proof is at risk. Escalate immediately: (a) source an AI-capable device, or (b) re-open the track decision. Deliberately a Day-1 check so there is time to act. |
| **60 fps missed at 200 agents by D5** | Step down in this order: 150 agents → dot rendering instead of sprites → drop the Metal glow → background-stepping upgrade (§A.7). **Never below 100 agents** — it must still read as a crowd. |
| **G1 not met by end of D6** | Cut Monte Carlo, A/B, PDF and the Learn quiz from the plan outright; Dev B pairs on the engine until G1 passes. |
| **G2 not met by end of D11** | Fall back to the **Smaller Version** (§0.1 #10): one venue (Nightclub), fire only, 200 agents, touch-drawn rooms, canned verdict, no AI. Abandon the Should tier except RALLY with canned lines. |
| **Toolchain breaks after D13** | Roll back to the pinned build; the `golden-should` archive is the submission fallback. |

**Cut order (first to go → last), revised for the §2.13 batch:** widget / Siri → `.egress` export → AI heatmap and apply-&-re-run → **stall-triggered exit re-decision** → **Monte Carlo** → PDF report → Learn quiz (keeping the case studies as static text) → A/B compare → **expressive emote layer** → flood hazard → retro SFX (keeping 4 core cues).

> **Ranking note.** Anticipatory dodge, bump/stumble and aisle analysis rank **above** Monte Carlo, PDF and the quiz, and are not in the cut list at all above the floor. Monte Carlo yields a predicted-range chip; this batch yields a crowd that visibly thinks. Expressive emotes sit lower because they are display-only and cost nothing to remove.

**The floor — never cut:** the editor, fire and smoke, agent emotions, **furnished venues** (§2.13.3 — an empty box is not a shippable room), the verdict engine, and RALLY. If RALLY must shrink, it degrades to a *static* sprite with canned card text (near-zero cost, high demo value) rather than disappearing.

## 6.7 Daily discipline

| Ritual | When | Purpose |
|---|---|---|
| 15-minute standup | each morning | yesterday · today · blockers |
| **Explain-back review** | 20 minutes, end of day | Each dev walks the other through their diffs. **Anything neither can explain is rewritten or deleted.** This is how "the team must understand every line" and "AI-generated code is untrusted until reviewed, compiled and tested" become an actual mechanism rather than an aspiration. |
| Green-main rule | every merge | feature branches; `swift test` green before merging; main always compiles |
| **Daily device run** | end of day | the app runs on the physical iPhone 16, not just the Simulator |
| Golden build | at each gate | tag plus archive. **You can always submit the last golden build's recording** — the single best insurance against a late regression. |
| Secret hygiene | continuous | no keys, tokens or sensitive test data committed |

## 6.8 Toolchain & beta discipline

| Date | Action |
|---|---|
| D1–D2 | Beta-SDK **build-acceptance spike**: archive and install on the physical device |
| Through D12 | Xcode and OS updates allowed only immediately after a passed gate, never mid-stage |
| **D13 Mon Aug 3** | **PIN.** Record the exact Xcode build number and device OS build in the README. **No Xcode or OS updates after this date.** |
| D13–D17 | If anything breaks, roll back to the pin; `golden-should` is the fallback submission |

> **Demo-OS decision.** With a single demo device, running an iOS 27 beta risks the entire submission for features that are all **Stretch tier**. The Must and Should tiers — including on-device Foundation Models coaching — are fully iOS-26-capable. So the demo device runs **stable iOS 26**, while the *build* toolchain stays Xcode 27 / Swift 6.4 / iOS 27 SDK. Modern toolchain, zero beta risk on demo day. If a second device becomes available, it takes the iOS 27 beta and the Stretch showcase.

## 6.9 Cross-cutting — WWDC26 / AI

> **Scheduling invariant: every fallback is implemented on an earlier calendar day than its enhancement.** Cutting any single modern API therefore never breaks the core — it just removes a layer.

| Adoption | Fallback built | Enhancement attempted | Tier |
|---|---|---|:--:|
| Foundation Models coaching | **canned lines D10** | model plus V1–V8 gate **D11** | Should |
| Liquid Glass | tokens plus material fallback **D2** | glass pass **D13** | Should |
| Auto-minimising toolbar | manual chevron **D4** | **D13** | Should |
| Reorderable grid / swipe actions | static order **D9** | **D13** | Should |
| Symbol effects (`.pulse` / `.bounce`) | static tint **D2** | **D13** | Should |
| Multimodal heatmap debrief | text digest **D11** | only if G3 lands early | Stretch |
| Agent tools / apply-&-re-run | deterministic engine-side edit **D11** | only if G3 lands early | Stretch |
| `.egress` document export | PDF report **D13** | only if G3 lands early | Stretch |
| Xcode 27 agentic coding | — | **process, daily**, bounded by the explain-back review | Process |

---

# D. RISK REGISTER

**Scoring:** L(ikelihood) and I(mpact) as H/M/L. "Fallback" is what actually ships if the risk lands — never "try harder."

| ID | Risk | L | I | Early warning signal | Pre-emptive mitigation | Concrete fallback | Owner | Gate |
|---|---|:-:|:-:|---|---|---|:-:|:-:|
| **R-01** | Engine complexity overruns the schedule | **H** | **H** | G1 not met by end of D6 | Engine-first sequencing; `MockSimulation` unblocks Dev B; headless tests over UI debugging | Dev B pairs onto the engine; cut Monte Carlo, A/B, PDF and quiz outright; if G2 slips past D11 → **Smaller Version** | A | G1/G2 |
| **R-02** | 60 fps unattainable at 200 agents | **M** | **H** | Instruments below 55 fps sustained on device at D5 | Spatial hash O(n); flow field not recomputed per frame; density grid once per frame; profile on **device** from D1 | Step down: 150 agents → dots instead of sprites → drop the Metal glow → background stepping with double buffering. **Floor 100 agents** | A/B | G1 |
| **R-03** | **Apple Intelligence unavailable on the demo device** (device tier, region or language) — kills the Pocket-Brain track proof | **L** | **H** | `SystemLanguageModel.availability` is not `.available` on **D1** | 🟡 The iPhone 16 is a capable device, but **device state is the only authority** — checked on D1, not assumed. Ensure Apple Intelligence is enabled and model assets are downloaded **while online**, before the airplane-mode demo | Demo runs on `CannedCoach` with **script variant B** (§E.6): reframe from "the model wrote this" to "the deterministic engine wrote this, and here is where the model plugs in." Escalate on D1: source another device or re-open the track choice | B | **G0** |
| **R-04** | Beta toolchain instability or a late build break | M | H | Xcode 27 crashes, archive fails, previews die | Demo device on **stable iOS 26**; build-acceptance spike D1–D2; **pin the toolchain Aug 3**; golden tag at every gate | Roll back to the pin; submit the **`golden-should` archive plus its recording** | A | G0/G3 |
| **R-05** | API churn between betas breaks working code | M | M | Compile errors after an Xcode update | No updates mid-stage; updates only immediately post-gate; every iOS-27 call availability-gated with the fallback already shipping | Delete the gated enhancement — the fallback is already the default path. Zero core impact by construction | A | G3 |
| **R-06** | Foundation Models output is poor, slow or refuses | M | M | Latency above 4 s, or V1–V8 failures in testing | Number-free prose plus `MetricKey` substitution; the V1–V8 gate with crafted malformed fixtures; a streaming UI so latency is felt as typing | `CannedCoach` — **identical card layout, different words**. The user sees no broken UI | B | G3 |
| **R-07** | Scope creep / tier violation | **H** | M | Work starting on a Should item before G2 signs off | The MoSCoW gate is a hard rule; the daily standup names the current tier; the cut order is pre-agreed | Enforce the cut order top-down, same day. Golden builds mean a cut never costs the demo | Both | all |
| **R-08** | A developer is lost for days (illness, exam, outage) | M | H | Any full day missed | Green-main plus the daily explain-back means neither dev's work is a black box; both can build and run the whole app | The remaining dev defends the **Must tier only**; everything Should-and-above is cut without discussion | Both | G2 |
| **R-09** | **The physics does not produce the wow** — jams look like sludge, faster-is-slower does not emerge, crowds look like particles rather than people | M | **H** | The faster-is-slower test does not reproduce at D9; playtests read as "dots drifting" | Constants are tunable in one file; the validation test is a **gate criterion**, not an afterthought; emotion is multi-channel (aura plus emote glyph plus gait) so humanity reads even at dot scale | Raise `K_FRIC` and `K_BODY`; narrow the demo exit to force a visible jam; **worst case, demo the Nightclub preset tuned by hand** — a preset that reliably jams is honest, because it is a real layout with a real flaw, and the seeded RNG makes it reproducible | A | G2 |
| **R-10** | Demo device fails on the day (crash, thermal, battery, notification, call) | M | **H** | Any crash in the 30-minute soak at G4 | Airplane mode (which also kills notifications) plus Do Not Disturb, battery above 80%, a cool device and fixed brightness; three-consecutive-run stability is a G2 criterion; haptic and audio engine restart handlers | **The recording is the submission.** Record at least 5 good takes on D16 so no live performance is ever load-bearing | B | G4 |
| **R-11** | The recording runs long, or the journey does not fit 3 minutes | M | M | First take over 3:30 | A beat sheet with timestamps (§E.2); rehearse with the fixed seed; voiceover recorded separately so the edit can breathe | Cut the A/B re-run to a **split-screen still** (before and after numbers) — saves about 20 s and keeps the payoff | B | — |
| **R-12** | Audio or haptics silently die after an interruption | M | M | A silent app after backgrounding in testing | `stoppedHandler` / `resetHandler` restart plus session reactivation on `.active`; explicitly tested in the G4 soak | Master sound toggle off; the visual twin of every cue already carries the meaning | B | G4 |
| **R-13** | Memory growth or thermal throttling over a long session | L | M | Ring buffer above 16 MB; `thermalState ≥ .serious` in the soak | Ring buffer capped with 5 Hz decimation; degradation touches **rendering only**, never the physics | Shorten the demo run; disable shader effects; the 30-minute soak at G4 is the proof | A | G4 |
| **R-14** | Work lost (repo, disk or a bad merge) | L | H | — | Remote push after every merge; tag plus archive at every gate; the plan itself lives in `EGRESS_PLAN.md` in-repo | Restore the last golden tag; at most one day lost | Both | all |
| **R-15** | **Real-disaster content handled insensitively** — Itaewon and Astroworld killed real people | M | **H** | Any copy that reads as a game level, a leaderboard, or blame | See §D.1 — this is a product-integrity risk, not a PR one | Ship **static text case studies with no playable recreation**. The Wellness overlay survives intact; the interactive recreation is expendable | B | G4 |
| **R-17** | **Dodging destabilises the crowd** — dense furniture plus predictive steering plus contact forces produces gridlock, jitter or side-oscillation | M | M | Playtest at D10 shows agents vibrating, deadlocking in aisles, or flip-flopping between sides | `DODGE_COMMIT` enforces side commitment; dodge strength is gated by `awareness_eff`; obstacle memory decays; presets authored to clear the aisle minima; a dedicated stability test in the §2.13.11 suite | **Set `A_DODGE = 0`** — agents revert to pure flow-field routing plus the existing wall force, which is the behaviour already validated at G1 and G2. One constant, no code change, no regression | A | G3 |
| **R-18** | **Expressive emotes read as trivialising** — crying badges over a simulated mass-casualty event | L | **H** | Any playtest reaction of "this feels like a game about people dying" | The §2.13.6 tone rules are binding: no gore, no screaming, a restrained teardrop badge, and **total suppression on real-incident presets** (matching §D.1) | Ship only the existing "?" and "!" badges. The display layer is separate from the physics, so removal costs nothing | B | G4 |
| **R-16** | Overclaiming — output mistaken for certified engineering advice | L | **H** | Any UI string implying compliance, approval or certification | A persistent disclaimer string; RALLY is named a **coach**, never an inspector or marshal; the PDF report carries the disclaimer in its header | Strengthen the wording; put the disclaimer on the results card, in the PDF, in the README, and spoken in the demo voiceover | B | G4 |

## D.1 R-15 handling rules (binding, not advisory)

The Learn tab's real-disaster case studies are the Wellness-Loop overlay's substance and its sharpest risk. Rules:

1. **Framing is educational and structural**, never dramatic: what the geometry did, what the standards say, what a different layout would have changed. No casualty photographs, no victim names, no re-enactment of individual deaths.
2. **No score, no leaderboard, no difficulty chip, no personal best** on a real-event preset. Those exist for fictional venues only. A real tragedy is not a level to beat.
3. **Neutral, non-blaming language.** Describe conditions and geometry; do not assign fault to organisers, police or victims. Where cause is contested or under investigation, say so.
4. **RALLY is silent on real-event presets** — no mascot, no jokes, no personality. The coach appears only on user-authored and fictional venues.
5. **Sourced and dated**, with a line stating that the recreation is approximate and educational.
6. **Cheap exit:** if any of the above cannot be done well by G4, ship the case studies as static text and drop the playable recreation. Cost: one Stretch feature. Benefit: the product stays defensible.

## D.2 Residual risk after mitigation

| Risk area | Post-mitigation exposure |
|---|---|
| Schedule (R-01 / R-07 / R-08) | **Moderate.** The descope ladder guarantees *something* complete ships; it does not guarantee the Should tier. Most likely landing zone: Must tier plus RALLY with AI plus partial Should. |
| Track proof (R-03 / R-06) | **Low**, because it is retired on **Day 1** rather than discovered on Day 16. |
| Demo failure (R-04 / R-10) | **Low** — golden builds plus a pre-recorded demo mean no single failure on Aug 7 can sink the submission. |
| Product integrity (R-15 / R-16) | **Low**, provided §D.1 is treated as binding. |

---

# E. DEMO, README & RECORDING

## E.1 What the demo must prove

Problem → complete product journey → technical proof → **track proof** → outcome. Voiceover throughout; **never unexplained taps**.

## E.2 Three-minute demo script — beats ordered for escalation

Total **180 s**. Airplane mode is established in the first 10 seconds so that it pays off at 1:45. Voiceover lines are indicative, not a read-aloud script.

| Time | Beat | On screen | Voiceover | Why it lands here |
|---|---|---|---|---|
| **0:00–0:12** | **Problem** | Title card → app launch on device, **airplane-mode indicator visible in the status bar** | "Crowd-evacuation analysis costs thousands and lives in consultancy software. This is Egress — it runs entirely on an iPhone, offline. Note the airplane mode; it stays on for the whole demo." | States the problem and plants the proof before it is needed |
| 0:12–0:35 | **Design** | Spaces → new space → draw walls, place two exits; cyan dimension lines snap; caption "1 Pixel Block = 0.25 m × 0.25 m"; the exit labelled "Clear width 1.2 m" | "Everything is to scale — a quarter-metre grid, real clear widths, real exit capacity ratings from published crowd-safety practice." | Establishes credibility *before* the eye candy, so the pixel art reads as engineering, not a toy |
| 0:35–0:48 | **Populate & arm** | Config chips: 200 agents, crowd mix, alarm delay; the crowd spawns as pixel people; **shake to trigger** | "Two hundred simulated people — adults, children, elderly, wheelchair users, staff — each with their own walking speed, awareness and patience." | The mix is what makes it humane rather than particulate |
| **0:48–1:22** | ★ **Simulate** (longest beat) | Alarm klaxon; agents react at staggered delays; **crowds thread between the bar and the standing tables, swerving early**; fire ignites and spreads; smoke veils; **an exit blocks and the crowd visibly reroutes**; as smoke thickens, agents start **clipping the furniture and stumbling**; density glow goes amber → orange; emote badges — "?", "!", a teardrop near the jam | "Fire spreads cell by cell, and smoke cuts their awareness — watch what that does. Early on they thread between the tables cleanly. As visibility drops, the same people start walking into the furniture. Nothing there is scripted: dodging is gated by how much each person can see, so clutter gets more dangerous exactly as the smoke arrives." | The wow beat, and the strongest single proof that the agents are simulated rather than animated |
| 1:22–1:33 | **Live escalation** | Amber banner "BOTTLENECK DETECTED" plus haptic and sting; density chip "6.8 p/m²" over the hotspot | "It flags the problem while it's happening — 6.8 people per square metre, past the at-risk band." | Proves it is an analysis tool, not a replay |
| 1:33–1:47 | **Verdict** | Sim ends; results sheet; score ring counts up; **FAIL** badge; reasons list with units | "Verdict: fail. Three casualties at Exit A. Clearance 168 seconds against a 120-second target. Every number comes from the simulation — the thresholds are published standards, and you can see exactly which one was violated." | Delivers the primary outcome |
| **1:47–2:12** | ★ **Track proof — RALLY, offline** | The RALLY card animates in; text **streams** in; the camera tilts to show the status bar still in airplane mode | "This diagnosis is being written right now by Apple's on-device foundation model — still in airplane mode, nothing leaving the phone. It's spotted that the aisle between the bar and the tables is 0.7 metres, below the 1.2 metre minimum. And it can't invent numbers: the model writes the language, the engine supplies every figure." | The Pocket-Brain proof, and the anti-hallucination design is itself a differentiator worth 8 seconds |
| **2:12–2:40** | ★ **Payoff — apply & re-run** | Tap "Widen Exit A to 1.2 m" → the editor applies → re-run at the **same seed** → A/B: clearance 168 s → 96 s, casualties 3 → 0, score 41 → 88, **PASS** plus fanfare | "One change. Same crowd, same fire, same random seed — and everybody gets out. That's the whole point: not scoring a room, but showing which change saves people." | Strongest closer — proves the product *works*, not merely that it renders |
| 2:40–2:55 | **Breadth (fast cuts)** | 3 s each: VoiceOver reading the verdict · a Learn tab case study · the PDF report · the Swift Charts evacuation curve | "Fully accessible, with a parametric editing path for VoiceOver users. Case studies from real incidents. Exportable reports." | Shows depth without narrating it |
| 2:55–3:00 | **Close** | Score card with the disclaimer line visible | "Egress. Professional crowd-safety analysis, offline, in your pocket. Educational analysis — not certified engineering advice." | The disclaimer **in the voiceover** is deliberate (R-16) |

**Cut-for-time order if a take runs long:** the breadth montage (−15 s) → the design beat trimmed to preset selection (−12 s) → A/B shown as a split-screen still instead of a live re-run (−20 s). **Never cut** the simulate beat, the offline callout, or the disclaimer.

## E.3 Track proof — explicit checklist

| Track | What the recording must show | Timestamp |
|---|---|---|
| **Pocket Brain** | Airplane mode visible at the start **and** during generation · RALLY text streaming live on-device · voiceover stating that the model writes language while the engine supplies numbers · a fix suggestion tied to real geometry that measurably improves the re-run | 0:00–0:12, 1:47–2:12, 2:12–2:40 |
| **Wellness Loop** | A genuine safety problem with real standards and units · a supportive, non-sensational coach tone on FAIL · accessibility shown, not claimed · the educational disclaimer spoken and on screen · responsible real-incident framing | 1:33–1:47, 2:40–3:00 |

## E.4 Screen-recording plan

**Capture:** **QuickTime Player on the Mac → New Movie Recording → source = iPhone over USB-C.** Preferred over iOS Control Centre recording because it does not consume device CPU or thermal headroom during a 200-agent 60 fps run, and it produces a clean file with no in-frame recording indicator. 🟡 Confirm the capture frame rate; if it cannot hold 60 fps, fall back to on-device Screen Recording and accept the extra load — test both at G4, not on D16.

**Showing taps (the "no unexplained taps" requirement):** iOS shows no touch indicator in either capture path. Build a **debug touch-indicator overlay** — a 32 pt translucent `accent.dataGreen` circle on touch-down, fading on release, behind a `#if DEBUG` flag or a Settings toggle. About 30 minutes of work on D14, and it makes every interaction legible. Voiceover carries the rest.

**Device setup (D16 checklist):** airplane mode **on** (proof plus notification suppression) · Do Not Disturb · battery above 80%, plugged in · brightness fixed, auto-brightness off · Low Power Mode **off** (it degrades to 30 fps) · device cool before each take · True Tone and Night Shift off for consistent colour · **Apple Intelligence model assets confirmed downloaded while online, before airplane mode goes on** (R-03) · demo venues pre-seeded in Spaces · **fixed simulation seed set** so every take produces the identical run.

**Audio:** record the voiceover **separately** (Voice Memos or a USB mic) and lay it over the edit — live narration into a phone mic while tapping is the classic ruined take. Keep app SFX at a moderate level under the voiceover; duck the app audio by 12 dB beneath speech in the edit.

**Takes:** a minimum of **5 clean full runs** on D16. Because the seed is fixed, takes are directly comparable and cuttable together. Keep one **unedited single-take run** in reserve as evidence that the journey works end to end without editing tricks.

**Edit:** a 2 s title card · no speed-ramping of the simulation, since it would misrepresent real-time performance (if anything, add a "1× real time" caption during the sim beat) · captions burned in for accessibility · export at 1080 × 1920 or 1170 × 2532, H.264, 60 fps if the source allows.

## E.5 README outline

```markdown
# Egress — offline crowd-evacuation designer
> One-paragraph pitch + hero GIF + the disclaimer line.

## What it does
Problem · target user · the Design → Simulate → Verdict loop · Safety Score.

## Demo
Recording link · 5-step "run it yourself" (launch → open Nightclub preset →
200 agents → shake to trigger → read the verdict) · the fixed demo seed.

## Setup
Xcode 27 (build ____) · Swift 6.4 · iOS 27 SDK · deployment target iOS 26 ·
Apple Silicon Mac on macOS Tahoe 26.4+ · open Egress.xcodeproj · run on device.
Note: on-device coaching needs an Apple-Intelligence-capable iPhone; the app is
fully functional without it (canned coaching).

## Architecture
Diagram: EgressEngine (pure Swift, no UI imports) → SimulationSnapshot → SwiftUI.
Why the package boundary · threading model · determinism (seeded RNG).

## Technologies
Apple frameworks used and what each earns its place for.
**Third-party dependencies: none.**

## The simulation
Social force model · flow-field pathfinding · hazard automata · emotional states.
**Real-world grounding:** every constant, its value, its unit, its source
(SFPE / Fruin density bands / geometry minima) — the SafetyStandards table.

## The intelligence layer
On-device Foundation Models · the number-free-output design · the V1–V8
validation gate · graceful degradation to canned coaching.

## Accessibility
What's supported · **Known limitation: freehand drawing is not VoiceOver-
operable; the accessible path is presets + parametric editing, which covers the
entire core loop.**

## Limitations & honest scope
iPhone only · educational, not certified engineering advice · hazard rates are
plausible and time-compressed, not validated fire modelling · RoomPlan not
supported on the demo hardware · what is demo-mode vs production.

## AI usage disclosure
AI coding assistance was used during development (Xcode 27 coding assistant).
All submitted code was reviewed, compiled and tested by the team.

## Credits & licence
All pixel art and audio original. No third-party assets.
```

## E.6 Contingency — demo script variant B (AI unavailable on the day)

If `SystemLanguageModel` is unavailable at recording time, **do not fake it and do not hide it.** Swap the 1:47–2:12 beat for:

> "Egress separates its safety spine from its intelligence layer. Everything you've seen — the physics, the thresholds, the verdict — is deterministic and always works. On an Apple-Intelligence-capable device, the on-device model turns these numbers into plain-language coaching; here you're seeing the deterministic fallback, which is what every user gets when the model isn't available. Same interface, same numbers, different words."

Then show the canned RALLY card and continue to the apply-&-re-run payoff, which is engine-side and unaffected. This costs the Pocket-Brain showcase but keeps the demo honest and the product intact — and the graceful-degradation architecture is itself worth showing. **Use only as a last resort; R-03 exists to make it unnecessary.**

## E.7 TestFlight checklist (optional — not required)

Only if time is genuinely free after G4; **never** at the cost of the recording.

| Step | Note |
|---|---|
| Apple Developer account and bundle ID | A paid account is required for TestFlight |
| Archive with the **pinned** toolchain | Must match the golden tag |
| App Store Connect record, screenshots, description | Include the educational disclaimer |
| Export compliance | No encryption beyond what the OS provides → standard exemption |
| Privacy nutrition label | **No data collected** — the honest and easy answer here |
| Internal testers | Availability is not instant; do not schedule this on Aug 7 |
| Beta review | External testing needs review; internal does not |

## E.8 Cross-cutting — WWDC26 / AI

| Item | Demo treatment |
|---|---|
| On-device Foundation Models | **Shown and named as the track proof** — the only modern-tech callout that gets explicit voiceover time, because it changes what the user gets |
| Liquid Glass, symbol effects, auto-minimising toolbar | **Visible, never narrated.** They should read as polish, not as a feature list |
| Multimodal heatmap · agent tools · `.egress` · widget | Only if they shipped; **not** mentioned if cut. Never described as "planned" in a demo |
| Xcode 27 agentic coding | README disclosure only — a process fact, not a product feature |
| Every gated adoption | If any is missing on the day, the fallback is already the default path — the demo is unaffected by construction |

---

# F. SWIFT LEARNING NOTES · DISCIPLINE · DEFINITION OF DONE

## F.1 How to use these notes

Two devs, intermediate programmers, new to Swift, learning **while** shipping. The rule that makes that safe: **learn the concept the day before you need it, not the day you're stuck.** Each stage below lists the minimum Swift surface required for that stage's tasks — deliberately *minimum*. Anything not listed is not needed yet, and chasing it is scope creep in disguise.

Verification is per stage and concrete: if you cannot answer the "check yourself" question without looking it up, you do not understand the code you are about to ship — which is exactly what the explain-back review catches.

## F.2 Per-stage learning map

| Stage | Days | Dev | Swift / SwiftUI surface | Where it appears in Egress | Newcomer trap | Check yourself |
|---|---|:--:|---|---|---|---|
| **S1 Foundations** | D1–D2 | A | `struct` versus `class`, **value semantics**, `let` / `var`, optionals with `if let` / `guard let`, `enum` with associated values, `Codable`, computed properties | `Vec2`, `GridCoord`, `VenueType`, `SafetyStandards` | Assuming a `struct` passed to a function can be mutated by it | Why does mutating a copied `VenueModel` not affect the original? |
| | D1–D2 | B | A SwiftUI view is a **value**, not an object; `body` recomputation; `@State`, `@Binding`; `TabView` / `NavigationStack`; view modifiers return new views | App shell, `ColorTokens`, `Motion` | Thinking `body` runs once, or storing mutable state in a plain `var` on a `View` | Why does a plain `var` on a `View` reset every redraw? |
| **S2 Algorithms** | D3–D5 | A | `Array` performance and `reserveCapacity`, `ContiguousArray`, index-based loops, `inout`, `simd` operators, generics basics, custom `Comparable` for a heap | `FlowField` Dijkstra, `SpatialHash`, social force | `[[Int]]` nested arrays in a hot loop; `enumerated()` inside per-frame code | What is the cost of appending to an array you did not reserve? |
| | D3–D5 | B | `Canvas` with `GraphicsContext`, `TimelineView(.animation)`, `GeometryReader`, coordinate spaces, `DragGesture` / `MagnifyGesture`, `SimultaneousGesture` | `SimCanvasView`, camera, gestures | Doing layout work per frame inside `Canvas`; fighting gesture composition instead of composing it | Why is `Canvas` faster than 200 `Circle()` views? |
| **S3 State & data** | D6–D9 | A | Protocols and protocol witnesses, `some` / `any`, error handling with `throws`, `Result`, access control (`public` versus `internal` — the package boundary is enforced by it) | Engine public API surface, `VerdictRules` | Marking everything `public`; the package boundary only holds if you are deliberate | Why does the app fail to compile if it touches an `internal` engine type? |
| | D6–D9 | B | **`@Observable`** (Observation), `@Environment`, `@Bindable`, sheets with `presentationDetents`, `ViewThatFits`, `@ScaledMetric` | Editor, tool sheet, Results, HUD | Using `@Published` / `ObservableObject` habits from older tutorials — this project uses **Observation**, not Combine | What causes a view to re-render under `@Observable`? |
| **S4 Concurrency** | D10–D11 | A | `async` / `await`, `Task`, `TaskGroup`, **actor isolation**, `@MainActor`, `Sendable`, `Task.checkCancellation()`, `AsyncStream` | Monte Carlo, audio setup | **The big one — see §F.3** | Why can a `@MainActor` type not be constructed inside `Task.detached`? |
| | D10–D11 | B | `async` in SwiftUI (`.task`), structured output decoding, streaming updates to the UI, avoiding `MainActor.run` | `CoachingService`, RALLY streaming | Awaiting on the main actor and freezing the sim loop | Where exactly does the model call hop off the main actor? |
| **S5 Polish** | D12–D15 | A | `AVAudioEngine` node graph, Swift Charts marks, PDFKit drawing, memory and retain cycles (`[weak self]` in closures and handlers) | Audio, charts, PDF | Strong-capture cycles in audio and haptic engine handlers → leaks | Which closures in `AudioEngine` need `[weak self]`, and why? |
| | D12–D15 | B | Accessibility modifiers, `@Environment(\.accessibility*)`, `.symbolEffect`, `ScenePhase` | Accessibility pass, motion, lifecycle | Adding labels without testing with VoiceOver actually on | Can you complete the whole loop with the screen curtain on? |

## F.3 Swift 6 strict concurrency — the crash course (read on D1, not D10)

This is the single largest source of confusing compiler errors for newcomers, and it is the area where AI-generated code most often produces something that compiles under Swift 5 mode and fails under Swift 6.

| Concept | What it means here | Rule for this project |
|---|---|---|
| **Isolation** | A type marked `@MainActor` can only be touched from the main actor. | Only *UI-facing* types are `@MainActor`. **`Simulation` is not** — it is a plain class used from exactly one context at a time. |
| **`Sendable`** | Safe to hand across isolation boundaries. Value types of `Sendable` members qualify automatically. | Every type crossing engine → UI (`SimulationSnapshot`, `VenueModel`, `Metrics`, `Verdict`) is a `Sendable` value type. That is why the boundary is clean. |
| **Compile-time data-race safety** | The compiler rejects shared mutable state across actors. | If you are fighting the compiler, the design is usually wrong: pass a *copy* (a snapshot); do not share the simulation. |
| **`nonisolated`** | Opts a member out of its type's isolation. | Use sparingly, and only on pure functions. |
| **`Task` versus `Task.detached`** | Structured versus unstructured; detached inherits nothing. | Monte Carlo uses `withTaskGroup`, and each child builds its **own** `Simulation`. Never share one. |
| **Cancellation** | Tasks must check it to actually stop. | Monte Carlo checks `Task.isCancelled` every N steps and on scene backgrounding. |

> **The mental model to carry:** the engine is a fast, single-threaded machine; concurrency exists only to run *several independent copies* of it (Monte Carlo) and to keep the UI responsive. There is **no shared mutable simulation state anywhere** — that design choice is what makes Swift 6 strict concurrency painless instead of painful.

## F.4 Swift 6.4 conveniences worth adopting (and what to skip)

| Feature | Use it? | Why |
|---|---|---|
| `anyAppleOS` availability shorthand | 🟡 **skip** | iPhone-only — one platform, so `@available(iOS 27, *)` is already minimal |
| Optional `any` / `some` without parentheses | ✅ yes | Free readability in the `CoachingService` protocol surface |
| `@diagnose` per-declaration warning control | ⚪ only if needed | Useful to silence one known-noisy warning; never to hide real ones |
| Module selectors (`::`) | ⚪ unlikely | Only if `EgressEngine` and the app collide on a type name — prefer renaming |
| `UniqueArray` / borrow-based `Iterable` | 🟡 **skip for v1** | Real performance tools, but ownership semantics are a poor first-week Swift topic. Revisit only if profiling at G1 demands it |
| `async` cleanup in `defer` | ✅ if it fits | Handy for audio and haptic engine teardown |
| **Swift Testing** (`@Test`, `#expect`, `#require`) | ✅ **yes, as the default** | The recommended framework; XCTest interop exists if needed. All engine tests use it |

🔴 Verify the exact syntax for anything on this list in Xcode 27 before relying on it — these come from release summaries, not from compiling.

## F.5 SwiftUI performance notes for Dev B (D3–D5 is where this is decided)

1. **`Canvas` draws; views do not.** 200 agents means 200 draw calls in one view, not 200 SwiftUI views. Never consider the latter.
2. **`TimelineView(.animation)` drives the clock.** Compute the snapshot once per tick and draw from it. Do not call engine methods from inside drawing code.
3. **Hoist everything constant out of the draw loop** — resolved images, paths, fonts, `GraphicsContext.resolve(_:)` results.
4. **Instrument on device from D1.** Simulator frame rates are meaningless for this decision.
5. **`@Observable` granularity:** a single observable holding the whole snapshot will re-render everything that reads it. Split HUD state from canvas state so a HUD text change does not invalidate the canvas.

## F.6 Learning-versus-shipping guardrail

Time-box any Swift concept to **45 minutes**. Past that, take the working-but-uglier approach, leave a `// LEARN:` comment, and move on — then bring it to the evening explain-back. A hackathon is not the place to master ownership or custom property wrappers. Learning is a goal; the gates make shipping a constraint; the 45-minute box is where those two live together.

## F.7 Implementation discipline (recap — governs the build)

| Rule | Mechanism in this project |
|---|---|
| **Smallest end-to-end path first** | G1 walking skeleton: launch → spawn → path → evacuate. No editor, no hazards, no UI polish until that runs on device. |
| **Inspect before building; preserve existing work** | Greenfield here, so this becomes: do not rewrite a passing module to make it prettier mid-sprint. |
| **Reuse sound code; native Swift naming** | Engine API names are locked in §A.3 — use them verbatim so both devs read the same vocabulary. |
| **Small increments; report what changed · what was verified · next action** | The daily standup format, literally these three fields. |
| **Compile and test after each meaningful increment** | The green-main rule; `swift test` green before every merge. |
| **An honest local seam when blocked** | `MockSimulation` (D2) and `CannedCoach` (D10) are both real seams — documented and shipped, not hacks. Demo mode is separated and disclosed. |
| **Do not declare success until it compiles and the primary flow has been exercised** | Gate criteria are all "on the physical iPhone 16", not "builds clean". |
| **AI-generated code is untrusted until reviewed, compiled and tested** | **Explain-back review**, daily, 20 minutes: each dev walks the other through their diffs; anything neither can explain is rewritten or deleted. This is the enforcement mechanism for "the team must understand every line". |

## F.8 DEFINITION OF DONE — final checklist

Confirm every row before calling the submission ready. Verified on the **physical device**, from a **clean install**.

**Product**

- [ ] Primary journey works from a clean launch — no hidden setup, no manual steps, no pre-warmed state.
- [ ] Launch → design → simulate → verdict → fix → re-run completes without a crash, three consecutive times.
- [ ] Loading, empty, offline, denied-permission, unavailable-feature and recoverable-error states all exist on the main journey (motion permission denied → on-screen trigger; model unavailable → canned coach; no saved spaces → empty state with a call to action).
- [ ] Every measurable value displays in real SI units with its unit shown.
- [ ] The educational disclaimer is visible in-app, in the PDF, in the README, **and spoken in the demo**.

**Technical**

- [ ] Full test suite green: determinism, flow-field correctness, integrator stability, metrics, score worked examples, verdict branches, **faster-is-slower**, V1–V8 validation fixtures.
- [ ] 60 fps target met (55 fps floor) at the shipped agent count on device; 30-minute soak with no crash, no unbounded memory growth, and thermal below `.serious`.
- [ ] Every iOS-27 API is availability-gated and its fallback is the default path; removing any single gated feature breaks nothing.
- [ ] Toolchain pinned (Xcode build number and device OS build recorded in the README); the final archive built from the pin.
- [ ] Golden tag archived at each gate; `release-candidate` tagged at code freeze.

**Accessibility** (checked on the actual interaction model — iPhone, touch plus VoiceOver)

- [ ] VoiceOver completes the accessible path end to end with no dead end.
- [ ] Reduce Motion, Reduce Transparency and Differentiate Without Color all verified.
- [ ] Dynamic Type to AX5 with no truncation on reading surfaces.
- [ ] Contrast audited with Accessibility Inspector; all text at or above WCAG AA.
- [ ] No state signalled by colour alone; no safety event signalled by audio or haptic alone.
- [ ] 44 × 44 pt minimum on every control.

**Disclosure & hygiene**

- [ ] **No secrets, keys or sensitive test data committed** (scan run, result recorded).
- [ ] Third-party dependencies: none — stated explicitly.
- [ ] AI development-tool usage disclosed; all submitted code reviewed, compiled and tested.
- [ ] All pixel art and audio original; no copyrighted assets.
- [ ] Real-incident content complies with the §D.1 handling rules.
- [ ] README complete: setup · architecture · technologies · **limitations** · demo steps.

**Demo**

- [ ] The recording shows problem → complete journey → technical proof → **track proof** → outcome.
- [ ] Voiceover throughout; the touch indicator is visible; no unexplained taps.
- [ ] Airplane mode visible at the start and during AI generation.
- [ ] One unedited single-take run held in reserve.
- [ ] At least 5 clean takes captured; the final cut is 3 minutes or under.

---

# APPENDIX 1 — APPLIED PATCH LOG

Every PATCH emitted during Phases 1–8 that targets a section of this file, with its effect. All are **already applied inline above** — this table is provenance, not a to-do list.

| ID | Issued | Target | Change |
|---|:--:|---|---|
| **P1a** | Phase 1 | §0.4 "Selected platforms" | Rewritten to iPhone-only; iPad, Pencil, macOS, visionOS, Watch and TV explicitly out of scope |
| **P1b** | Phase 1 | §0.4 tech table | `NavigationSplitView` row replaced with `TabView` + `NavigationStack` (iPhone-only) |
| **P1c** | Phase 1 | §0.4 tech table | PencilKit / PaperKit row deleted |
| **P5a** | Phase 5 | §3.6 audio vocabulary | Added `sfx_ui_confirm` (export / save complete, max 1 per 2 s) |
| **P5b** | Phase 5 | §4.3 layout diagram | Scrubber annotation now states both modes (live progress versus post-run seek) |
| **P5c** | Phase 5 | §4.6 RALLY placement | Added the reachability rule (44 pt pill in the natural thumb zone) |
| **PATCH-01** | Phase 8 | §A.3, §A.7 | ⚠️ **Load-bearing fix.** `Simulation` was declared `@MainActor` while Monte Carlo instantiates it off-main — mutually exclusive under Swift 6 strict concurrency, and it would have surfaced as a compiler error around D10. `Simulation` is now a plain `final class` with an explicit single-context isolation rule |
| **PATCH-02** | Phase 8 | §A.3, §2.9, §2.10 | Preset agent counts of 250–350 exceeded the 200-agent count validated at G1/G2. Added `maxValidatedAgents` (default 200); all presets clamp on load; above-budget counts show a HUD notice; the demo never exceeds the budget |
| **PATCH-03** | Phase 8 | §4.9, scope | The isometric Engineering Sandbox view had no allocated day. Cut to Stretch and unscheduled; the `cube.transparent` toggle removed; the cyan dimension overlay carries the engineering identity instead. Crowd theme packs likewise Stretch |
| **PATCH-08** | Phase 8 | §6.5 (D12) | A half-day rest had been scheduled against a full day of work. D12 is now morning-only work for both devs, with SFX assets and scrubber replay-seek moved to D13 |

| **PATCH-09** | User req. | §2.13 (new), §A.3, §A.4, §3.3, §3.5.2, §3.5.3, §3.6, §6.4–6.6, §D, §E.2 | **Obstacle interaction, NPC behavioural intelligence and expressive emotion.** Adds: furnished-by-default venues with `Obstacle.isRelocatable`; anticipatory dodge steering gated by `awareness_eff`; bump / stumble / obstacle memory; obstacle-derived aisle clear-width analysis (reusing `FlowField.wallDist`) surfacing as WARN reason 4d and `MetricKey.aisleClearWidth`; a display-only expressive emote layer; fire and water as editor-placeable hazard props via the existing `HazardSeed`. Records the **no-LLM-per-agent** decision. Funded by demoting Monte Carlo in the cut order. New risks R-17 and R-18 |

**Consistency items verified clean (no patch needed):** the Safety Score worked examples reproduce exactly (Concert Crush = 7, Office = 98); `SIM_TIME_CAP` matches `clamp(3 × target, 300, 600)` for all six venues; the §3.2 disagreement band is arithmetically 5.0–6.0 p/m² as stated; ring-buffer sizings (2.4 MB and 12 MB) are correct at 4 bytes per agent per 10 Hz frame and stay under the 16 MB cap for every venue at its time cap; verdict rule 2 is reachable (maximum non-casualty penalty 60 → score 40); the escalation cooldown is stated identically in §3.1, §3.3 and §5.5; every fallback in §6.9 is scheduled earlier than its enhancement.

---

# APPENDIX 2 — AMENDMENTS TO THE MASTER PROMPT REQUIREMENT BLOCKS

These PATCHes target the source prompt's `[R-*]` blocks rather than this file. They are recorded here so the plan and the prompt stay reconciled.

| ID | Target block | Amendment |
|---|---|---|
| **A-01** | `[R-CONTEXT]` build window | "22 July – 7 Aug 2026" is **17 calendar days (D1–D17)**, not 16. |
| **A-02** | `[R-STACK]` SwiftUI line | `NavigationSplitView` → **`TabView` + per-tab `NavigationStack`** for the iPhone-only scope. |
| **A-03** | `[R-STACK]` audio line | Session is `.ambient` with `.mixWithOthers`; the silent switch is respected and the user's audio is never interrupted. **No background-audio mode** — Egress has no reason to play while backgrounded, and claiming that capability would be an unjustified entitlement. |
| **A-04** | `[R-WWDC26]` `appearsActive` row | **Dropped.** That refinement dims custom glass cards when a window is inactive — an iPad/macOS multi-window concern with no meaning at iPhone-only scope; adopting it would be scorecard-chasing. The automatic Liquid Glass refresh is retained. |
| **A-05** | `[R-WWDC26]` beta discipline | The single demo device runs **stable iOS 26**, not the iOS 27 beta. The Must and Should tiers are entirely iOS-26-capable, so a beta OS would risk the whole submission for Stretch-tier features only. Build toolchain unchanged (Xcode 27 / Swift 6.4 / iOS 27 SDK). Pin on Aug 3. If a second device is available it takes the beta and the Stretch showcase. |
| **A-06** | `[R-VISUAL]` item 1 | `hazard.flood` is `#1E63D6`, deliberately deeper than `accent.cyan` `#4FD8FF`, so water never reads as a dimension line. Cyan is reserved exclusively for measurement and carries no safety semantics. |
| **A-07** | `[R-VISUAL]` item 3 | The isometric extruded-wall sandbox is **cut to Stretch and unscheduled**; the app ships the top-down Sim View plus the cyan dimension overlay. A static isometric thumbnail is the cheap version if G3 lands early. |
| **A-08** | GLOBAL RULES MoSCoW | **Must** = drawn rooms + crowd sim + emotions + fire + score + verdict banners with canned messages. **Should** = flood, Monte Carlo, A/B compare, mascot with AI coaching and jokes, retro SFX, quiz, Liquid Glass polish. **Stretch** = AI heatmap debrief, apply-&-re-run, widget / Siri, `.egress` sharing, isometric thumbnail. **Cut entirely: RoomPlan** (no LiDAR on the demo device), **Pencil authoring, iPad and macOS reach**. |
| **A-10** | `[R-VISUAL]` item 4 · `[R-SIM]` item 2 | Props are not optional dressing: **every System Preset ships furnished**, and an empty rectangle is never a shippable venue. Props gain `isRelocatable`, distinguishing movable furniture from structural elements the coach may never propose relocating. Agents actively **dodge** obstacles (predictive steering gated by awareness) and **collide** with them when perception fails, with stumble, arousal spike and obstacle memory. Emotional expression is extended beyond "?" and "!" with a **display-only** reaction-emote layer that never touches the physics. Fire and water become **editor-placeable hazard props**. Full specification in §2.13. |
| **A-09** | SECONDARY FEATURES | The "daily drill" notification and widget are **out of scope** — no notification permission, scheduling or WidgetKit extension is planned or built. Shipping a permission prompt for a feature that does not exist would violate the Definition of Done. Real-incident case studies are governed by §D.1. |

---

# APPENDIX 3 — VERIFICATION REGISTER (RESOLVE AT G0)

Every load-bearing claim tagged 🔴 or 🟡 across the plan, in one place. **G0 (D2, Jul 23) requires each 🔴 to be resolved to ✅ or replaced by its named fallback.**

| # | Item | Tag | How to verify | Fallback if it fails |
|:--:|---|:--:|---|---|
| 1 | `@Generable` / `@Guide` constraint spellings (`.count`, `.range`, description form) | 🔴 | Compile the §3.5.2 schemas in Xcode 27 | Plain `@Generable` structs with prompt-level constraints plus stricter V1–V8 checks |
| 2 | SwiftUI Metal shader modifier names (`.colorEffect` / `.layerEffect` / `.distortionEffect`) | 🔴 | Xcode autocomplete plus a trivial shader | Plain SwiftUI gradients and fills for glow and smoke |
| 3 | `ConcentricRectangle` / `.rect(corner:)` | 🔴 | Xcode autocomplete | `RoundedRectangle(style: .continuous)` (already the shipping default) |
| 4 | `gauge.medium` symbol string | 🔴 | SF Symbols 7 app | `gauge` |
| 5 | `play.rectangle.fill`, `cube.fill`, `water.waves`, `cross.case.fill`, `door.left.hand.closed`, `figure.roll`, `figure.child` | 🟡 | SF Symbols 7 app | `play.fill`, `square.fill`, `drop.fill`, `bandage.fill`, `door.left.hand.open`, `figure.stand`, `figure.stand` |
| 6 | `SystemLanguageModel.availability` result on the demo device | 🔴 | **Run on the physical iPhone 16, D1** | `CannedCoach` plus demo script variant B (§E.6) — and escalate |
| 7 | Whether Low Power Mode suppresses haptics on iPhone 16 | 🟡 | Toggle Low Power Mode, fire each pattern | The visual twin already covers every haptic |
| 8 | `AccessibilityNotification.Announcement` priority API spelling | 🟡 | Xcode autocomplete plus a VoiceOver test | Post plain announcements with manual throttling |
| 9 | iPhone 16 safe-area insets (59 / 34 pt) and thumb-zone boundaries | 🟡 | Simulator plus on-device measurement | Read insets dynamically from `GeometryReader`; never hard-code |
| 10 | Contrast ratios in the §4.8 token table | 🟡 | Accessibility Inspector on device | Darken or lighten the token until AA passes |
| 11 | QuickTime USB capture frame rate at 60 fps | 🟡 | **Test at G4, not on D16** | On-device Screen Recording, accepting the extra load |
| 12 | Swift 6.4 syntax specifics in §F.4 | 🔴 | Compile each before relying on it | Use the Swift 6.0-era equivalent; none is load-bearing |
| 14 | §2.13.10 dodge, bump and emote constants | 🟡 | Playtest at D10; the §2.13.11 stability and no-tunnelling tests | `A_DODGE = 0` reverts to the G1/G2-validated behaviour (R-17) |
| 15 | Furnished presets still reproduce the §2.8 worked examples (Office = 98 / PASS) | 🔴 | Preset regression test at **G2**, run after prop authoring | Re-author the offending prop layout to clear the aisle minimum |
| 13 | All numeric constants in `SimConstants` (force coefficients, hazard rates, score weights) | 🟡 | Playtest tuning; the faster-is-slower test at G2 | Raise `K_FRIC` / `K_BODY`; hand-tune the Nightclub preset (R-09) |

---

*End of `EGRESS_PLAN.md`. Planning complete through Phase 8; the build begins at D1 (22 July 2026). The first item on the critical path is the Day-1 Apple Intelligence availability spike — the one open risk that could still change the track.*
