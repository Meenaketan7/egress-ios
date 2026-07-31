# EGRESS — BUILD PLAN v3 (RUBRIC-ALIGNED)

Use the claude_design MCP (https://api.anthropic.com/v1/design/mcp, auth via /design-login) to import this project:
https://claude.ai/design/p/6552a350-c0c8-41d0-83d7-b41b15533b29?file=Egress+App+UI.dc.html

Focus on these files (the whole project is readable):

- `Egress App UI.dc.html`

Also read these files the selection imports:

- `support.js`

Implement: `Egress App UI.dc.html`

> **Canonical planning document.** Phases 0–8 of the Master Planning & Build Prompt v4 with all PATCH blocks applied inline, then **revised against IndeHub Rubric v1.0 and the Hacker Guide** (indehub.org/hackathon/2026/guide, last updated 25 Jul 2026). Original provenance is in Appendix 1; source-prompt amendments in Appendix 2; **the v3 rubric revision log is Appendix 4**.
>
> **Product:** Egress — an offline, on-device crowd-evacuation simulator for iPhone.
> **Event:** The IndeHub Hackathon 2026 · **The Pocket Brain** track (Wellness overlay) · 2 developers.
> **Disclaimer carried by the product:** _educational analysis, not certified engineering advice._

## ⛔ HARD DATES — ELIGIBILITY IS PASS/FAIL AND CHECKED BEFORE ANY SCORING

| Date (IST)                | Event                                                                                                              |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **31 Jul 2026, 11:59 PM** | **REGISTRATION CLOSES.** Nothing else in this document matters if the team is not registered.                      |
| 1 Aug 2026, 00:00         | Submissions open                                                                                                   |
| **7 Aug 2026, 11:59 PM**  | **SUBMISSION DEADLINE.** No build, video, feature, or clarification may be changed, replaced, or added afterwards. |
| 8–10 Aug 2026             | Evaluation · finalists emailed 10 Aug                                                                              |
| **22 Aug 2026**           | **Bengaluru finale** — 5-minute demonstration + 5 minutes of questions, five judges, self-funded travel            |

**Irreversible at registration:** 1–3 Indian nationals; members cannot be added, removed, or replaced afterwards; one project per team; one sponsored track.

## THE FOUR FACTS THAT SHAPE v3

1. **Video-only submission.** No paid Apple Developer account, therefore no TestFlight. The recording is the _sole_ evidence for both asynchronous judging rounds — two judges at preliminary, three more re-scoring fresh at semifinals.
2. **Two artifacts, not one.** 7 August delivers a _video_. 22 August is a _live demo_, twelve days later. v2 conflated them into a single "demo day".
3. **Source code is not submitted, and no judge reads it.** Documentation volume explicitly earns nothing. Stop writing for a reader who does not exist.
4. **Scope must roughly halve.** v2 was sized for a 17-day window from a standing start. Whatever remains is materially less. The "Smaller Version" of §0.1 #10 is **no longer a fallback — it is the plan** (§3.2 of the revised scope, §6).

## STATUS TRACKER

| Phase  | Title                                                           | Status | Date           |
| ------ | --------------------------------------------------------------- | :----: | -------------- |
| 0      | Understand + Commit                                             |   ✅   | 2026-07-22     |
| 1      | A. Architecture                                                 |   ✅   | 2026-07-22     |
| 2      | Simulation Deep Spec (reqs 1–4)                                 |   ✅   | 2026-07-22     |
| 3      | Verdict + Mascot + Retro SFX (reqs 5–6)                         |   ✅   | 2026-07-22     |
| 4      | C. UI/UX parts 1–3                                              |   ✅   | 2026-07-22     |
| 5      | C. UI/UX parts 4–6 + accessibility                              |   ✅   | 2026-07-22     |
| 6      | B. Build sequence                                               |   ✅   | 2026-07-22     |
| 7      | D. Risk register · E. Demo script                               |   ✅   | 2026-07-22     |
| 8      | F. Learning · Discipline · DoD · consistency                    |   ✅   | 2026-07-22     |
| **v3** | **Rubric alignment against IndeHub Rubric v1.0 + Hacker Guide** |   ✅   | **2026-07-29** |
| —      | **PLANNING COMPLETE — build in progress**                       |   ✅   | —              |

## STATE CAPSULE (v3 — ground truth for the build)

**Track:** Pocket Brain + Wellness overlay; 100% offline on-device Foundation Models.
**Platform:** iPhone-ONLY. Demo iPhone 16 on **stable iOS 26**; build toolchain Xcode 27 · Swift 6.4 · iOS 27 SDK; deployment target iOS 26; every iOS-27 API availability-gated, fallback-first. **v3 rule: only what actually runs on the demo device may be claimed anywhere** — form, video, or voiceover (criterion 3 gives zero for "mentioning an API that is not functional in the submitted product").
**Targets:** `Egress` app; pure `EgressEngine` library (Foundation + simd only); Swift Testing.
**Engine:** `SafetyStandards` · `SimConstants` · `VerdictConstants`; `VenueModel`/`Exit`/`Obstacle`; `Agent`/`AgentTraits`/`EmotionalState`; `FlowField` (multi-source Dijkstra, no corner-cutting); `HazardField` (Fire CA / Smoke — **flood cut in v3**); `SpatialHash`; **`Simulation` = plain `final class`, NOT `@MainActor`** (PATCH-01); `SimulationSnapshot` contract; `Metrics`/`DensityGrid`/`SafetyScore`; `RunEventLog`; `VerdictRules`. **Cut in v3: `MonteCarlo`, snapshot ring buffer, PDFKit, Metal glow, audio bus graph.** Social force τ 0.5 / A_PED 12 / K_BODY 60 / K_FRIC 40 / R_INT 1.2; H = 1/120 s, dt ≤ 1/30 s; hazards 15 Hz. Score = 100 − C(min 60, cas×25) − D(×25) − R(×20) − T(×15). Seeded RNG ⇒ reproducible demo.
**Verdict:** PASS 80 / FAIL 50 / PEAK 5 / CRUSH 7 / RISK 0.15; cap = clamp(3 × target, 300, 600) s; any occupant trapped ⇒ FAIL; **rules table = authority, Safety Score = communication**; escalation on first crossing, 6 s cooldown.
**Obstacles & NPC intelligence (§2.13):** every venue **furnished by default**; `Obstacle.isRelocatable` gates coach relocation fixes; **anticipatory dodge** raycast (`T_LOOK` 0.8 s, `A_DODGE` 10, `DODGE_COMMIT` 0.6 s) gated by `awareness_eff` — smoke-blinded and panicked agents crash instead of swerving; **bump → stumble**; **aisle clear-width analysis** reusing `FlowField.wallDist` → WARN reason 4d, score-neutral by design; fire is an **editor-placeable hazard prop**. **No LLM per agent — ever.** Kill-switch: `A_DODGE = 0`. _(v3 cuts: obstacle memory, expressive emote layer beyond `?`/`!`, stall-triggered exit re-decision, water prop.)_
**Authoring (v3 inversion):** the **parametric editor is the primary path** — typed dimensions, steppers and tappable handles on the 0.25 m grid. Freehand drawing is a secondary tool, shipped only if everything else is done. One authoring path, not two; the accessibility hole is deleted rather than disclosed.
**Mascot:** RALLY (RP-25), 5 animation states, never colour-alone.
**AI:** three `@Generable` schemas, `joke` field on PASS only; model emits `MetricKey` enums, **never numerals**; V1–V8 validation gate → `CannedCoach`. **The fallback is a scored asset, not just a contingency — it is triggered deliberately on camera.**
**UI:** canvas ignores safe area and stays dark in Light Mode; **hue = meaning, shape = affordance**; 2-finger always pans / 3–40 pt per cell; scrubber = **live progress only** (replay-seek cut); `.sensoryFeedback` + 3 CoreHaptics patterns, 1 haptic per 0.5 s; accessibility canvas = single element with a spoken summary.
**Core journey (protect absolutely):** launch → open or shape a furnished venue → set the crowd → trigger the alarm → watch the evacuation → verdict + score + reasons with units → RALLY names a geometry fix → **Apply** → re-run → **visibly better score**. The final clause is the submission; "Apply & re-run" is promoted from Stretch to **Must** in v3.
**Build:** Dev A = engine, Dev B = app, parallel via `MockSimulation`. Dependency-ordered stages **S0–S5** with exit criteria (§6) — no calendar schedule.
**Evidence:** video-only. One unbroken take of the core journey; deliberate AI-fallback beat; states reel; audible VoiceOver; spoken limitations; timestamp index in the submission form (§E).
**Risk:** R-01 engine overrun · R-02 60 fps · R-03 AI availability (retire on day one) · R-09 physics wow · **R-19 evidence single-point-of-failure (new)**. R-15 **retired** — real-incident case studies cut.
**Cut / out of scope:** Monte Carlo · PDF report · Learn quiz and case studies · flood · replay-seek · Metal glow · audio bus graph · Liquid Glass pass · auto-minimising toolbar · reorderable grid · symbol effects · `.egress` export · widget/Siri · AI heatmap · isometric sandbox · RoomPlan · iPad/macOS/Pencil.

## TABLE OF CONTENTS

- [R. Rubric alignment — the scoring model that governs every trade](#r-rubric-alignment--the-scoring-model-that-governs-every-trade)
- [0. Phase 0 — Understand + Commit](#0-phase-0--understand--commit)
- [A. Architecture](#a-architecture)
- [Simulation Deep Spec (Reqs 1–4)](#simulation-deep-spec-reqs-14)
  - [§2.13 Obstacle interaction · NPC behavioural intelligence · expressive emotion](#213-obstacle-interaction--npc-behavioural-intelligence--expressive-emotion)
- [Verdict Engine + Mascot + Retro SFX (Reqs 5–6)](#verdict-engine--mascot--retro-sfx-reqs-56)
- [C. UI/UX — Layout · Colour · SF Symbols (Parts 1–3)](#c-uiux--layout--colour--sf-symbols-parts-13)
- [C. UI/UX — Gestures · Springs · Haptics/Audio + Accessibility (Parts 4–6)](#c-uiux--gestures--springs--hapticsaudio--accessibility-parts-46)
- [B. Build sequence — dependency-ordered stages S0–S5](#b-build-sequence--dependency-ordered-stages-s0s5)
- [D. Risk Register](#d-risk-register)
- [E. Evidence plan — video, submission form, finale](#e-evidence-plan--video-submission-form-finale)
- [F. Learning Notes · Discipline · Definition of Done](#f-swift-learning-notes--discipline--definition-of-done)
- [Appendix 1 — Applied patch log](#appendix-1--applied-patch-log)
- [Appendix 2 — Amendments to the Master Prompt](#appendix-2--amendments-to-the-master-prompt-requirement-blocks)
- [Appendix 3 — Verification register (resolve at S0)](#appendix-3--verification-register-resolve-at-s0)
- [Appendix 4 — v3 rubric revision log](#appendix-4--v3-rubric-revision-log)

---

# R. RUBRIC ALIGNMENT — THE SCORING MODEL THAT GOVERNS EVERY TRADE

## R.1 The 100 points

|  #  | Criterion                               | Points | What it actually rewards                                                                                                                     |
| :-: | --------------------------------------- | :----: | -------------------------------------------------------------------------------------------------------------------------------------------- |
| 01  | Problem and user value                  | **20** | A specific user, a concrete use case _shown through the working journey_, a credible outcome visible in the build                            |
| 02  | Working product and technical execution | **25** | End-to-end core journey; claims directly demonstrated; loading/empty/permission/offline/failure states; visible recovery; honest limitations |
| 03  | Apple-platform craft                    | **20** | A native capability that _materially improves the core journey_; correct conventions; honest handling of device and API limits               |
| 04  | Experience design and accessibility     | **15** | Clear navigation, labels, states, feedback; real assistive-technology support; alternatives to colour/motion/audio/gesture-only              |
| 05  | Originality and product judgment        | **10** | A recognisable point of view; **deliberate omissions that protect the core**; thoughtful execution                                           |
| 06  | Demonstration evidence                  | **10** | Judges can see the journey and outcome without guessing; functional vs mocked vs planned clearly separated                                   |

## R.2 Ratings are a six-position dial

Judges score **whole numbers 0–5**; points = rating ÷ 5 × criterion max.

| Rating | Anchor                                                                                |
| :----: | ------------------------------------------------------------------------------------- |
|   0    | No evidence — impossible to assess                                                    |
|   1    | Weak — primarily claimed, unclear, or substantially non-functional                    |
|   2    | Developing — credible partial work, important gaps remain                             |
|   3    | Solid — functional and convincing within ordinary hackathon limits                    |
| **4**  | **Strong — deliberate, well executed, clearly above expectations**                    |
|   5    | Exceptional — unusually coherent, convincing, memorable within its demonstrated scope |

**Six "Solid" 3s = 60/100.** That is exactly where a broad, competent, unfocused submission lands. The 3→4 step is defined as _deliberate and clearly above expectations_ — **breadth never moves that dial; concentration does.**

## R.3 Effort ranking is not proportional to points

The Grand Prize tie-break is explicitly ordered: **(1) working product and technical execution → (2) problem and user value → (3) Apple-platform craft → (4) recorded majority of the finale panel.** Those are the same three criteria that carry 65 of the 100 points, so they are weighted twice over.

**Ranking: 02 > 01 > 03 > 04 > 05 ≈ 06 — with one large exception.**

**Criterion 06 is a multiplier, not a 10-point line item.** With no TestFlight, the recording is the only channel through which criteria 01–04 reach a judge. An unverifiable claim does not score partial credit; the anchors read it as _Weak_. Evidence work must therefore be resourced as if criterion 06 were worth 25 points, because in practice it gates that much.

**Target profile:** 4–5 on criteria 01, 02, 03 and 06; 3–4 on 04 and 05 → roughly **82–90**. Chasing uniform 4s costs far more work and lands near 80.

## R.4 The exclusion list, quoted and binding

None of the following earns points. Each maps to something v2 planned to build:

| Exclusion                                                              | v2 item it kills                                                                |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Framework or feature count                                             | The §6.9 WWDC26 adoption table as a goal in itself                              |
| Decorative adoption of WWDC26 APIs                                     | Liquid Glass pass · auto-minimising toolbar · reorderable grid · symbol effects |
| AI features without product relevance                                  | (Egress is clean here — the coach is grounded in engine output)                 |
| Team size, expensive equipment, **or a paid developer account**        | Removes any regret about video-only                                             |
| App Store publication or RevenueCat integration                        | Confirms no publication path is needed                                          |
| Presentation polish unsupported by working evidence                    | Cinematic editing, PiP charisma, montage beats                                  |
| Unnecessary architectural complexity                                   | Snapshot ring buffer · Metal glow · audio bus graph · Monte Carlo `TaskGroup`   |
| Market-size claims without a convincing product                        | Any "the safety-consulting market is worth $X" line                             |
| **AI-generated code, copy, or written documentation volume by itself** | The elaborate README of v2 §E.5                                                 |

## R.5 The three-stage process, and what it implies

| Stage               | Who                                     | Evidence permitted                                                                                                                                             | Implication for Egress                                                                                                      |
| ------------------- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Preliminary**     | 2 judges, independent, async            | Deadline-locked form + video. Participants do not attend. A third reviewer is added when totals differ by ≥15 points **or any criterion differs by ≥2 levels** | Ambiguity costs twice: it lowers the score _and_ triggers re-review. The timestamp index (§E.4) exists to suppress variance |
| **Semifinals**      | 3 judges, async, **scores start fresh** | Same locked evidence. TestFlight inspected _when available_ — not available to us                                                                              | The video must survive five separate first-time viewings with no author present                                             |
| **Finale (22 Aug)** | 5 judges, live, **scores start fresh**  | 5-minute demo + 5 minutes of questions; judges may request a specific flow, **hands-on device access**, or verification of a claim                             | Requires the verification menu and a hands-on-safe build (§E.6)                                                             |

> **The single most important open question is in §E.7:** whether the finalist build may differ from the submitted build. The "no new build" rule is written under _Online semifinals_; the finale is twelve days after finalists are announced. The answer changes the scope decision below.

---

# 0. PHASE 0 — UNDERSTAND + COMMIT

## 0.1 Existing-work summary

1. **No repository or Swift code exists — greenfield.** Verified: uploads, working directory and all mounts contain zero `.swift` / `.xcodeproj` / `Package.swift`. Nothing to preserve.
2. Accumulated work is **planning only**: the Master Prompt v4 plus a set of **approved mockups** (retro-pixel × blueprint; "Metro Platform B" isometric sandbox with labelled dimensions; mascot card; game-style scenario cards). The spec is mature and internally consistent.
3. **Concept locked:** Egress — offline, on-device crowd-evacuation simulator; loop **Design → Simulate → Verdict**. (Pivoted from earlier rainwater-harvesting and AI-widget-generator concepts, both dropped.)
4. **Team / constraints (v3):** 2 developers, intermediate, new to Swift (learning Swift is an explicit goal); submission window closes **7 Aug 2026, 11:59 PM IST**. **Deliverable is a screen recording — not a live demo.** No paid Apple Developer account, therefore **no TestFlight**; TestFlight is recommended by the organisers but not required, and a paid account earns no points. **Source code is not submitted.** The Bengaluru finale on **22 Aug** is a separate live artifact, reached only by placing in the asynchronous rounds.
5. **Toolchain (✅ verified):** Xcode 27 beta ships **Swift 6.4** with the iOS/iPadOS/macOS/visionOS/tvOS **27** SDKs and **requires an Apple Silicon Mac on macOS Tahoe 26.4+**. Deployment target **iOS 26**; every iOS-27 API is availability-gated with a working iOS-26 path.
6. **What already works toward the primary journey: nothing (0% code).** The journey exists only on paper.
7. **What is missing (i.e. everything):** engine package, renderer, editor, verdict engine, mascot, AI layer, SFX, all UI. **Critical path = the deterministic engine**; nothing is demoable until it runs.
8. **Top-3 delivery risks** (expanded in §D):
   - **(a)** The AI showcase may not run on the demo device — on-device Foundation Models needs an Apple-Intelligence-capable iPhone; on older hardware the Pocket-Brain payoff degrades to canned text _in the actual demo_.
   - **(b)** Engine complexity versus Swift newcomers in a 17-day window — social force + flow field + hazards + 200–500 agents at 60 fps is hard, and could consume the whole timeline.
   - **(c)** 60 fps rendering of hundreds of sprites plus Metal shaders on-device is unproven for this team.
9. **Mitigation posture:** MoSCoW discipline (deterministic core + canned verdict is Must; AI / mascot / SFX are Should; RoomPlan / heatmap / widget are Stretch); engine-first vertical slice; performance spike and demo-device confirmation on days 1–2; fallback-first for every WWDC26 adoption; pin one known-good toolchain after Aug 3.
10. **Smaller version — PROMOTED TO THE PLAN IN v3.** iPhone-only · ~4 furnished presets · fire and smoke only · ~150 agents · **parametric authoring** · verdict with reasons in real units · RALLY with the on-device coach _and_ its canned fallback · **Apply & re-run**. That is a complete, honest, demonstrable Design → Simulate → Verdict → Fix → Improve loop. The organisers' own builder prompt states the governing principle: _prefer a narrow, complete vertical slice over a broad collection of unfinished features._ Criterion 02 penalises "large feature sets with an incomplete core journey"; criterion 05 rewards "deliberate omissions that protect the core experience". **Narrowing scope is not a concession here — it is directly scored.**

## 0.2 Track decision — **CONFIRMED**

| Track                                                                                    | Fit                                                                                                                                                   | Verdict                    |
| ---------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| **Pocket Brain** (on-device LLM must be _essential_)                                     | On-device Foundation Models powers the payoff: plain-language diagnosis, geometry-grounded fixes, cross-run memory and Learn quizzes — fully offline. | ✅ **Primary (confirmed)** |
| **Wellness Loop** (usefulness · safety · empathy · accessibility · responsible language) | Egress _is_ a safety and preparedness tool; the Learn tab, real case studies and accessibility rigour ride free. No medical claims.                   | ✅ **Overlay (confirmed)** |
| **MRR Machine** (believable paywall / subscription)                                      | A "Pro" tier is plausible but bolts monetisation onto a safety tool.                                                                                  | ⚪ Rejected                |
| **Voice Layer** (functional ElevenLabs use)                                              | ElevenLabs is a **cloud** service → breaks the 100%-offline promise and re-architects the audio layer.                                                | 🔴 Rejected                |

**Reconciliation (Section 4A).** The **deterministic core** (simulation + threshold verdict engine) always works and is the honest safety spine — the Must tier. The **intelligence layer** (natural-language diagnosis, grounded fixes, session memory, quizzes) is where the on-device model is _essential_ and is the track's showcase. On unsupported devices it degrades to templated text, disclosed as graceful degradation and never presented as the intended experience.

### 0.2.1 v3 — the Pocket Brain "essential" test, answered honestly

The track asks that local or on-device language modelling be **essential** to the product. Egress's safety spine is fully deterministic, and the canned fallback produces an identical card. Those two facts are in tension, and the tension is visible in our own video.

**Decision: stay on Pocket Brain, and argue it on user-facing grounds rather than architectural ones.** Track choice does not change the score — sponsored-track awards use the same 100-point assessment, and the Grand Prize is track-independent — so the only exposure is competing for the track pool against products where the model _is_ the product.

| Claim we make                                                                                     | Claim we do **not** make                          |
| ------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| A real venue's floor plan never leaves the device                                                 | "The model performs the safety analysis"          |
| It works in a basement, a construction site, or a venue with no signal                            | "The product does not function without the model" |
| No account, no per-run cost, no upload                                                            | "The model is required for the verdict"           |
| The model turns numbers into language a non-engineer can act on; the engine supplies every number | Any numeral originating from the model            |

Overclaiming essentiality would be caught by a judge watching our own deliberate fallback beat, and would discount the whole submission under criteria 02 and 06. Honest framing costs a little track fit and protects 35 points.

## 0.3 Assumptions & resolved questions

**Assumptions in force:**

- **A1** iPhone is the sole target; iPad adaptivity and Pencil authoring are **out of scope** (resolved by Q3).
- **A2** No LiDAR on the demo device → RoomPlan is **cut** (see PATCH-04).
- **A3** The demo runs in **airplane mode** to prove offline / on-device operation.
- **A4** **Zero third-party dependencies** — offline-first is a product virtue and a clean privacy story.
- **A5** Target **200 agents** for a guaranteed-smooth demo; higher counts are a tuning goal exposed as a config chip, clamped per PATCH-02.
- **A6** SwiftData is the in-app source of truth; `.egress` document sharing is Stretch.

**Blocking questions — answered:**

|   #    | Question           | Answer                                                                                                                                                                                           |
| :----: | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Q1** | Track confirmation | **Pocket Brain + Wellness Loop.** 100% offline, on-device Foundation Models, no cloud services.                                                                                                  |
| **Q2** | Exact demo device  | **iPhone 16** (A18 / 8 GB — supports Apple Intelligence locally, so the AI coach runs live rather than as a fallback). Base model ⇒ **no LiDAR, no ProMotion** ⇒ 60 fps target and RoomPlan out. |
| **Q3** | iPad scope         | **iPhone-only.** iPad and Apple Pencil authoring are completely out of scope; the full 17 days go to a flawless iPhone vertical slice.                                                           |

## 0.4 BUILD BRIEF

**Problem.** Professional crowd-evacuation analysis is locked inside expensive consultancy software; a small-venue operator or event organiser has no fast way to test whether a layout gets people out alive in an emergency.

**Target user.** Primary: a **small-venue operator / event organiser** without access to egress-modelling tools. Secondary (Learn / Wellness overlay): **students and the safety-curious public**.

**Primary outcome.** A clear, trustworthy **PASS / WARN / FAIL** verdict on a specific layout, with concrete **geometry-grounded fixes** that measurably improve clearance — computed **entirely on-device, offline**.

**End-to-end demo journey (launch → outcome).**
Launch → pick or draw a venue (demo: "Nightclub" preset or a quick touch-drawn room) → place exits and props on the 0.25 m grid → set the crowd (count / mix / alarm-delay chips) → **trigger the emergency** (shake or on-screen button) → watch a physically-grounded evacuation (density glow, fire, smoke, panic, herding) → **live bottleneck banner + haptic + sound** the moment a threshold is crossed → sim ends → **Safety Score + verdict + at-risk count + clearance time** → **RALLY coach card** with a grounded fix ("Widen Exit A to 1.2 m") → **apply & re-run** → **A/B** improved result → export **PDF**.
_Proof beat:_ airplane mode is on throughout — the coaching is on-device Foundation Models.

**Selected platform.** **iPhone only** — the sole target (the "in your pocket" positioning, the CoreMotion trigger, and the iPhone 16 demo device with on-device Apple Intelligence). iPad, Apple Pencil, macOS, visionOS, Watch and TV are all out of scope; no cross-platform faking. A macOS path is noted but not built. _(Applied: PATCH-P1a.)_

**Tech table.**

| Tech                                                                           | Purpose                                 | Availability risk                                                    | Fallback                                  |
| ------------------------------------------------------------------------------ | --------------------------------------- | -------------------------------------------------------------------- | ----------------------------------------- |
| Xcode 27 · Swift 6.4 · iOS 27 SDK · deploy iOS 26                              | build toolchain                         | ✅ confirmed; beta instability; needs Apple Silicon + macOS 26.4+    | pin a known-good build; iOS-26 code paths |
| SwiftUI + Observation + `TabView` / `NavigationStack`                          | all UI (iPhone-only)                    | ✅                                                                   | — _(Applied: PATCH-P1b.)_                 |
| `EgressEngine` Swift package · strict concurrency · Swift Testing              | pure sim engine, unit-tested            | ✅                                                                   | —                                         |
| `TimelineView(.animation)` + `Canvas`                                          | 60 fps sim rendering                    | ✅ core; perf at high agent counts 🔴                                | dot rendering; lower agent count          |
| Metal shader modifiers (`.colorEffect` / `.layerEffect` / `.distortionEffect`) | heat haze, smoke, density glow          | 🔴 verify symbols + perf                                             | plain SwiftUI fills and gradients         |
| Foundation Models on-device (`SystemLanguageModel`, `@Generable`)              | coach diagnosis, fixes, quizzes         | ✅ at iOS 26; needs an AI-capable device; 2nd-gen features iOS 27 🔴 | **canned / templated lines (Must tier)**  |
| SwiftData                                                                      | saved venues and runs (source of truth) | ✅                                                                   | —                                         |
| Swift Charts                                                                   | evacuation curves, density timelines    | ✅                                                                   | —                                         |
| PDFKit                                                                         | exportable safety report                | ✅                                                                   | share a score screenshot                  |
| CoreHaptics + `.sensoryFeedback`                                               | felt safety feedback                    | ✅                                                                   | sound + visual only                       |
| AVAudioEngine (all-original 8-bit SFX)                                         | retro sound system                      | ✅                                                                   | master toggle → silent                    |
| CoreMotion                                                                     | shake-to-trigger; gyro parallax         | ✅                                                                   | on-screen button; static camera           |
| App Intents + WidgetKit                                                        | "rerun my last drill" / widget          | 🔴 device & region                                                   | in-app only (Stretch)                     |
| **Third-party**                                                                | **none by default**                     | —                                                                    | offline-first is the story                |

_(Applied: PATCH-P1c — the PencilKit / PaperKit row was deleted; iPad authoring is out of scope. RoomPlan was subsequently cut entirely — see PATCH-04.)_

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

_Then Should:_ emotion polish, retro SFX, RALLY + AI coaching + jokes, A/B compare, Monte Carlo, PDF, Liquid Glass. _Then Stretch:_ AI heatmap debrief, apply-&-re-run, widget / Siri, `.egress` sharing.

**Out of scope.** App Store release; any backend, cloud or multiplayer; visionOS / Watch / TV; iPad, Pencil and macOS; live purchases; certified engineering claims; foldable layout; Private Cloud Compute and third-party model providers; ElevenLabs.

**Track-specific proof the demo must show.** _Pocket Brain:_ the on-device model produces the diagnosis, grounded fixes and cross-run memory ("clearance improved from 4:10 to 2:45 since you widened Exit A") with the device in airplane mode. _Wellness overlay:_ the Learn tab, a real case-study preset handled per §D.1, accessibility rigour, and responsible non-alarmist language.

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

| Unit               | Kind                                   | Imports                                                                                                             | Contains                                                                                                                                                 | Tested by                           |
| ------------------ | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| **`EgressEngine`** | Swift Package library (local, in-repo) | `Foundation`, `simd`                                                                                                | Deterministic sim core: standards, venue and agent models, flow field, hazards, spatial hash, integrator, metrics, Monte Carlo, event log, verdict rules | `EgressEngineTests` (Swift Testing) |
| **`Egress`**       | iOS app target (SwiftUI)               | SwiftUI, SwiftData, FoundationModels, AVFoundation, CoreHaptics, CoreMotion, PDFKit, Charts, TipKit, `EgressEngine` | UI (Spaces / Simulate / Learn), Canvas renderer, editor, persistence, AI coach seam, audio, haptics, design system                                       | light UI and preview tests only     |

**Why the package boundary:** it makes the "zero UI imports" guarantee _mechanical_ — the engine physically cannot import SwiftUI, so it stays pure, `Sendable`, testable in isolation, and is the honest safety spine that always works. Proportionate: **one** package, not a constellation. 🟡 A local package was chosen over a single-target folder for enforced isolation and fast headless tests; it is trivially collapsible if it fights the beta toolchain.

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

_(Applied: PATCH-01 — `Simulation` is no longer `@MainActor`; PATCH-02 added `maxValidatedAgents`.)_

## A.4 Data models (sub-types)

**Venue**

| Type        | Fields                                                                                                                                                 | Notes                                                                                                                                                            |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `VenueType` | enum: nightclub, gym, concertHall, office, metroPlatform, school                                                                                       | drives per-venue defaults (§2.9)                                                                                                                                 |
| `Wall`      | `cells: [GridCoord]`                                                                                                                                   | fully blocks movement and the flow field                                                                                                                         |
| `Exit`      | `id: UUID`, `cells: [GridCoord]` (doorway span), `clearWidth: Double` (m)                                                                              | `clearWidth` is the flow-rating input; labelled in the UI                                                                                                        |
| `Obstacle`  | `id`, `footprint: [GridCoord]`, `kind: PropKind` (stage / bar / turnstile / desk / rack / bench …), `blocksMovement = true`, **`isRelocatable: Bool`** | a **true obstacle** with a real footprint; `isRelocatable = false` for structural elements (columns, stages), which RALLY may never propose moving — see §2.13.3 |
| `DecorTile` | `cells`, `kind`                                                                                                                                        | **sim-inert**; visually distinct                                                                                                                                 |

**Agent**

| Type             | Fields / cases                                                                   | Notes                                                                                                                      |
| ---------------- | -------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `MobilityClass`  | adult, child, elderly, wheelchair, staff                                         | sets base speed range and body radius; wheelchair widens the footprint                                                     |
| `AgentTraits`    | `mobility`, `desiredSpeed` (m/s), `patience` 0–1, `awareness` 0–1, `herding` 0–1 | sampled at spawn from `CrowdMix` + `SafetyStandards`                                                                       |
| `EmotionalState` | calm → uneasy → panicked                                                         | transitions driven by local density, hazard proximity and alarm time (§2.6); panic raises desired speed → faster-is-slower |
| `AgentStatus`    | active, evacuated, injured, dead                                                 | injured / dead set by hazard contact; removed from the force calculation but retained as soft obstacles                    |

## A.5 Event-log schema (feeds the AI debrief)

```swift
public struct RunEvent: Sendable, Codable {
    let id: Int; let time: TimeInterval; let kind: RunEventKind
    let location: GridCoord?; let magnitude: Double?
    let agentID: Int?; let detail: String
}
```

| `RunEventKind`                 | Emitted when                                | Payload                                    |
| ------------------------------ | ------------------------------------------- | ------------------------------------------ |
| `alarmTriggered`               | t == alarmDelay                             | —                                          |
| `ignition`                     | hazard seeded                               | location                                   |
| `hazardSpread`                 | throttled (≤ 1 Hz)                          | location, magnitude = cells affected       |
| `exitBlocked`                  | a hazard reaches an exit cell               | location (exit id in detail)               |
| `flowFieldRecomputed`          | after a geometry or hazard change           | reason in detail                           |
| `densityThresholdCrossed`      | a cell crosses a Fruin band                 | location, magnitude = p·m⁻²                |
| `jamFormed`                    | at-risk density sustained ≥ N s in a region | location, magnitude = peak density         |
| `agentInjured` / `agentKilled` | hazard contact                              | agentID, location, magnitude = cause code  |
| `evacuationProgress`           | throttled (≤ 2 Hz)                          | magnitude = fraction out (feeds the curve) |
| `simEnded`                     | all out \| time cap \| casualty stop        | reason in detail                           |

**AI grounding rule.** The model never sees the raw per-frame stream. `RunEventLog.summary()` produces a **token-bounded structured digest** — counts by kind, worst jam {location, density, time}, casualties by hazard and location, clearance, per-exit throughput versus rating — and _that_ is the `@Generable` context. This bounds tokens and keeps every cited number engine-sourced.

## A.6 Verdict-rules table (structure; final values in §3.1)

Constants live in one place (`VerdictConstants` / `SafetyStandards`), are tunable, and are surfaced in the results UI.

| Constant                |           Value | Meaning                                                         |
| ----------------------- | --------------: | --------------------------------------------------------------- |
| `PASS_SCORE_MIN`        |              80 | at or above ⇒ PASS-eligible                                     |
| `FAIL_SCORE_MAX`        |              50 | below ⇒ FAIL regardless of casualties                           |
| `PEAK_DENSITY_WARN`     |       5.0 p·m⁻² | Fruin at-risk band                                              |
| `PEAK_DENSITY_FAIL`     |       7.0 p·m⁻² | crush / casualty band                                           |
| `AT_RISK_FRACTION_WARN` |            0.15 | fraction of agents above the at-risk band beyond the dwell time |
| `AT_RISK_DWELL`         |           3.0 s | dwell that counts as "at risk"                                  |
| `CLEARANCE_TARGET`      | per `VenueType` | from the per-venue defaults (§2.9)                              |
| `JAM_UNRESOLVED_AT_CAP` |     true ⇒ FAIL | agents still trapped at the time cap                            |

Full evaluation order, reason templates and live-escalation behaviour are in §3.3.

## A.7 Threading & concurrency (Swift 6 strict)

| Domain            | Runs on                                                                | Data crossing the boundary                                                                           |
| ----------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| UI + render loop  | `@MainActor` (`TimelineView(.animation)` → `Canvas`)                   | reads `SimulationSnapshot` (`Sendable`)                                                              |
| Sim step (v1)     | the **main actor's own `Simulation` instance**, called inside the tick | mutates that instance in place                                                                       |
| Monte Carlo batch | **off-main**, `TaskGroup`, one **private** `Simulation` per child task | takes `Sendable` `VenueModel` + `SimulationConfig` + seeds; returns `Sendable` `ClearancePrediction` |
| AI coaching       | `async`, app actor                                                     | `Sendable` digest in, `@Generable` out                                                               |

> **Isolation rule (PATCH-01).** `Simulation` is a plain reference type that is _not_ `Sendable` and must be used from exactly one execution context. The app creates and owns one instance **on the main actor**, so the render loop touches it without actor hops. Each Monte Carlo child task creates and owns its **own private instance** inside `withTaskGroup` and returns only `Sendable` values. **No `Simulation` instance is ever shared across contexts** — which is why no actor or lock is needed anywhere in the engine.

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

| Capability flag             | Source                                 | Gated feature                                | Default fallback (built first)          |
| --------------------------- | -------------------------------------- | -------------------------------------------- | --------------------------------------- |
| `supportsOnDeviceModel`     | `SystemLanguageModel.availability`     | AI coach diagnosis, fixes, quizzes           | `CannedCoach` templated lines           |
| `supportsMultimodalFM`      | `#available(iOS 27, *)` + availability | heatmap image in the coach prompt            | text-only digest                        |
| `supportsAgentTools`        | `#available(iOS 27, *)`                | one-tap apply-&-re-run authored by the model | deterministic engine-side edit + re-run |
| `supportsAppIntentsSurface` | `#available(iOS 27, *)`                | "rerun my last drill" / Spotlight            | in-app only                             |

> **Rule.** The fallback is the _default code path_; the enhanced path is layered behind the flag. Nothing iOS-27-only ever enters the Must tier.

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

Total acceleration for agent _i_ — mass and unit conversions are folded into the coefficients, so these are **tuning coefficients, not literal SI force constants**; calibrate empirically:

`a_i = a_drive + Σⱼ a_ped(i,j) + Σ_w a_wall(i)`, then `|a_i| ≤ A_MAX`

**Driving (goal) term**

```
a_drive = (v0_i · ê_i − v_i) / τ
  v0_i = desiredSpeed_i · emotionSpeedFactor_i   // base sampled speed, scaled by arousal (§2.6)
  ê_i  = herding-blended flow direction at the agent's cell (§2.4, §2.6)
         zero until the agent's reaction delay has elapsed
```

**Pedestrian repulsion** — neighbour _j_, `d = |xᵢ−xⱼ|`, `n = (xᵢ−xⱼ)/d`, `overlap = 2·bodyRadius − d`, tangent `t = (−n_y, n_x)`:

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

| Constant  |   Start | Effect / knob direction                               |
| --------- | ------: | ----------------------------------------------------- |
| `TAU` (τ) |   0.5 s | ↓ = snappier, more aggressive acceleration            |
| `A_PED`   |      12 | ↑ = larger personal space                             |
| `B_PED`   |  0.20 m | ↑ = begin avoiding from farther out                   |
| `A_WALL`  |       8 | ↑ = keep off walls more                               |
| `B_WALL`  |  0.20 m | —                                                     |
| `K_BODY`  |      60 | ↑ = firmer bodies (stiffer → watch stability)         |
| `K_FRIC`  |      40 | governs clogging and faster-is-slower magnitude       |
| `V_MAX`   | 2.5 m/s | hard cap above panic speed                            |
| `A_MAX`   |      20 | acceleration clamp for stability                      |
| `R_INT`   |   1.2 m | neighbour query cutoff (the exponential is ~0 beyond) |
| `H`       | 1/120 s | fixed physics step                                    |
| `DT_MAX`  |  1/30 s | frame-dt clamp                                        |

**Faster-is-slower / clogging** is _emergent_, not scripted: panic raises `v0`, agents push harder into a bottleneck, contact and friction rise, and flow stutters.
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

| Trait                          | Source                                                   | Range                                        |
| ------------------------------ | -------------------------------------------------------- | -------------------------------------------- |
| `mobility`                     | `CrowdMix` categorical                                   | adult / child / elderly / wheelchair / staff |
| `desiredSpeed`                 | `SafetyStandards.desiredSpeed(mobility)` mean ± variance | m/s (see the realism table, §2.11)           |
| `bodyRadius`                   | 0.22 m; wheelchair footprint wider (≈ 0.35 m effective)  | m                                            |
| `patience`                     | Beta-like sample                                         | 0–1                                          |
| `awareness`                    | sample; staff = 1.0                                      | 0–1                                          |
| `herding`                      | sample                                                   | 0–1                                          |
| `reactionDelay` (pre-movement) | lognormal-like, inversely tied to awareness              | 0 – ~15 s                                    |

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

| State        | s         | Speed factor                                 | Patience | Herding weight | Extra behaviours                                                                                      |
| ------------ | --------- | -------------------------------------------- | -------- | -------------- | ----------------------------------------------------------------------------------------------------- |
| **calm**     | < 0.33    | 1.0× base                                    | high     | low            | follows the flow field cleanly                                                                        |
| **uneasy**   | 0.33–0.66 | 0.9–1.0×                                     | medium   | medium         | brief **hesitation dwell** at decision cells (multiple similar-cost exits)                            |
| **panicked** | ≥ 0.66    | scales base → `panicSpeed` (1.8–2.2 sampled) | low      | high           | pushes into the crowd; small-probability **freeze**; follows the herd, possibly to the **wrong exit** |

**Herding blend:** `ê = normalize((1−λ)·ê_flow + λ·ê_neighbours)`, where `λ = herdWeight(state) · herding · (1 − awareness_eff)` and `ê_neighbours` is the normalised mean heading of neighbours within `R_INT`. High density + smoke + panic → `λ` rises → agents follow the pack, sometimes to a farther or wrong exit (the required herding failure mode).
**Freeze:** a rare per-tick chance when panicked and low-awareness sets the drive term to ≈ 0 briefly.
**Staff / guide:** `awareness = 1`, `λ = 0` (knows the exit), and lowers neighbours' `s_target` within `R_calm` by `CALM_STRENGTH` — a visible calming influence.

## 2.7 Hazards (Req 3) — physics the room reacts to

All hazards advance on a **15 Hz** clock, decoupled from `H`. All spread randomness uses `SeededRNG`.

**Fire — cellular automaton.** Flammable cells cycle `unburnt → igniting → burning → burnt`. Each hazard tick, every `burning` cell tries to ignite each flammable neighbour with `p = 1 − exp(−FIRE_SPREAD · Δt)` (orthogonal at full weight, diagonal × 0.7). `igniting → burning` after `IGNITION_DELAY`; `burning → burnt` after `BURN_DURATION`. Burning and igniting cells are **impassable** (marking the flow field dirty) and **harmful**.

**Smoke — diffusion field** in `[0,1]` per cell, deliberately **outrunning the flame**: burning cells add `SMOKE_PRODUCTION` per second, and each tick `smoke(c) += D · (mean(neighbours) − smoke(c)) − DECAY · smoke(c)`, clamped. Smoke **does not block** movement; it cuts `awareness_eff` (§2.6) → disorientation, wandering and stronger herding. Optional (Should) cumulative toxicity: `Σ smoke·Δt` past a threshold causes incapacitation.

**Flood — depth automaton.** A depth field (metres) fills from source cells at `FLOOD_FILL`, equalising into adjacent cells. Effects by depth: above `WADE_DEPTH` (0.3 m) the speed factor drops (wading); above `INCAP_DEPTH` (0.8 m) incapacitation follows. Deep cells are marked **high-cost** rather than impassable, so the flow field routes crowds around rising water → visible rerouting.

**Contact, casualties and classification.** An agent in a `burning` or `igniting` cell is injured immediately and dies after `FIRE_LETHAL_DELAY`; smoke toxicity injures (`.smoke`); sustained depth ≥ `INCAP_DEPTH` injures or kills (`.flood`); density ≥ 7 p/m² sustained for `CRUSH_DWELL` causes probabilistic injury (`.crush`). Casualties are recorded as `{hazard, location, time}` in the event log. Downed agents leave the drive loop but **remain as soft obstacles** — still contributing density and repulsion, because a fallen person worsens a jam, as in reality.

**Hazard constants (`SimConstants`, 🟡 tunable — time-compressed for a 1–4 minute demo; the ordering fire ≺ smoke is physically motivated, but this is an _educational_ model, not validated fire simulation):**

| Param               |   Start | Param                 |   Start |
| ------------------- | ------: | --------------------- | ------: |
| `FIRE_SPREAD`       | 0.35 /s | `SMOKE_PRODUCTION`    |  0.5 /s |
| `IGNITION_DELAY`    |   1.0 s | `SMOKE_DIFFUSION D`   |    0.25 |
| `BURN_DURATION`     |    20 s | `SMOKE_DECAY`         | 0.01 /s |
| `FIRE_LETHAL_DELAY` |   2.0 s | `SMOKE_AWARE_PENALTY` |     0.8 |
| `FLOOD_FILL`        | 0.4 m/s | `WADE_DEPTH`          |   0.3 m |
| `CRUSH_DWELL`       |   3.0 s | `INCAP_DEPTH`         |   0.8 m |

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

_Worked — Concert Crush:_ 3 casualties → C = 60; peak 6.5 → D = 22.6; risk 0.40 → R = 8.0; 210 s against a 180 s target → T = 2.5 ⇒ **7 → FAIL**.
_Worked — Office (good):_ 0 casualties; peak 2.2 → D = 1.9; risk 0.02 → R = 0.4; 120 s against 150 s → T = 0 ⇒ **98 → PASS**.

**Monte Carlo prediction (Should tier):** run 30 headless seeded sims varying spawn positions, traits, reaction delays and stochastic spread/freeze, with no rendering, stepped at `H` (or 1/60 for speed). Concurrency is bound to `activeProcessorCount` via `TaskGroup` and is cancellable; **each child task owns its own `Simulation` instance** (§A.7). Clearance times are collected and sorted into `ClearancePrediction { p10, median, p90 }`, shown as a predicted range. Deterministic per seed, therefore reproducible.

**Event emission throttles:** `hazardSpread` ≤ 1 Hz, `evacuationProgress` ≤ 2 Hz, `densityThresholdCrossed` debounced per region — so `RunEventLog.summary()` stays token-bounded for the AI digest.

## 2.9 Per-venue defaults 🟡

Occupant-load factors are code-derived approximations for the _preset_ footprint, and clearance targets are reasoned egress goals — **not** certified standards; the educational disclaimer applies. Default agent counts may intentionally exceed nominal comfort to stress-test a layout; users can lower them via the config chip.

**PATCH-02 applied:** every preset default is clamped to `maxValidatedAgents` (default **200**) at load.

| Venue          | Footprint          | Load factor | Capacity est. | Spec default | **Loaded default (clamped)** | Target clearance | Default mix a/c/e/wc/staff |
| -------------- | ------------------ | ----------: | ------------: | -----------: | ---------------------------: | ---------------: | -------------------------- |
| Nightclub      | 20 × 15 m (300 m²) |   0.65 m²/p |          ~460 |          200 |                      **200** |            120 s | .88/.00/.02/.02/.08        |
| Gym            | 25 × 20 (500)      |         4.6 |          ~108 |           90 |                       **90** |            120 s | .90/.00/.05/.02/.03        |
| Concert Hall   | 30 × 24 (720)      |        0.93 |          ~774 |          300 |                      **200** |            180 s | .85/.05/.03/.02/.05        |
| Office         | 24 × 18 (432)      |         9.3 |           ~46 |           80 |                       **80** |            150 s | .90/.00/.03/.03/.04        |
| Metro Platform | 60 × 6 (360)       |        0.50 |          ~720 |          250 |                      **200** |            240 s | .80/.05/.07/.03/.05        |
| School         | 30 × 20 (600)      |         1.9 |          ~315 |          180 |                      **180** |            180 s | .82/.10/.00/.02/.06        |

Raising the agent chip above `maxValidatedAgents` is permitted but shows a one-line HUD notice: _"Above the validated performance budget — frame rate may drop."_ **The demo never runs above `maxValidatedAgents`.**

## 2.10 Scenario presets (Req 3)

`Scenario { name, venue, hazards: [HazardSeed], alarmDelay, configOverrides, difficulty }`

| Scenario          | Venue          | Hazard (seed)                        | Alarm | Overrides (clamped per PATCH-02)   | Difficulty |
| ----------------- | -------------- | ------------------------------------ | ----- | ---------------------------------- | ---------- |
| Kitchen Fire      | Nightclub      | fire at a kitchen-corner cell        | 5 s   | 200 agents                         | ●●○        |
| Burst Pipe        | Metro Platform | flood at a wall source               | 3 s   | 250 → **200** agents               | ●●○        |
| Blocked Main Exit | Concert Hall   | main exit disabled at t₀ (no hazard) | 0 s   | 300 → **200** agents               | ●●●        |
| Concert Crush     | Concert Hall   | fire at stage-left + narrow exits    | 4 s   | 350 → **200** agents, panic bias ↑ | ●●●        |
| School Drill      | School         | none (orderly drill)                 | 0 s   | 180 agents, calm                   | ●○○        |

## 2.11 Constants files (consolidation)

- **`SafetyStandards.swift`** (citable — the coach quotes these verbatim with units): `cellSize 0.25 m`; `bodyRadius 0.22 m`; desired speeds adult **1.35**, child **0.9**, elderly **0.8**, wheelchair **0.7**, staff **1.4** m/s; `panicSpeed 1.8…2.2` m/s; `exitSpecificFlow 1.2` persons/s/m; density bands **< 1.8** comfortable, **2–4** congested, **≥ 5** at-risk, **≥ 7** crush; geometry minima interior door **≥ 0.9 m**, final exit **≥ 1.2 m**, assembly corridor **≥ 1.2 m** (recommend **2.4 m** at high occupancy).
- **`SimConstants.swift`** (internal knobs): the §2.2 force coefficients, `H`, `DT_MAX`, `R_INT`, `R_dens`, `τ_emotion`, arousal weights, `AT_RISK_DWELL`, the §2.7 hazard rates, the §2.8 score weights, `R_calm`, `CALM_STRENGTH`, `SMOKE_AWARE_PENALTY`.

## 2.12 Cross-cutting — WWDC26 / AI

The engine is pure Swift and simd, **iOS-26-safe with no iOS-27 dependency** — the entire Must-tier simulation runs regardless of Apple Intelligence availability. Two engine outputs are the AI's _only_ grounding: the smoothed **density grid** (optionally an iOS-27 multimodal heatmap, gated) and `RunEventLog.summary()` (the text digest). Monte Carlo uses Swift Concurrency `TaskGroup`, also iOS-26-safe. Nothing in this section enters the demo as an iOS-27-only path.

## 2.13 Obstacle interaction · NPC behavioural intelligence · expressive emotion

### 2.13.1 Scope check — what already existed, what this section adds

| Capability                                                                    | Status before this section                     |
| ----------------------------------------------------------------------------- | ---------------------------------------------- |
| Obstacles as real blocking footprints (`Obstacle`, `blocksMovement = true`)   | ✅ already specified (§A.4)                    |
| Themed props per venue — stage, bar, turnstiles, desks, racks, benches        | ✅ already specified                           |
| Decorative floor tiles that are sim-inert and visually distinct               | ✅ already specified                           |
| Wall and obstacle repulsion force via a distance field                        | ✅ already specified (§2.2, §2.4)              |
| Fire, smoke and flood hazards with rerouting                                  | ✅ already specified (§2.7)                    |
| Three-state emotion machine (calm → uneasy → panicked) driving physics        | ✅ already specified (§2.6)                    |
| Emote badges "?" and "!"                                                      | ✅ already specified                           |
| **Every venue furnished by default — no empty boxes**                         | 🆕 rule added below                            |
| **Anticipatory dodging — visible swerve before contact**                      | 🆕                                             |
| **Collision, stumble and obstacle memory**                                    | 🆕                                             |
| **Obstacle-derived aisle clear-width analysis**                               | 🆕 (nearly free — reuses `FlowField.wallDist`) |
| **Expressive reaction emotes — astonished, distressed, frustrated, relieved** | 🆕                                             |
| **Fire and water as editor-placeable hazard props**                           | 🆕 (nearly free — reuses `HazardSeed`)         |
| **Stall-triggered exit re-decision**                                          | 🆕 (Stretch)                                   |

### 2.13.2 What "intelligent NPC" means here — and what it does not

**It is not an LLM per agent.** Stating the arithmetic plainly, because this is the single most expensive wrong turn available: one on-device model call costs order _seconds_; the frame budget is 16.6 ms; there are 200 agents. That is roughly five orders of magnitude over budget, and it would additionally destroy the two properties the demo depends on — **determinism** (fixed seed, reproducible takes, §E.4) and **offline battery headroom**. It is off the table permanently, not deferred.

NPC intelligence in Egress is **deterministic behavioural intelligence** — four mechanisms that make agents _read_ as thinking beings:

| Mechanism                              | What it produces on screen                                                      | Where   |
| -------------------------------------- | ------------------------------------------------------------------------------- | ------- |
| **Anticipatory avoidance**             | agents swerve _early and decisively_ around a table rather than mushing into it | §2.13.4 |
| **Obstacle memory**                    | an agent that clips a bench gives it a wider berth next time                    | §2.13.5 |
| **Stall-triggered re-decision**        | an agent stuck in a non-moving queue reconsiders its exit                       | §2.13.8 |
| **Social influence** (already present) | herding, staff calming, wrong-exit following                                    | §2.6    |

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

| Venue          | Authored prop set                                     | Structural (non-relocatable) |
| -------------- | ----------------------------------------------------- | ---------------------------- |
| Nightclub      | bar run, stage block, standing tables, speaker stacks | stage block, bar run         |
| Gym            | rack rows, benches, treadmill bank                    | —                            |
| Concert Hall   | stage, seating blocks, crowd barriers, merch stand    | stage, seating blocks        |
| Office         | desk pods, meeting pod, printer bank, lockers         | —                            |
| Metro Platform | benches, kiosk, turnstile bank, **columns**           | columns, turnstile bank      |
| School         | desk rows, lockers, lab benches                       | lab benches                  |

> **Authoring constraint (load-bearing — see the G2 note in §2.13.7):** preset prop layouts must be authored so that every primary egress route clears the `SafetyStandards` minimum. The Office preset in particular must still produce **Score 98 / PASS**, because that is a G2 gate criterion.

### 2.13.4 Anticipatory dodging — the visible intelligence

The existing wall force is a _reactive_ term: it grows as an agent nears a surface, which reads as mush. Dodging adds a _predictive_ term, which reads as intent.

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

`awareness_eff` is the _same_ quantity that smoke degrades (§2.6). So a calm, clear-sighted agent dodges early; a panicked or smoke-blinded agent dodges late or not at all — **and therefore crashes**. Collisions are not scripted; they are what happens when perception fails. This also means clutter becomes measurably more dangerous as smoke spreads, which is both true and demoable.

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

**Sound:** `sfx_bump_soft` on the Agents bus, global maximum 2/s. **No haptic.** Haptics are reserved for events that concern the _analyst_ — thresholds, casualties, verdicts — not individual agent contacts. At 200 agents, per-bump haptics would be exactly the fatigue failure §5.5 exists to prevent.

**Trip-and-fall — deliberately off by default.** Falls under crowd pressure are a real cascade mechanism in crush incidents, but modelling them here would attribute _casualties_ to furniture on the basis of an unvalidated mechanism. `TRIP_FALL_ENABLED` therefore defaults to **false**, is exposed as a clearly-labelled experimental toggle in Settings, and when enabled is **excluded from the Safety Score and from the verdict**. It may be shown; it may not silently change a safety judgement.

### 2.13.6 Expressive emotion — a display layer, deliberately separate

**Two layers, and the separation is architectural, not cosmetic:**

| Layer                                               | Drives physics? | Status                                                                  |
| --------------------------------------------------- | :-------------: | ----------------------------------------------------------------------- |
| **Arousal spine** — calm / uneasy / panicked (§2.6) |     **yes**     | unchanged and untouched; already validated by the faster-is-slower test |
| **Reaction emotes** (new)                           |     **no**      | transient, display-only, cuttable without touching the engine           |

Keeping expression out of the physics means richer characters cannot destabilise a simulation whose behaviour is a gate criterion — and means the whole layer can be cut on a bad day at zero engine risk.

| Emote        | Glyph (shape, never colour-coded) | Trigger                                                                              | Duration |
| ------------ | --------------------------------- | ------------------------------------------------------------------------------------ | -------- |
| `astonished` | wide-eye "!"                      | first hazard sighting within `SIGHT_HAZARD`, gated by `awareness_eff`; or first bump | 1.2 s    |
| `confused`   | "?"                               | at a decision cell with two or more similar-cost routes; or on exit re-decision      | 1.0 s    |
| `frustrated` | steam puff                        | two or more bumps within 4 s, or a queue stalled ≥ 6 s                               | 1.0 s    |
| `distressed` | single teardrop                   | a casualty nearby, sustained ≥ 5 p/m² for ≥ 8 s, or trapped at the time cap          | 1.5 s    |
| `relieved`   | exhale                            | crossing an exit threshold                                                           | 0.8 s    |
| `resolute`   | steady chevron                    | staff only, on calming a neighbour                                                   | 1.0 s    |

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
2. **Constrictions.** Find local minima of aisle width along _traversed_ routes, weighted by cumulative agent path counts, so an unused corner never generates a false finding.
3. **Compare** against `SafetyStandards.geometryMinimums` — interior door ≥ 0.9 m, final exit ≥ 1.2 m, assembly corridor ≥ 1.2 m (recommend 2.4 m at high occupancy).
4. **Report** a new metric: `narrowestTraversedAisle` (metres) with its location and the obstacle pair responsible.

**Verdict integration — additive, and deliberately score-neutral.** A new WARN sub-reason **4d** joins §3.3:

> "The aisle between the bar and the standing tables is 0.7 m — below the 1.2 m assembly-corridor minimum."

**No new Safety Score term is added.** Adding one would change the §2.8 worked examples (Concert Crush = 7, Office = 98), which are G2 gate criteria — so clutter surfaces as a verdict reason and a coach fix, not as a score penalty. If playtesting later argues for a score term, it must be introduced _with_ new worked examples and a G2 criteria update, never silently.

**RALLY integration — zero schema change.** `FixTargetKind` already includes `.obstacle` (§3.5.2), so this slots straight into the existing fix vocabulary. `MetricKey` gains one case, `aisleClearWidth`. Only `isRelocatable` obstacles may be proposed for relocation; structural ones yield reroute advice.

> **G2 test note (load-bearing):** aisle analysis runs against furnished presets, so the six preset prop layouts must be authored to clear the minima on primary routes. A preset regression test asserts the §2.8 worked examples are unchanged — **Office must still be 98 / PASS**. Author the props first, then re-run the worked examples.

### 2.13.8 Fire and water as placeable hazard props

The editor palette gains a **Hazards** group, visually separated from Props and Decor to prevent accidental placement:

| Palette item    | Places                     | Config chip        | Symbol           |
| --------------- | -------------------------- | ------------------ | ---------------- |
| Ignition source | `HazardSeed(.fire, cell)`  | ignition delay (s) | `flame.fill` ✅  |
| Water source    | `HazardSeed(.flood, cell)` | fill rate (m/s)    | `water.waves` 🟡 |

**Zero new engine types:** editor placement writes into the venue's existing `Scenario.hazards: [HazardSeed]` (§2.10). Seeds are drawn with a warning-hatched footprint and are **inert until the alarm or their configured delay**, so the editor stays safe to browse and arrange.

**Reaction — how agents treat them:**

- Fire cells are impassable, so **the new dodge raycast already avoids flame fronts**: agents visibly swerve away from fire rather than discovering it on contact.
- Smoke degrades `awareness_eff`, which degrades dodging — so crowds get clumsier around furniture exactly as visibility drops.
- Flood cells are high-cost, so routes bend around rising water; above `WADE_DEPTH` agents wade and may show `distressed`.
- **Hazard flinch (new):** an agent within `FLINCH_RADIUS` of a _newly ignited_ cell receives an arousal spike, an `astonished` emote, and a brief away-vector impulse. This is the visible startle response that makes danger feel dangerous.

### 2.13.9 Stall-triggered exit re-decision (Stretch)

Today the flow field routes everyone to the globally cheapest exit. Per-agent re-decision requires **one flow field per exit** (typically 2–4 fields over ≤ 5 k cells — memory is trivial, compute is a multiple of an already sub-millisecond pass).

An agent whose progress-toward-exit falls below `STALL_THRESHOLD` for `STALL_TIME` re-evaluates: high-awareness agents switch to a cheaper alternative exit and emit `confused`; low-awareness agents herd instead (existing behaviour). This is the most expensive item in this section and the least necessary for the demo, so it stays **Stretch** and is the first of this batch to be cut.

### 2.13.10 New constants (`SimConstants`, 🟡 all tunable starting values)

| Constant                         |          Start | Governs                                           |
| -------------------------------- | -------------: | ------------------------------------------------- |
| `T_LOOK`                         |          0.8 s | lookahead time for the dodge raycast              |
| `L_MIN` / `L_MAX`                |    0.5 / 2.5 m | lookahead distance clamp                          |
| `A_DODGE`                        |             10 | dodge steering strength (before awareness gating) |
| `DODGE_COMMIT`                   |          0.6 s | side-commitment window — prevents oscillation     |
| `RAY_STRIDE`                     |     4 substeps | dodge evaluation cadence (~30 Hz)                 |
| `BUMP_OVERLAP`                   |         0.06 m | penetration that counts as a collision            |
| `BUMP_TANGENT_RETAIN`            |            0.5 | tangential velocity kept on bump (scrape)         |
| `BUMP_AROUSAL`                   |           0.15 | arousal spike per bump                            |
| `BUMP_COOLDOWN`                  |          1.0 s | per-agent anti-spam                               |
| `STUMBLE_RANGE`                  |      0.4–0.8 s | stumble duration sample                           |
| `STUMBLE_SPEED_FACTOR`           |           0.35 | speed multiplier while stumbling                  |
| `MEMORY_DECAY`                   |          6.0 s | obstacle-memory decay                             |
| `SIGHT_HAZARD`                   |          4.0 m | hazard sighting radius for `astonished`           |
| `FLINCH_RADIUS`                  |          2.0 m | hazard-flinch radius                              |
| `EMOTE_CONCURRENT`               |             12 | on-screen emote budget                            |
| `EMOTE_COOLDOWN`                 |          2.5 s | per-agent emote cooldown                          |
| `STALL_THRESHOLD` / `STALL_TIME` | 0.15 m/s · 6 s | exit re-decision trigger (Stretch)                |
| `TRIP_FALL_ENABLED`              |      **false** | experimental; excluded from score and verdict     |

### 2.13.11 Tests (added to the engine suite)

| Test                  | Asserts                                                                                                                       |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Dodge — clear sight   | at `awareness = 1.0`, an agent with an obstacle dead ahead deviates **before contact**; zero bumps registered                 |
| Dodge — blinded       | at `awareness = 0.1`, the identical fixture **does** register a bump — proving the awareness coupling is live, not decorative |
| No tunnelling         | across 10 k substeps at panic speed, no agent ever ends a substep inside an impassable cell                                   |
| Bump cooldown         | an agent pinned against an obstacle registers ≤ 1 bump per second                                                             |
| Dodge stability       | no side-oscillation: an agent changes committed side at most once per `DODGE_COMMIT` window                                   |
| Aisle measurement     | a fixture with an authored 0.7 m gap reports `narrowestTraversedAisle` = 0.70 ± 0.02 m                                        |
| **Preset regression** | all six furnished presets reproduce their §2.8 worked examples — **Office = 98 / PASS**, Concert Crush = 7 / FAIL             |
| Determinism preserved | identical seed → identical bump count, stumble timings and clearance                                                          |

### 2.13.12 Tiering and the honest cost — **RE-TIERED IN v3**

| Item                                   | v2 tier  | **v3 tier** | Est. cost     | Rubric justification                                                                                                                    |
| -------------------------------------- | :------: | :---------: | ------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Furnished presets + `isRelocatable`    |   Must   |  **Must**   | ~0.5 day (B)  | An empty box is not a room; cheap credibility for criterion 01                                                                          |
| Anticipatory dodge + commitment        | Should ★ |  **Must**   | ~0.6 day (A)  | The strongest "important technical claim, directly demonstrated" available (criterion 02) and the clearest point of view (criterion 05) |
| Bump + stumble on contact              | Should ★ |  **Must**   | ~0.35 day (A) | The visible consequence of failed perception — it is what makes the dodge legible                                                       |
| Aisle clear-width analysis + reason 4d | Should ★ |  **Must**   | ~0.4 day (A)  | Reuses `wallDist`; converts geometry into advice, which is the criterion 01 payoff                                                      |
| Hazard flinch                          |  Should  | **Should**  | ~0.2 day (A)  | Folds into hazard work                                                                                                                  |
| Editor hazard palette (fire only)      |  Should  | **Should**  | ~0.2 day (B)  | Reuses `HazardSeed`; water prop cut with flood                                                                                          |
| Obstacle memory                        | Should ★ | ⛔ **CUT**  | —             | Invisible at demo timescale; pays for the dodge                                                                                         |
| Expressive emote layer (6 glyphs)      |  Should  | ⛔ **CUT**  | —             | Display-only, zero rubric surface. `?` and `!` remain                                                                                   |
| Stall-triggered exit re-decision       | Stretch  | ⛔ **CUT**  | —             | Per-exit fields for a beat no judge will isolate                                                                                        |

**Revised total ≈ 1.55 dev-days (A) + 0.7 dev-days (B)** — down from 2.2 + 1.3.

> **What funds it in v3: Monte Carlo, the ring buffer, and the emote layer, all deleted outright rather than deferred.** Monte Carlo yields a predicted-range chip. This batch yields a crowd that visibly thinks, dodges and collides — the difference between "dots drifting" (risk R-09) and a room full of people. Criterion 02 asks whether important technical claims are _directly demonstrated_; a range chip demonstrates nothing you can watch.

**The kill-switch, unchanged:** if dodging destabilises the crowd (risk R-17), set `A_DODGE = 0`. Agents fall back to pure flow-field routing plus the existing wall force. One constant, zero code, no regression.

---

# VERDICT ENGINE + MASCOT + RETRO SFX (Reqs 5–6)

## 3.1 Verdict constants — final values

`VerdictConstants.swift` — one file, tunable, surfaced in the UI.

| Constant                |                                                                         Value | Source / rationale                                                                                    |
| ----------------------- | ----------------------------------------------------------------------------: | ----------------------------------------------------------------------------------------------------- |
| `PASS_SCORE_MIN`        |                                                                            80 | at or above ⇒ PASS-eligible                                                                           |
| `FAIL_SCORE_MAX`        |                                                                            50 | below ⇒ FAIL (catches casualty-free catastrophes)                                                     |
| `PEAK_DENSITY_WARN`     |                                                                      5.0 p/m² | `SafetyStandards` Fruin at-risk band ✅                                                               |
| `PEAK_DENSITY_FAIL`     |                                                                      7.0 p/m² | crush band ✅ (also drives crush casualties, §2.7)                                                    |
| `AT_RISK_FRACTION_WARN` |                                                                          0.15 | 🟡 15% of occupants held at risk indicates a layout problem                                           |
| `AT_RISK_DWELL`         |                                                                         3.0 s | 🟡 dwell that counts as "at risk"                                                                     |
| `CLEARANCE_TARGET`      |         club 120 · gym 120 · hall 180 · office 150 · metro 240 · school 180 s | §2.9 🟡                                                                                               |
| `SIM_TIME_CAP`          | `clamp(3 × CLEARANCE_TARGET, 300, 600)` s → 360 / 360 / 540 / 450 / 600 / 540 | a run must terminate for a demo                                                                       |
| `TRAPPED_FAIL_COUNT`    |                                                                             1 | **any** occupant unevacuated at the cap ⇒ FAIL — in a safety product, one trapped person is a failure |
| `ESCALATION_COOLDOWN`   |                                                                         6.0 s | anti-spam for the live banner, haptic and sound                                                       |
| `ESCALATION_REARM`      |                                                         10.0 s below the band | before the same band can fire again                                                                   |

## 3.2 ⚠️ Score-versus-threshold coherence (resolved design decision)

The two systems **can disagree in a narrow band**, and that must be handled deliberately rather than discovered during the demo.

_Worked:_ peak density of exactly 5.0 p/m², zero casualties, otherwise clean → `D = ((5.0 − 1.8)/5.2) × 25 = 15.4` → **Score 85** (PASS band) — yet rule 4 fires **WARNING**. The disagreement window is peak density **5.0 – 6.0 p/m²** on an otherwise-clean run. At 6.0, `D = 20.2` → score 80, and above that the score falls into the WARN band on its own.

**Resolution — three rules:**

1. **The rules table is the safety authority; the Safety Score is a communication device.** The verdict level is _never_ derived from the score alone. This is documented in-app under "How scoring works."
2. **UI rule:** whenever `verdict.level` disagrees with the score's band, the results card and RALLY both **lead with the violated threshold**, not the number — "Peak density 5.4 p/m² at Exit A (caution band ≥ 5.0)" — with the score shown as secondary. This prevents the "Score 85 but WARNING?" confusion.
3. Not "fixed" by re-weighting: forcing agreement would require a `D` weight of at least 32.5, distorting the casualty and time balance. A narrow, explainable disagreement beats a contorted formula. 🟡 Tunable if playtesting says otherwise.

**Why rules 1 and 2 both exist:** rule 1 (casualties > 0) catches every casualty run — one casualty already costs 25 points and two hit the 50-point cap. Rule 2 is reachable only casualty-free: the maximum non-casualty penalty is `25 + 20 + 15 = 60` → score 40 (for example, mass entrapment at 7 p/m² over the target time). Both are live.

## 3.3 Verdict evaluation & reason templates

```swift
Verdict { level, score, reasons: [VerdictReason], firstEscalationTime, timeline: [EscalationEvent] }
VerdictReason { metricKey, thresholdValue, actualValue, unit, locationLabel, template }
```

Every reason renders **metric + threshold + value + units**. First match wins:

| #   | Condition                                             |  Level   | Rendered reason                                                                                          |
| --- | ----------------------------------------------------- | :------: | -------------------------------------------------------------------------------------------------------- |
| 1   | `casualties > 0`                                      | **FAIL** | "3 casualties at Exit A (fire)"                                                                          |
| 2   | `score < 50`                                          | **FAIL** | "Safety Score 41 below floor of 50"                                                                      |
| 3   | `activeAgents ≥ 1` at `SIM_TIME_CAP`                  | **FAIL** | "7 occupants unable to reach an exit within 360 s"                                                       |
| 4a  | `peakDensity ≥ 5.0`                                   | **WARN** | "Peak density 6.8 p/m² at the north corridor (caution ≥ 5.0 p/m²)"                                       |
| 4b  | `atRiskFraction ≥ 0.15`                               | **WARN** | "31% of occupants held above 5.0 p/m² for over 3 s"                                                      |
| 4c  | `clearance > CLEARANCE_TARGET`                        | **WARN** | "Clearance 168 s exceeds the 120 s target for a nightclub"                                               |
| 4d  | `narrowestTraversedAisle < geometryMinimum` (§2.13.7) | **WARN** | "The aisle between the bar and the standing tables is 0.7 m — below the 1.2 m assembly-corridor minimum" |
| 5   | `50 ≤ score < 80`                                     | **WARN** | "Safety Score 72 in the caution band"                                                                    |
| 6   | else                                                  | **PASS** | "Cleared in 94 s · peak 2.2 p/m² · zero casualties"                                                      |

All applicable WARN sub-reasons are collected so the card can list them; the **level** is decided by the first match.

**Live in-sim escalation** (`EscalationEvent`) — the same predicates evaluated per frame against live metrics:

| Trigger                     | Banner                      | Haptic                  | Sound              |
| --------------------------- | --------------------------- | ----------------------- | ------------------ |
| density ≥ 4.0 (approaching) | "CONGESTION BUILDING" amber | `.warning` light        | `sfx_sting_soft`   |
| density ≥ 5.0 (at risk)     | "BOTTLENECK DETECTED" amber | `.warning`              | `sfx_sting_warn`   |
| density ≥ 7.0 (crush)       | "CRUSH RISK" red            | `.error` + custom curve | `sfx_sting_crit`   |
| exit blocked by a hazard    | "EXIT B BLOCKED" red        | `.error`                | `sfx_exit_blocked` |
| first casualty              | "CASUALTY" red              | heavy impact            | `sfx_thud`         |

Each band fires **once per run** (first crossing), with `ESCALATION_COOLDOWN` (6 s) between any two escalations and re-arming after 10 s below the band. All escalations are appended to `RunEventLog` and drawn as timeline-scrubber markers.

## 3.4 Mascot character sheet — **RALLY**

**Name:** RALLY · **Unit designation:** RP-25 (_Rally Point, 0.25 m grid_) · **Role:** safety coach, not an authority.
Deliberately _not_ named "Marshal" or "Inspector" — the app gives educational analysis, not certified engineering advice, and the mascot must never imply certification.

**Silhouette (all original, no copyrighted characters):** a 16 × 16 px source rendered at 3–4× (48–64 pt). A chunky rounded-square head with a **single wide visor** (readable at dot scale, where two eyes would mush), a stubby antenna with a bulb, a boxy torso with a 3-pip chest grid, short arms, and a **hover base instead of legs** — which halves the animation work and makes the idle bob free. Palette of at most 6 colours drawn from the design tokens.

| State       | Frames | fps | Trigger                 | Pose / tells                                                                      |
| ----------- | :----: | :-: | ----------------------- | --------------------------------------------------------------------------------- |
| `idle`      |   2    |  4  | default on the card     | gentle hover bob; antenna bulb pulses slowly                                      |
| `talk`      |   4    |  8  | while text streams      | visor waveform animates; antenna blinks per syllable; synced to `sfx_mascot_blip` |
| `concerned` |   3    |  4  | WARN                    | leans forward, antenna droops, visor narrows, one arm raised pointing             |
| `alert`     |   2    |  6  | FAIL / crush escalation | rigid posture, antenna bulb strobes (**Reduce Motion → static**)                  |
| `celebrate` |   4    | 10  | PASS                    | arms up, hover bounce, 6 pixel-confetti sprites                                   |

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

The model returns **metric _keys_, not values**; the app substitutes the engine's real number at render time. The model therefore _cannot_ invent a metric.

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

**Prompt contract:** the system prompt supplies the `RunEventLog.summary()` digest, an explicit **list of valid element IDs**, and the `SafetyStandards` minima, and states: _use only the supplied element IDs; never write digits in prose; cite a metric by key._

### 3.5.3 Validation gate (`Validation.swift`) — every check must pass or we fall back

| #   | Check                                                                                                                                                                                                                                                                                                          | Failure action                                   |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| V1  | Session returned non-empty, well-formed, non-refusal output                                                                                                                                                                                                                                                    | → Canned                                         |
| V2  | Every `elementID` exists in `VenueModel` (exit / obstacle / wall ID set)                                                                                                                                                                                                                                       | → Canned                                         |
| V3  | `citedMetric` is materially relevant (e.g. `exitFlowRate` only if that exit's measured flow is below its rating)                                                                                                                                                                                               | drop that fix; if fewer than 1 survives → Canned |
| V4  | **Numeral scan:** regex `\d` over `diagnosis` / `encouragement` / `instruction`; any digit not matching a whitelisted engine value within tolerance (0.05 m / 0.1 p·m⁻² / 1 s)                                                                                                                                 | → Canned                                         |
| V5  | **Geometry feasibility:** `proposedMetres` ≥ the `SafetyStandards` minimum for that element type (door 0.9 / exit 1.2 / corridor 1.2) **and** it physically fits the venue bounds without colliding with a fixed wall **and**, for a relocation fix, the target obstacle has `isRelocatable == true` (§2.13.3) | drop that fix                                    |
| V6  | Fix count after drops is 2–3                                                                                                                                                                                                                                                                                   | pad from the canned list, or → Canned            |
| V7  | Latency budget of 4.0 s (streaming shown meanwhile)                                                                                                                                                                                                                                                            | timeout → Canned                                 |
| V8  | PASS only: `joke` is present and contains no casualty or injury vocabulary (small blocklist)                                                                                                                                                                                                                   | drop the joke, keep the summary                  |

**Rendering:** the UI composes final strings by interpolating the engine's real value for `citedMetric` into the model's number-free prose — so what the user reads is _model phrasing plus engine arithmetic_. Every card offers **regenerate**, **dismiss**, and **"show the numbers behind this"** (which opens the metric with its threshold and source).

### 3.5.4 Canned fallback lines (Must tier — used on any validation failure or unsupported device)

Deterministic templates with engine-filled slots; the app is fully coherent with **zero** AI.

| Verdict            | Headline                | Body template                                                                                                                                                                                                       | Fix chips                                        |
| ------------------ | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| PASS               | "EVACUATION SUCCESSFUL" | "Everyone cleared in {clearance} s, peak density {peak} p/m². Below the {target} s target."                                                                                                                         | "Save layout" · "Try a harder scenario"          |
| WARN (density)     | "BOTTLENECK DETECTED"   | "Peak density reached {peak} p/m² at {location} — above the {5.0} p/m² caution band."                                                                                                                               | "Widen {element} to {min+0.6} m" · "Add an exit" |
| WARN (clearance)   | "TOO SLOW"              | "Clearance {clearance} s exceeded the {target} s target for this venue type."                                                                                                                                       | "Widen main exit" · "Add an exit"                |
| WARN (at risk)     | "CROWD UNDER PRESSURE"  | "{pct}% of occupants spent over {dwell} s above {5.0} p/m²."                                                                                                                                                        | "Widen {element}" · "Relocate obstacles"         |
| FAIL (casualties)  | "EVACUATION FAILED"     | "{n} casualties at {location} ({hazard})."                                                                                                                                                                          | "Add exit near {location}" · "Clear the route"   |
| FAIL (trapped)     | "OCCUPANTS TRAPPED"     | "{n} occupants could not reach an exit within {cap} s."                                                                                                                                                             | "Add a second exit" · "Remove blocking obstacle" |
| Device unsupported | —                       | Silent degradation: cards still appear, sourced from this table. A single one-time note in Settings explains that on-device coaching is unavailable on this device. **Never** presented as the intended experience. | —                                                |

### 3.5.5 Cross-run memory & gated extras (fallback-first)

- **Session memory (Should):** the last `RunRecord` for the same venue is included in the digest → "Clearance improved from 4:10 to 2:45 since you widened Exit A." The _comparison arithmetic is done by the engine_; the model only phrases it. Fallback: stateless per-run coaching.
- **Multimodal heatmap (Stretch, `supportsMultimodalFM`):** attach the density-grid snapshot image so the diagnosis can reason about _where_. Fallback: the text-only digest, which is the default path.
- **Agent tools / apply-&-re-run (Stretch, `supportsAgentTools`):** `readRunMetrics()` and `proposeGeometryFix(edit:)` drive one-tap apply. Fallback: the chip performs a **deterministic, engine-side** edit and re-runs — so "apply & re-run" still works without any agent API; only the _authoring_ of the edit is AI-assisted.

## 3.6 Retro pixel sound system (Req 6) — **REDUCED IN v3**

> **⚠️ v3 scope cut.** The `AVAudioEngine` five-bus graph, ducking, and the full cue library are **cut**. Ship **three cues only** — alarm klaxon, threshold-crossing sting, verdict fanfare — played through simple players on an `.ambient` session that respects the silent switch. Audio carries no rubric weight of its own, and criterion 04 only requires that **no safety event is signalled by audio alone** (the escalation banner and haptic already satisfy that). The bus architecture below is retained as reference for the finale window, not built for the 7 August submission.

**Session:** `AVAudioSession` category `.ambient` with `.mixWithOthers` — the **silent switch is respected** and the user's own music is never interrupted. No background-audio mode.

**Graph:** `AVAudioEngine` → 5 sub-mixers → main mixer. All assets are **all-original 8-bit-style** (square, triangle and noise oscillators rendered offline to short 22.05 kHz mono WAVs; no copyrighted audio). Runtime synthesis is used only for RALLY's voice.

| Bus          |  Priority   |     Voices     | Contents                                                                           |
| ------------ | :---------: | :------------: | ---------------------------------------------------------------------------------- |
| **Mascot**   | 1 (highest) |       1        | RALLY blip speech                                                                  |
| **Alerts**   |      2      |       3        | klaxon, stings, verdict fanfares, casualty thud                                    |
| **Hazard**   |      3      |       2        | fire crackle loop, water rush loop (panned)                                        |
| **Agents**   |      4      |       6        | emotion chirps                                                                     |
| **Ambience** |      5      |       1        | crowd murmur bed                                                                   |
| **Budget**   |      —      | **≤ 24 total** | 13 allocated plus headroom; the oldest lowest-priority voice is stolen on overflow |

**Vocabulary**

| Cue                                  | Character                                            | Bus      | Trigger                                   | Cooldown / behaviour                                                                                            |
| ------------------------------------ | ---------------------------------------------------- | -------- | ----------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `amb_murmur`                         | filtered noise plus a low square bed, looped         | Ambience | always after spawn                        | **volume ∝ mean density** (0.15 → 0.6); **pitch +0 … +3 semitones** with mean arousal — the room audibly tenses |
| `sfx_chirp_confused`                 | 2-note rising blip "?"                               | Agents   | agent → `uneasy`                          | 0.4 s per agent; **global max 3/s**; on-screen agents only                                                      |
| `sfx_chirp_panic`                    | short descending squeak                              | Agents   | agent → `panicked`                        | 0.6 s per agent; global max 2/s                                                                                 |
| `fire_crackle`                       | noise-burst loop                                     | Hazard   | any burning cell                          | **panned L/R by hazard x** relative to the viewport; gain ∝ burning-cell count                                  |
| `water_rush`                         | filtered noise sweep loop                            | Hazard   | flood active                              | panned; gain ∝ flooded area                                                                                     |
| `sfx_klaxon`                         | 2-tone square alarm, 3 repetitions                   | Alerts   | alarm trigger                             | once per run; ducks everything by 10 dB                                                                         |
| `sfx_sting_soft` / `_warn` / `_crit` | 2 / 3 / 4-note descending stings                     | Alerts   | escalation bands (§3.3)                   | one per band per run, 6 s cooldown                                                                              |
| `sfx_exit_blocked`                   | dull clang                                           | Alerts   | exit consumed by a hazard                 | once per exit                                                                                                   |
| `sfx_thud`                           | **muffled** low thud — deliberately soft, never gory | Alerts   | casualty                                  | max 1/s; volume capped                                                                                          |
| `sfx_fanfare_pass`                   | ascending 5-note arpeggio                            | Alerts   | PASS verdict                              | once                                                                                                            |
| `sfx_motif_fail`                     | descending 4-note minor motif                        | Alerts   | FAIL verdict                              | once; low, sombre, never comedic                                                                                |
| `sfx_mascot_blip`                    | Animalese-**style** per-character blip               | Mascot   | RALLY talking                             | 1 blip per 33 ms, whitespace skipped, ±2 semitone jitter per character                                          |
| `sfx_ui_confirm`                     | two-note rising square blip                          | Alerts   | export / save complete                    | max 1 per 2 s _(Applied: PATCH-P5a.)_                                                                           |
| `sfx_bump_soft`                      | short muted knock                                    | Agents   | agent collides with an obstacle (§2.13.5) | global max 2/s; **no haptic** — agent contacts concern the crowd, not the analyst                               |
| UI taps                              | soft square clicks                                   | Alerts   | tool select, chip tap                     | 0.05 s                                                                                                          |

**Ducking controller** — priority-ordered gain ramps, 0.08 s attack and 0.25 s release:
_Mascot speaking_ → Alerts −6 dB, Hazard −8, Agents −10, Ambience −12 · _Alert playing_ → Hazard −4, Agents −8, Ambience −8 · _Klaxon_ → all others −10. Never a full mute — the room keeps breathing under the coach.

**Controls & accessibility**

- A **master sound toggle** plus independent sub-toggles (Ambience / Agents / Alerts / Mascot voice) in Settings, persisted.
- **Reduce Motion** does not mute audio (they are orthogonal); a separate **"Reduce Audio Intensity"** halves agent-chirp rates, disables the pitch rise on the murmur bed, and caps stings at −6 dB. RALLY's `alert` strobe is disabled by Reduce Motion.
- **Never audio-alone:** every cue has a visual twin — escalations draw timeline markers and banners, casualties place timeline pins, and RALLY's speech is on-screen text. This _is_ the caption strategy: the timeline scrubber doubles as a readable event log, and a plain-text **run transcript** is exportable with the PDF report.

## 3.7 Cross-cutting — WWDC26 / AI

Everything in §3.6 and the §3.5.4 canned table is **iOS-26-safe with zero AI dependency** — the Must-tier verdict experience (thresholds, the RALLY sprite, escalations, the full SFX vocabulary) demos identically on a device with no Apple Intelligence. Foundation Models enters only at §3.5.2–3.5.3 (Should), and the two iOS-27-only enhancements are gated behind `DeviceCapabilities` flags whose fallbacks are the default code path. On the iPhone 16 demo device the on-device model **runs live in airplane mode** — that is the Pocket-Brain proof beat.

---

# C. UI/UX — LAYOUT · COLOUR · SF SYMBOLS (Parts 1–3)

## 4.1 IA reconciliation — explicit mapping

The mockups' **Scenarios · Create · Profile** bar collapses into **Spaces · Simulate · Learn**. Rationale: the tab bar should mirror the core loop (Design → Simulate → Verdict) plus the Wellness overlay, not the object types.

| Mock element                                                                 | Destination                          | Form                                                                                                               |
| ---------------------------------------------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| **Scenarios** tab (scenario cards, difficulty chip, capacity, personal best) | **Spaces**                           | the "System Presets" section of the Workspace Project Library                                                      |
| **Create** tab (new venue)                                                   | **Spaces**                           | toolbar `+` → pushes the **Editor** (a screen, not a tab — you always create _into_ the library)                   |
| **Profile** tab (personal bests, history)                                    | **Spaces** (per card) + **Settings** | score-history sparkline and "Modified 2h ago" on each card; an account-less Settings sheet from the Spaces toolbar |
| —                                                                            | **Simulate**                         | run screen: HUD, canvas, timeline scrubber, RALLY, results                                                         |
| —                                                                            | **Learn**                            | quizzes, preparedness tips, case studies (the Wellness-Loop overlay)                                               |

**Simulate-with-no-context problem (a real design decision):** the tab can be tapped with nothing selected. Resolution — Simulate has three states: **(a)** resume the last run's results if one exists this session; **(b)** show the last-used venue, ready to arm; **(c)** first-launch empty state — a dimmed blueprint grid, "No space loaded", and a primary button to Spaces. Never a blank screen, and never a modal picker on tab tap.

## 4.2 Navigation architecture & screen inventory

`TabView` with 3 tabs; each tab owns an independent `NavigationStack` with its own `path`, so state is preserved when switching. **Maximum 2 push levels per tab** — hackathon discipline; deeper hierarchy is a smell.

| Screen            | Tab      | Presentation                  | Title style                    | Notes                                                                                               |
| ----------------- | -------- | ----------------------------- | ------------------------------ | --------------------------------------------------------------------------------------------------- |
| Workspace Library | Spaces   | root                          | `.large` "Spaces"              | sectioned grid: System Presets / Custom Templates; searchable; drag-reorder (Should)                |
| Space Detail      | Spaces   | push                          | `.inline` (venue name)         | thumbnail, sparkline, capacity, Edit / Simulate / Duplicate / Export                                |
| **Editor**        | Spaces   | push                          | `.inline`, editable venue name | tool sheet; dimension overlay; scale caption "1 Pixel Block = 0.25 m × 0.25 m"                      |
| Pre-run Config    | Simulate | `.sheet` `.medium`            | inline                         | quick-config chips: agent count · crowd mix · alarm delay · scenario                                |
| **Sim Canvas**    | Simulate | root                          | **hidden**                     | a custom Liquid Glass HUD replaces the nav bar entirely                                             |
| Results           | Simulate | `.sheet` `.medium` → `.large` | inline "Results"               | score ring, verdict reasons, charts, A/B, PDF export                                                |
| Learn Home        | Learn    | root                          | `.large` "Learn"               | quiz card, tips, case-study list                                                                    |
| Case Study        | Learn    | push                          | `.inline`                      | narrative plus "Play this scenario" → loads the preset                                              |
| Settings          | any      | `.sheet` `.large`             | inline                         | audio toggles, reduce-audio-intensity, units, "How scoring works", disclaimer, AI-availability note |

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

_(Applied: PATCH-P5b — the scrubber annotation now states its two modes.)_

**Density chips** float over hotspots, clamped to stay at least 12 pt inside the canvas free zone, and never overlap the HUD, the RALLY card or the scrubber. The **Editor** replaces the playback row with the tool sheet (§4.5) and keeps the same HUD slot for the scale caption and dimension toggle.

## 4.4 Dynamic Type strategy

> **Principle: chrome scales, the map does not.** The sim canvas is a metric drawing at 0.25 m per cell — scaling it with text would break spatial truth. Agent sprites, the grid and dimension geometry are fixed to the world scale; only _labels_ on the canvas scale, and those are capped.

| Region                                      | Range                               | Behaviour at accessibility sizes                                                                                                    |
| ------------------------------------------- | ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Results, verdict reasons, RALLY text, Learn | **full** `.xSmall … AX5` (uncapped) | this is the reading surface — never truncated; the card grows and the sheet expands to `.large`                                     |
| HUD numerics                                | capped at `.xxLarge`                | above the cap the HUD collapses to a **single summary line** (`t+42.7s · 200 · 6.8 p/m²`); full stats move to a tap-to-expand sheet |
| Canvas dimension labels                     | capped at `.large`                  | above the cap labels hide and the overlay switches to tap-to-reveal callouts                                                        |
| Tool chips / tab bar                        | system default                      | `ViewThatFits`: a 2-column chip row becomes stacked full-width rows                                                                 |
| Buttons                                     | full                                | minimum 44 × 44 pt touch target at every size                                                                                       |

A `ScrollView` wraps any content that can exceed one screen at AX5. The verdict headline uses `.minimumScaleFactor(0.8)` with `.lineLimit(2)` rather than truncating.

## 4.5 Bottom sheets & detents

| Sheet                        | Detents                   | Background interaction                                         | Dismiss                                          | Corner |
| ---------------------------- | ------------------------- | -------------------------------------------------------------- | ------------------------------------------------ | ------ |
| **Editor tools**             | `.height(140)`, `.medium` | **`.enabled`** — you must draw while it is open (load-bearing) | drag down to a `.height(56)` handle, never fully | 28     |
| Pre-run config               | `.medium`                 | disabled                                                       | interactive ✅                                   | 28     |
| **Results**                  | `.medium` → `.large`      | disabled                                                       | interactive ✅ (results persist in `RunRecord`)  | 28     |
| RALLY expanded               | `.medium`                 | `.enabled` (the sim keeps running)                             | interactive ✅                                   | 26     |
| Settings / How scoring works | `.large`                  | disabled                                                       | interactive ✅                                   | 28     |

All use `.presentationDetents`, `.presentationDragIndicator(.visible)`, `.presentationCornerRadius(28)`, and a Liquid Glass background (iOS 26 material; fallback `.ultraThinMaterial` plus `surface.glassTint`).

## 4.6 RALLY card placement — non-blocking rules

| Rule                   | Spec                                                                                                                                                                                                |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Placement              | the canvas half **opposite** the triggering hotspot (a peak-density cell in the top half puts the card in the bottom half); horizontally centred, 16 pt side insets, maximum width 361 pt           |
| Never occludes         | the hotspot cell plus a 44 pt halo, the HUD bar, the timeline scrubber, the tab bar                                                                                                                 |
| Instances              | **maximum 1**; a new event replaces the content with a `talk` transition — cards never stack                                                                                                        |
| Blocking               | never modal; the sim continues; no dimming scrim                                                                                                                                                    |
| Interaction            | tap → expand sheet (full diagnosis · show the numbers · regenerate) · swipe → dismiss · `×` → dismiss                                                                                               |
| Auto-dismiss           | 12 s for in-sim events; **never** for the final verdict card                                                                                                                                        |
| Z-order (bottom → top) | canvas → density glow → hazards → agents → dimension overlay → density chips → **RALLY card** → HUD / scrubber → escalation banner → sheets                                                         |
| Reduce Motion          | entrance bounce becomes a cross-fade; the `alert` strobe becomes static                                                                                                                             |
| **Reachability**       | if the card lands in the hard-reach zone (more than 520 pt from the bottom), a 44 pt "RALLY" pill appears in the natural thumb zone and re-opens the card as a bottom sheet _(Applied: PATCH-P5c.)_ |

## 4.7 Corner smoothing & radius scale

Apple squircles everywhere: `RoundedRectangle(cornerRadius:_, style: .continuous)`. 🔴 Verify iOS 26's `ConcentricRectangle` / `.rect(corner:)` in Xcode 27; `.continuous` is the fallback and ships first.

| Token          | Radius | Applied to                         |
| -------------- | -----: | ---------------------------------- |
| `radius.xs`    |      8 | chips, density pills, tool buttons |
| `radius.sm`    |     12 | inline fields, sparkline tiles     |
| `radius.md`    |     16 | HUD bar, timeline container        |
| `radius.lg`    |     20 | library cards                      |
| `radius.xl`    |     26 | RALLY card                         |
| `radius.sheet` |     28 | all sheets                         |

**Concentric rule:** a nested radius equals the outer radius minus the padding (e.g. 26 card − 10 pad = 16 inner), so corners stay optically parallel.

## 4.8 Semantic colour tokens & dark mode

**Two decisions stated up front.**

**(1) The sim canvas stays dark in Light Mode.** Density glow, fire, smoke and aura legibility all depend on a dark ground; inverting it would destroy the hazard semantics. Chrome (sheets, library, Learn, Settings) adapts fully to Light Mode; the canvas and its HUD are permanently dark. This is a deliberate, disclosed exception, not a missing feature.

**(2) Green conflict resolved — hue carries meaning, shape carries affordance.** The visual identity wants neon data-green for scores, sparklines and primary actions, while the UX rules reserve green / amber / red for density, hazard and verdict semantics. Resolution: **one** green token (`accent.dataGreen` = `verdict.pass`), used only where the meaning is genuinely "safe / improving / correct". Primary actions are distinguished from status by **shape** — a filled glass capsule, 44 pt, elevated — never by inventing a second green. Consequence: destructive and neutral actions are _never_ green (Delete uses `verdict.fail` red; Cancel uses `text.secondary` plain). No green appears decoratively anywhere.

**Token table** — contrast ratios computed against `canvas.base` (#0A0E14); 🟡 verify in Accessibility Inspector.

| Token                        | Hex (dark)                | Light mode     |         Ratio | Use                                                                                   |
| ---------------------------- | ------------------------- | -------------- | ------------: | ------------------------------------------------------------------------------------- |
| `canvas.base`                | `#0A0E14`                 | **unchanged**  |             — | blueprint ground                                                                      |
| `canvas.grid`                | `#1B2430`                 | unchanged      |             — | faint dot grid (0.25 m)                                                               |
| `canvas.gridMajor`           | `#26323F`                 | unchanged      |             — | every 4 cells = 1.0 m                                                                 |
| `surface.glass`              | material + `#131A24` @72% | light material |             — | Liquid Glass chrome                                                                   |
| `surface.raised`             | `#161E2A`                 | `#F5F7FA`      |             — | cards, sheets                                                                         |
| `separator`                  | `#2A3644`                 | `#D8DEE6`      |             — | hairlines                                                                             |
| `text.primary`               | `#E8EEF5`                 | `#0E1620`      | **16.6:1** ✅ | headlines, metrics                                                                    |
| `text.secondary`             | `#9AA9BA`                 | `#4A5766`      |  **8.1:1** ✅ | labels, captions                                                                      |
| `text.tertiary`              | `#74849A`                 | `#6B7889`      |  **5.1:1** ✅ | metadata ("Modified 2h ago")                                                          |
| `accent.dataGreen`           | `#34E27A`                 | `#0F9D52`      | **11.4:1** ✅ | scores, sparklines, primary actions, PASS                                             |
| `accent.cyan`                | `#4FD8FF`                 | `#0A7EA4`      | **11.6:1** ✅ | **dimension lines and measurement callouts only — never semantic**                    |
| `density.comfortable` (<1.8) | `#1E5C46` @25%            | unchanged      |             — | glow band                                                                             |
| `density.congested` (2–4)    | `#C98A2E` @45%            | unchanged      |             — | glow band                                                                             |
| `density.atRisk` (≥5)        | `#E8632B` @65%            | unchanged      |             — | glow band                                                                             |
| `density.crush` (≥7)         | `#FF2D4B` @85%            | unchanged      |             — | glow band                                                                             |
| `hazard.fire` / `fireCore`   | `#FF6B1A` / `#FFD24A`     | unchanged      |             — | flame sprite                                                                          |
| `hazard.smoke`               | `#8B95A3` @variable       | unchanged      |             — | smoke veil                                                                            |
| `hazard.flood`               | `#1E63D6`                 | unchanged      |             — | **deepened** so water never reads as a dimension line                                 |
| `verdict.pass`               | `#34E27A`                 | `#0F9D52`      |     11.4:1 ✅ | PASS badge, RALLY visor                                                               |
| `verdict.warn`               | `#F5B93B`                 | `#9A6B00`      | **10.9:1** ✅ | WARN badge, escalation banner                                                         |
| `verdict.fail`               | `#FF3B5C`                 | `#C2001E`      |  **5.6:1** ✅ | FAIL badge, casualty markers                                                          |
| `agent.calm`                 | `#B8C6D6`                 | unchanged      |             — | dot / sprite tint                                                                     |
| `agent.uneasy`               | `#F5B93B`                 | unchanged      |             — | shares the caution ramp **deliberately**                                              |
| `agent.panicked`             | `#FF3B5C`                 | unchanged      |             — | shares the danger ramp deliberately                                                   |
| `agent.staff`                | `#7B5CFF`                 | unchanged      |             — | violet — **outside every semantic ramp**, so staff read as "special", not "dangerous" |
| `rally.body`                 | `#C7D3E0`                 | unchanged      |             — | mascot chassis; visor and antenna tint use the verdict token                          |

**Colour-blind safety (palette level; full pass in §5.6):** the four density bands have **monotonically increasing luminance and saturation** — in greyscale or under deuteranopia, _brighter always means worse_. Redundancy: pattern fill (dot → hatch → cross-hatch → solid), the numeric chip ("6.8 p/m²"), and the banner text. **No state anywhere is signalled by hue alone.**

## 4.9 SF Symbols vocabulary (Part 3)

The deployment target is iOS 26, so SF Symbols 6-era names are available; **the risk is string accuracy, not availability**. Tags: ✅ confident · 🟡 verify spelling · 🔴 likely renamed, use the fallback first. Verify all in the SF Symbols 7 app bundled with Xcode 27. Every symbol ships with an `.accessibilityLabel`; **no icon-only control for a destructive or state-critical action.**

**Editor**

| Action                   | Symbol                                         | Mode / weight         | Tag |
| ------------------------ | ---------------------------------------------- | --------------------- | :-: |
| Draw wall                | `pencil.and.ruler`                             | hierarchical · medium | ✅  |
| Place exit               | `door.left.hand.open`                          | hierarchical · medium | ✅  |
| Freehand draw            | `hand.draw`                                    | monochrome · regular  | ✅  |
| Place prop / obstacle    | `cube.fill` (fallback `square.fill`)           | hierarchical          | 🟡  |
| Decor (sim-inert) tile   | `paintbrush.fill`                              | monochrome            | ✅  |
| Erase                    | `eraser.fill`                                  | monochrome            | ✅  |
| Dimension overlay toggle | `ruler.fill`                                   | palette (cyan / off)  | ✅  |
| Grid snap toggle         | `square.grid.3x3.fill`                         | monochrome            | ✅  |
| Undo / Redo              | `arrow.uturn.backward` / `arrow.uturn.forward` | monochrome            | ✅  |

_(`cube.transparent` — the isometric sandbox toggle — was removed: the isometric view is cut, see PATCH-03.)_

**Simulate / HUD**

| Action               | Symbol                                      | Mode            |     Tag      |
| -------------------- | ------------------------------------------- | --------------- | :----------: |
| Play / Pause / Stop  | `play.fill` · `pause.fill` · `stop.fill`    | mono · semibold |      ✅      |
| Restart run          | `arrow.counterclockwise`                    | mono            |      ✅      |
| Step back / forward  | `gobackward` · `goforward`                  | mono            |      ✅      |
| Agent count          | `person.3.fill`                             | hierarchical    |      ✅      |
| Elapsed time         | `timer`                                     | mono            |      ✅      |
| Density readout      | `gauge.medium` (fallback `gauge`)           | hierarchical    |      🔴      |
| Alarm trigger        | `bell.fill`                                 | palette (amber) |      ✅      |
| Fire / Smoke / Flood | `flame.fill` · `smoke.fill` · `water.waves` | palette         | ✅ / ✅ / 🟡 |
| Event log / scrubber | `waveform`                                  | mono            |      ✅      |
| Frame-rate pill      | _(text only, no symbol)_                    | —               |      —       |

**Verdict & state**

| State              | Symbol                                          | Mode                    |                Tag                 |
| ------------------ | ----------------------------------------------- | ----------------------- | :--------------------------------: |
| PASS badge         | `checkmark.seal.fill`                           | palette (green / white) |                 ✅                 |
| WARN badge         | `exclamationmark.triangle.fill`                 | palette (amber / dark)  |                 ✅                 |
| FAIL badge         | `xmark.octagon.fill`                            | palette (red / white)   |                 ✅                 |
| Casualty marker    | `cross.case.fill`                               | mono                    |                 🟡                 |
| Blocked exit       | `door.left.hand.closed`                         | hierarchical            |                 🟡                 |
| At-risk occupants  | `figure.stand` / `figure.roll` / `figure.child` | mono                    |            ✅ / 🟡 / 🟡            |
| AI coaching active | `sparkles`                                      | mono                    | ✅ (avoid `apple.intelligence` 🔴) |

**Spaces / Learn / Settings**

| Action                              | Symbol                                                                        | Tag |
| ----------------------------------- | ----------------------------------------------------------------------------- | :-: |
| New space                           | `plus` (toolbar) / `plus.circle.fill` (empty state)                           | ✅  |
| Search · Duplicate · Delete · Share | `magnifyingglass` · `plus.square.on.square` · `trash` · `square.and.arrow.up` | ✅  |
| PDF report                          | `doc.richtext`                                                                | ✅  |
| Charts / A-B compare                | `chart.xyaxis.line` · `arrow.left.arrow.right`                                | ✅  |
| Quiz · Tips · Case studies          | `graduationcap.fill` · `lightbulb.fill` · `books.vertical.fill`               | ✅  |
| Sound on/off · Settings             | `speaker.wave.2.fill` / `speaker.slash.fill` · `gearshape.fill`               | ✅  |

**Rendering modes and motion.** Default to **hierarchical** (single-tint depth, matching the blueprint aesthetic). Use **palette** wherever a symbol carries semantic state (verdict badges, hazard toggles, the dimension toggle), so the meaningful layer takes the semantic token and the chassis stays neutral. **Multicolour is never used** — it would import Apple's palette and break the reserved-hue rule. Weights: HUD numerics `.semibold`, toolbar `.regular`, empty-state hero glyphs `.light` at 48 pt.

**Variable colour — honest scope:** true `variableValue` only works on symbols authored with sequential layers (`speaker.wave.3.fill`, `cellularbars`). It is used for the **audio-level indicator** only. For live warning escalation — where variable colour would be the obvious choice — the symbol set has no genuine variable-layer equivalent, so we substitute **`.symbolEffect(.pulse)`** on `exclamationmark.triangle.fill`, escalating to `.bounce` at crush level, plus a palette tint change. Same communicative goal, real API. All symbol effects respect **Reduce Motion** (static plus tint change only).

## 4.10 Cross-cutting — WWDC26 / AI

| Adoption                                               | Use here                                                            |   Tier    | Fallback (ships first)                        |
| ------------------------------------------------------ | ------------------------------------------------------------------- | :-------: | --------------------------------------------- |
| Liquid Glass (iOS 26 automatic; iOS 27 refresh free)   | HUD bar, sheets, RALLY card, tab bar                                |  Should   | `.ultraThinMaterial` plus `surface.glassTint` |
| Toolbar visibility priority / auto-minimising toolbars | the sim HUD minimises during playback and restores on interaction   |  Should   | a manual show/hide chevron on the HUD bar     |
| Reorderable grid plus swipe actions on any view        | drag-reorder Custom Templates; swipe to Duplicate / Export / Delete |  Should   | static ordering plus `List` swipe actions     |
| `ConcentricRectangle` / `.rect(corner:)`               | corner concentricity                                                | 🔴 verify | `RoundedRectangle(style: .continuous)`        |
| Foundation Models                                      | RALLY card text only — **no layout depends on it**                  |  Should   | the canned table, §3.5.4                      |

> **AI layout invariant.** The RALLY card's geometry, placement rules and dismissal behaviour are identical whether the text came from the on-device model or the canned table. If Foundation Models is unavailable the user sees _different words_, never a different or degraded interface.

---

# C. UI/UX — GESTURES · SPRINGS · HAPTICS/AUDIO + ACCESSIBILITY (Parts 4–6)

## 5.1 Gesture conflict resolution (the load-bearing decision)

One canvas serves drawing, panning and zooming — the classic conflict. **Resolution: tool-modality on one finger, invariants on two.**

| Fingers           | Editor, tool armed                                                                                                | Editor, Inspect mode | Sim canvas      |
| ----------------- | ----------------------------------------------------------------------------------------------------------------- | -------------------- | --------------- |
| **1-finger drag** | **draws** (wall run / exit span)                                                                                  | pans                 | pans the camera |
| **2-finger drag** | **pans** (always — never draws)                                                                                   | pans                 | pans            |
| **Pinch**         | zooms (always)                                                                                                    | zooms                | zooms           |
| **Double-tap**    | zoom to fit the venue                                                                                             | zoom to fit          | zoom to fit     |
| **Rotation**      | **rejected** — the blueprint is axis-aligned; rotation conflicts with pinch and breaks dimension-label legibility | —                    | —               |

Two-finger pan is the invariant escape hatch, so the user is never trapped in a tool. `SimultaneousGesture` composes pinch with two-finger pan; the one-finger `DragGesture` carries `minimumDistance: 4` to keep taps clean. Tool arming is always visible — the armed chip fills with `accent.dataGreen` and the HUD shows the tool name — so modality is never invisible.

**Zoom clamp:** 0.5×–4×, additionally clamped so that one 0.25 m cell renders between **3 and 40 pt**. Below 3 pt the grid aliases and dimension labels become unreadable; above 40 pt the venue loses context. Zoom-to-fit computes the scale that fits `venue.bounds` plus a 24 pt margin.

## 5.2 Gesture inventory

**Editor**

| Gesture                        | Target                      | Result                                                                                      |
| ------------------------------ | --------------------------- | ------------------------------------------------------------------------------------------- |
| Tap                            | palette item                | **arms** the tool (the primary placement model — reliable at 393 pt and VoiceOver-operable) |
| Tap                            | canvas cell (armed)         | places a prop or decor tile at the snapped cell                                             |
| Drag                           | canvas (wall or exit armed) | draws a run; a live length label in cyan, snapped to 0.25 m                                 |
| **Drag from palette → canvas** | prop                        | drag-to-place (**Should** — an enhancement over tap-to-arm, never the only path)            |
| Tap                            | element (Inspect)           | selects; shows the dimension callout and clear-width label                                  |
| Long-press                     | element                     | context menu: Edit width · Duplicate · Lock · **Delete** (destructive, red, confirmed)      |
| Long-press                     | empty canvas                | context menu: Paste · Zoom to fit · Toggle dimensions                                       |
| Drag                           | selected element handle     | resize; snaps to 0.25 m; the live cyan dimension updates                                    |

**Simulate**

| Gesture                    | Result                                                                                                                                                             |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Tap density chip           | expands to metric detail (value · band · threshold · location)                                                                                                     |
| **Shake** (CoreMotion)     | triggers the alarm — a tactile "start the emergency"; **the on-screen `bell.fill` button is always present** as the fallback and the accessible path, never hidden |
| Tap RALLY card             | expands to a `.medium` sheet (full diagnosis · show the numbers · regenerate)                                                                                      |
| Swipe RALLY card           | dismiss (any direction; 44 pt threshold)                                                                                                                           |
| Drag scrubber              | see §5.3 — behaviour differs live versus post-run                                                                                                                  |
| Long-press scrubber marker | jumps to that event and shows its tooltip                                                                                                                          |

**Spaces**

| Gesture         | Result                                                                    |
| --------------- | ------------------------------------------------------------------------- |
| Swipe leading   | Duplicate                                                                 |
| Swipe trailing  | Export · **Delete** (confirmation dialog; never a single-swipe destroy)   |
| Long-press card | context menu plus drag-reorder (Should)                                   |
| Pull-to-refresh | **rejected** — there is no network and no remote state; it would be a lie |

## 5.3 Timeline scrubber — **LIVE PROGRESS ONLY (v3)**

A running physics simulation cannot be scrubbed backwards: state is produced forward by integration. v2 solved this with a post-run replay mode backed by a 16 MB snapshot ring buffer.

> **⛔ v3 cut: replay-seek and the snapshot ring buffer are deleted.** That is real engineering — packed `2 × Int16` positions at 10 Hz, decimation on overflow, a parallel byte lane for emotion and hazard state — spent on an affordance that a re-run reproduces for free, on a deterministic seeded engine where every run is identical anyway. Criterion 02 explicitly gives nothing for "unnecessary infrastructure".

**What ships:** a single-mode progress bar with event markers at ignition, jam formation, casualties and threshold crossings. No thumb; dragging does not seek; markers are tappable for a tooltip. Elapsed time in mono, trailing. Renders 20 pt tall inside a 44 pt hit area.

**Scrub haptics:** a `.selection` tick only when a marker is crossed, never per frame.

## 5.4 Spring physics — motion tokens

One `Motion` enum; no ad-hoc animation values anywhere in the codebase.

| Token              | `spring(response:dampingFraction:)` | Applied to                          | Character                                          |
| ------------------ | ----------------------------------- | ----------------------------------- | -------------------------------------------------- |
| `motion.tap`       | `0.25, 0.85`                        | button and chip press, tool arm     | snappy, no overshoot                               |
| `motion.chip`      | `0.30, 0.80`                        | config chips, density chip expand   | slight life                                        |
| `motion.sheet`     | `0.45, 0.85`                        | tool, results and settings sheets   | system-like                                        |
| `motion.banner`    | `0.35, 0.75`                        | escalation banner in and out        | urgent but not jarring                             |
| `motion.card`      | `0.50, 0.60`                        | **RALLY entrance bounce**           | visible overshoot — the mascot has personality     |
| `motion.emote`     | `0.28, 0.55`                        | agent emote badge pop-in ("?", "!") | tiny playful overshoot, scale 0.6 → 1.0            |
| `motion.dismiss`   | `0.30, 1.00`                        | any exit transition                 | critically damped — nothing bounces on the way out |
| `motion.toolSheet` | `0.40, 0.85`                        | tool sheet detent change            | —                                                  |

**Score-ring reveal (results):** not a spring — a **1.2 s** `.easeOut` sweep from 0 to the score with a synchronised count-up numeral, then `motion.card` on the verdict badge. Haptics: light ticks at **at most 8 evenly-spaced points regardless of score** (an 8-tick ceiling, not one per point), then a single `.success` / `.warning` / custom-fail on completion.

**RALLY talk loop:** a frame cycle at 8 fps driven by `TimelineView(.periodic)`, _not_ a spring; it runs only while text streams and stops on the last character. The entrance is `motion.card` plus a 12 pt upward offset and opacity.

**Scene-phase transitions**

| Phase              | Action                                                                                                                                                                       |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.inactive`        | **pause the sim immediately** (no dt accumulation), duck audio to −18 dB, freeze haptics                                                                                     |
| `.background`      | stop `AVAudioEngine`, stop `CHHapticEngine`, persist the in-progress `RunRecord`, **cancel the Monte Carlo `TaskGroup`**                                                     |
| `.active` (return) | **stay paused** with a "Paused — tap to resume" overlay (never auto-resume a run the user is not watching); restart the audio session and haptic engine before the first cue |

> **Engine restart discipline ✅.** `CHHapticEngine` stops on backgrounding — wire `stoppedHandler` and `resetHandler` to `try? engine.start()`, and lazily restart before any pattern plays. Do the same for `AVAudioEngine` plus session reactivation. This is a top source of "haptics and audio silently died after a phone call" bugs in demos.

**Adaptive degradation**

| Condition                                | Response                                                                          |
| ---------------------------------------- | --------------------------------------------------------------------------------- |
| `ProcessInfo.isLowPowerModeEnabled`      | target 30 fps, disable the Metal glow shader, halve the agent-chirp rate          |
| `ProcessInfo.thermalState ≥ .serious`    | disable shader effects, show a quiet HUD notice, suggest lowering the agent count |
| Sustained frame time above 20 ms for 2 s | auto-reduce visual effects before reducing the agent count                        |

> **Invariant.** Performance degradation only ever touches _rendering_. Agent count, `H` and hazard rates are never auto-adjusted — the simulation the user is judged on must stay the simulation they configured.

## 5.5 Haptic + audio event map (Part 6)

**Implementation split (proportionate):** SwiftUI `.sensoryFeedback` for all standard Taptic patterns, plus **exactly three** custom `CoreHaptics` patterns. Three is the entire CoreHaptics scope — enough for signature moments, small enough to build and test in a hackathon.

| Custom pattern  | Shape                                                                                                            |
| --------------- | ---------------------------------------------------------------------------------------------------------------- |
| `haptic.klaxon` | 2 transients (intensity 1.0, sharpness 0.9) separated by 0.18 s, repeated 3× over 1.2 s — synced to `sfx_klaxon` |
| `haptic.crush`  | 0.9 s continuous, intensity ramping 0.4 → 1.0, sharpness 0.3 — a rising swell, not a buzz                        |
| `haptic.fail`   | 2 transients (intensity 0.7, sharpness 0.2) at 0 s and 0.5 s — low, slow, sombre; deliberately **not** `.error`  |

| Event                         | Haptic            | Sound              |             Both?             | Anti-fatigue                                                                         |
| ----------------------------- | ----------------- | ------------------ | :---------------------------: | ------------------------------------------------------------------------------------ |
| Tool select / chip tap        | `.selection`      | `ui_tap`           |             both              | —                                                                                    |
| Grid snap while drawing       | `.selection` @0.4 | —                  |        **haptic-only**        | **only on 1.0 m major lines**, max 8/s                                               |
| Element placed                | `.impact(.light)` | `ui_tap`           |             both              | —                                                                                    |
| Invalid placement             | `.warning`        | —                  |          haptic-only          | 1/s                                                                                  |
| Delete confirmed              | `.impact(.rigid)` | `ui_tap`           |             both              | —                                                                                    |
| Export / save complete        | `.success`        | `sfx_ui_confirm`   |             both              | —                                                                                    |
| **Alarm trigger**             | `haptic.klaxon`   | `sfx_klaxon`       |           **both**            | once per run                                                                         |
| Congestion ≥ 4.0              | `.impact(.soft)`  | `sfx_sting_soft`   |             both              | first crossing only, 6 s cooldown                                                    |
| **Bottleneck ≥ 5.0**          | `.warning`        | `sfx_sting_warn`   |           **both**            | first crossing only, 6 s cooldown                                                    |
| **Crush ≥ 7.0**               | `haptic.crush`    | `sfx_sting_crit`   |           **both**            | first crossing only                                                                  |
| Exit blocked                  | `.error`          | `sfx_exit_blocked` |             both              | once per exit                                                                        |
| **Casualty**                  | `.impact(.heavy)` | `sfx_thud`         | both → **sound-only after 3** | **first 3 casualties only** — a mass-casualty run must not become a buzzing massacre |
| Agent emotion chirp           | **none**          | `sfx_chirp_*`      |        **sound-only**         | with 200 agents, haptics here are unthinkable                                        |
| Ambient murmur · fire · flood | **none**          | loops              |        **sound-only**         | —                                                                                    |
| RALLY appears                 | `.impact(.soft)`  | —                  |          haptic-only          | 1 per card                                                                           |
| RALLY talking                 | **none**          | `sfx_mascot_blip`  |          sound-only           | —                                                                                    |
| Scrub past an event marker    | `.selection` @0.5 | —                  |          haptic-only          | markers only, never per frame                                                        |
| Score ring fill               | light ticks ×≤8   | —                  |          haptic-only          | fixed 8 ceiling                                                                      |
| **Verdict PASS**              | `.success`        | `sfx_fanfare_pass` |           **both**            | once                                                                                 |
| **Verdict WARN**              | `.warning`        | `sfx_sting_warn`   |           **both**            | once                                                                                 |
| **Verdict FAIL**              | `haptic.fail`     | `sfx_motif_fail`   |           **both**            | once                                                                                 |

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
- **RALLY card:** `.accessibilityElement(children: .contain)` — headline, then metric sentence, then each action chip as a `Button` with a hint ("Applies the fix and re-runs the simulation"). The mascot sprite is `.accessibilityHidden` (decorative); RALLY's _state_ is conveyed by the headline text, never by the sprite alone.
- Reading order is set explicitly with `.accessibilitySortPriority` so it runs headline → metric → actions regardless of visual placement.

### ★ v3 INVERSION — the parametric editor is the primary authoring path

v2 built **two** authoring paths: freehand drag-to-draw as the primary experience, plus a form-based parametric editor added late as the VoiceOver alternative, with the honest disclosure that freehand has no accessible equivalent.

**v3 inverts this.** The **parametric editor is the primary path** and the freehand tool is optional, shipped only if everything else is done.

**The parametric editor:** rooms, exits and props placed, sized and moved through tappable handles, steppers and typed dimensions, all snapped to the 0.25 m grid. Exit clear width by 0.1 m stepper. Add an exit on wall {N/E/S/W}. Select an obstacle from a list and reposition or remove it (structural props expose a disabled row labelled `LOCKED — STRUCTURAL`). Crowd count, mix and alarm delay as chips.

**Why this is the highest-value structural trade in v3 — five reasons:**

1. **It is cheaper.** One authoring path instead of two, and the second one was scheduled a day before code freeze.
2. **It deletes the criterion 04 problem instead of documenting it.** Criterion 04 gives zero for "accessibility statements without demonstrable implementation" and its 5-anchor reads _"accessibility and platform behavior shaping the product from the start"_. A disclosed workaround scores 3; an accessible primary path scores 4–5.
3. **It is more credible for the stated user.** A venue operator typing `Exit A: 1.2 m` is more plausible than one finger-painting a floor plan. That is "product decisions that reflect the stated user and context" — criterion 01, 20 points, tie-break #2.
4. **It makes Apply & re-run nearly free.** The coach's fix is a parameter change; the engine already owns the geometry. Apply & re-run is the criterion 01 outcome and is promoted to Must in v3.
5. **It removes a live-demo failure mode.** At the finale, judges may ask for hands-on device access. A judge holding the phone will draw something the renderer has never seen. Steppers cannot produce a malformed venue.

**Accessibility consequence:** the _entire_ core loop is now VoiceOver-operable end to end — preset or parametric authoring → simulate → verdict → apply a fix → re-run. There is no dead end and no disclosed gap. The freehand tool, if it ships, is labelled as an additional convenience, not a required step.

### Reduce Motion — data-motion versus decorative-motion

The key distinction: **motion that carries information stays; motion that carries only delight goes.**

| Motion                                | Reduce Motion                                | Why                                                   |
| ------------------------------------- | -------------------------------------------- | ----------------------------------------------------- |
| Agent walk cycles, position updates   | **kept**                                     | _is_ the simulation — removing it removes the product |
| Density glow, hazard spread, smoke    | **kept** (crossfade instead of pulse)        | conveys hazard state                                  |
| Emote badge pop-in                    | kept, **no overshoot** (fade plus scale 1.0) | conveys emotion                                       |
| RALLY entrance bounce                 | → cross-fade                                 | decorative                                            |
| RALLY `alert` antenna strobe          | → **static**                                 | decorative plus photosensitivity risk                 |
| `celebrate` confetti                  | → a single static burst frame                | decorative                                            |
| Gyro camera parallax                  | → **off**                                    | decorative                                            |
| Score-ring sweep                      | → the number cross-fades to its final value  | decorative                                            |
| Sheet and banner springs              | → `.easeInOut(0.2)`, no overshoot            | decorative                                            |
| Symbol effects (`.pulse` / `.bounce`) | → static plus tint change                    | decorative                                            |

**Reduce Transparency:** all Liquid Glass surfaces become solid `surface.raised` with a 1 pt `separator` border. Verified against the §4.8 contrast tokens — the text ratios hold, because they were computed against an opaque base.

### Colour-blind safety — shape and pattern redundancy

Pattern fill is **always on**, not a toggle, so the default experience is already accessible:

| Band              | Colour     | Pattern            | Extra redundancy                                          |
| ----------------- | ---------- | ------------------ | --------------------------------------------------------- |
| Comfortable < 1.8 | dark green | **no fill**        | —                                                         |
| Congested 2–4     | amber      | **sparse dots**    | chip shows the value                                      |
| At risk ≥ 5       | orange     | **diagonal hatch** | chip plus amber banner                                    |
| Crush ≥ 7         | red        | **cross-hatch**    | chip plus red banner plus `exclamationmark.triangle.fill` |

`@Environment(\.accessibilityDifferentiateWithoutColor)` increases pattern opacity by 40%, gives agent emotion auras outline rings (calm none, uneasy dashed, panicked solid double), and adds inline text labels to verdict badges. Agent emotion is _already_ multi-channel: aura colour **plus** emote glyph shape ("?" versus "!") **plus** gait jitter. Staff use `agent.staff` violet **plus** a distinct silhouette — deliberately outside every semantic ramp.

### Captions & transcripts

Every audio cue has a visual twin — that _is_ the caption strategy:

| Audio                         | Visual twin                                  |
| ----------------------------- | -------------------------------------------- |
| RALLY blip speech             | on-screen text, streaming in sync            |
| Escalation stings             | banner plus timeline marker                  |
| Klaxon                        | "ALARM" HUD state plus banner                |
| Casualty thud                 | timeline pin plus casualty counter increment |
| Fire and flood loops          | visible hazard rendering                     |
| Crowd murmur (density-linked) | density chips plus glow                      |
| Verdict fanfare or motif      | verdict badge plus headline                  |

Plus an **Event Log sheet** (scrollable, timestamped, VoiceOver-readable) mirroring the scrubber, and a **plain-text run transcript** exported alongside the PDF report.

### Targets, contrast, focus

- **44 × 44 pt minimum** on every control. The scrubber renders 20 pt tall but carries a 44 pt hit area. Direct canvas manipulation is exempt — it is spatial, not a control.
- Contrast ratios are verified in §4.8 (lowest text token 5.1:1, lowest semantic 5.6:1 — all at or above WCAG AA). 🟡 Re-verify with Accessibility Inspector on device.
- Focus order: HUD → canvas → RALLY → scrubber → playback → tab bar. Sheets trap focus and return it to the invoking control on dismissal.
- Every icon-only control has an `.accessibilityLabel`; no destructive or state-critical action is icon-only.

## 5.7 Thumb-zone mapping (iPhone 16, 393 × 852 pt)

Measured from the bottom edge for a right-handed one-handed grip 🟡:

| Zone        | Range      | Contents                                                                                              |
| ----------- | ---------- | ----------------------------------------------------------------------------------------------------- |
| **Natural** | 0–260 pt   | tab bar, playback row, scrubber, tool sheet, primary CTA                                              |
| **Stretch** | 260–520 pt | RALLY card action chips, density chips                                                                |
| **Hard**    | 520–852 pt | HUD readouts (**display-only**), nav title, **destructive actions** (deliberately far from the thumb) |

**RALLY reachability rule:** when the card is placed in the hard-reach top half (because the hotspot is in the bottom half), a persistent **44 pt "RALLY" pill** appears in the natural zone; tapping it re-opens the card as a bottom sheet. No action is ever stranded out of reach.

## 5.8 Cross-cutting — WWDC26 / AI

| Adoption                            | Use here                                                               |  Tier  | Fallback (ships first) |
| ----------------------------------- | ---------------------------------------------------------------------- | :----: | ---------------------- |
| `.sensoryFeedback` (iOS 17+)        | all standard haptics                                                   |  Must  | `UIFeedbackGenerator`  |
| Auto-minimising toolbars (iOS 27)   | the HUD minimises on playback and restores on touch                    | Should | manual chevron         |
| Symbol effects `.pulse` / `.bounce` | live warning escalation (substituting for unavailable variable colour) | Should | static tint change     |
| Foundation Models                   | RALLY **text only**                                                    | Should | canned lines           |

**Invariants:** no gesture, spring, haptic or accessibility affordance depends on Foundation Models — the entire interaction model is identical on a device with no Apple Intelligence. And no accessibility behaviour sits behind an iOS-27 API; the accessibility pass is fully iOS-26.

---

# B. BUILD SEQUENCE — DEPENDENCY-ORDERED STAGES S0–S5

> **v3 replaces the calendar.** v2's D1–D17 table assumed a full 17-day window from a standing start. What remains is materially less, and a schedule that has already drifted is worse than no schedule. This section is ordered by **dependency and exit criteria**, not by date. Work the stages in order; do not begin a stage until the previous one's exit criteria are true on the physical device.

## 6.1 The two rules that govern everything below

**Rule 1 — The core journey is the product.** Nothing above the S2 list is started until every row of S2 is true. Criterion 02 (25 points, tie-break #1) explicitly penalises "large feature sets with an incomplete core journey".

**Rule 2 — Once S2 exits, evidence outranks features.** States, accessibility and the recording (S3–S4) come before _any_ remaining feature. Criterion 06 is the channel through which criteria 01–04 reach a judge; an unbuilt feature costs a fraction of a point, an unrecorded product costs all of them.

## 6.2 Developer split & the parallelisation contract _(unchanged from v2 — it works)_

| Dev                | Owns                                                                                                                                 | Rationale                                                                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **Dev A — Engine** | `EgressEngine`: standards, venue and agent models, flow field, social force, hazards, metrics, score, verdict, event log             | Algorithm-heavy, pure Swift, headless-testable — the best surface for learning Swift fundamentals without fighting SwiftUI simultaneously |
| **Dev B — App**    | The SwiftUI app: design system, canvas renderer, parametric editor, HUD, sheets, Spaces, the AI seam, haptics, accessibility, states | UI-heavy; learns SwiftUI and Observation                                                                                                  |

**The contract that makes parallel work possible:** `SimulationSnapshot` is locked in S0, and Dev A immediately ships `MockSimulation` — a ~40-line fake emitting agents orbiting toward a fake exit. Dev B builds the entire renderer, HUD, gestures and camera against the mock, then swaps in the real engine at S1 exit. **Neither dev is ever blocked on the other.** If the engine slips, the UI still demos; if the UI slips, the engine still tests.

**Pairing windows:** engine ↔ renderer integration (S1 exit), end-to-end wiring (S2 exit), bug bash (S4).

---

## 6.3 S0 — Foundation and risk retirement

| Dev A                                                                                                       | Dev B                                                                                                                                                                                       |
| ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Repo, `EgressEngine` package, `.gitignore`; `Vec2`, `GridCoord`, `GridGeometry`, `SeededRNG` + first tests  | App target and `TabView` shell running **on the physical iPhone 16**                                                                                                                        |
| `SafetyStandards`, `VenueModel` / `Exit` / `Obstacle`; **lock `SimulationSnapshot`**; ship `MockSimulation` | ⚠️ **AI-availability spike** (`SystemLanguageModel.availability`) · build-acceptance spike (archive → install) · `ColorTokens` / `Motion` / radius scale · resolve all 🔴 SF Symbol strings |

**Exit criteria — all true on device:**

- [ ] `swift build` clean; the app archives against the iOS 27 SDK with deployment target iOS 26 and installs on the iPhone 16
- [ ] At least 6 engine tests green: grid↔world round-trip, `SeededRNG` determinism, `SafetyStandards` values
- [ ] **`SystemLanguageModel.availability` result recorded** — this retires R-03 at the earliest possible moment, not at recording time
- [ ] Every 🔴 in Appendix 3 resolved to ✅ or replaced by its named fallback
- [ ] Apple Intelligence assets confirmed downloaded **while online**

## 6.4 S1 — Walking skeleton

| Dev A                                                                                                              | Dev B                                                                                                            |
| ------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `FlowField`: multi-source Dijkstra, no corner-cutting, wall-distance and normal field; maze fixture tests          | `SimCanvasView`: `TimelineView(.animation)` + `Canvas`, dot grid, rendering **mock** agents; pan / zoom / clamps |
| `SpatialHash`, `AgentSpawner`, drive force, semi-implicit Euler — agents reach the exit                            | HUD bar, playback row, camera clamp 3–40 pt per cell, double-tap to fit                                          |
| Full social force: pedestrian repulsion, contact, friction, wall force; substepping at H = 1/120 with the dt clamp | **Swap `MockSimulation` → real `Simulation`**; Instruments profile on device                                     |

**Exit criteria:**

- [ ] Flow field reaches all passable cells; no corner-cutting; spatial-hash neighbour sets correct
- [ ] 10 000-step integrator stability — no NaN, no blow-up
- [ ] Agents spawn → path to the exit → all evacuate
- [ ] **≥55 fps sustained** (60 target, 55 floor) in Instruments at the shipped agent count
- [ ] Tag `golden-skeleton`

## 6.5 S2 — ★ THE CORE JOURNEY (the submission floor)

**This is the minimum shippable submission.** If nothing after this stage is built, Egress is still a coherent, honest, demonstrable product.

| Dev A                                                                                              | Dev B                                                                                                                        |
| -------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `DensityGrid` (bin + separable blur); `Metrics`: clearance, peak density, at-risk person-seconds   | ★ **Parametric editor** (§5.6): rooms, exits, props via handles, steppers and typed dimensions on the 0.25 m grid; undo/redo |
| Fire cellular automaton, smoke diffusion, dirty-flag flow-field recompute; casualty classification | Hazard and density-glow rendering; cyan dimension overlay + the `1 PIXEL BLOCK = 0.25 m × 0.25 m` caption                    |
| `SafetyScore`, `VerdictRules`, `RunEventLog`, live-escalation predicates                           | Results sheet, score ring, verdict badges, **canned banner strings**, escalation banner                                      |
| **Apply & re-run**: deterministic engine-side geometry edit + before/after score                   | Spaces library with **~4 furnished presets**; pre-run config chips; RALLY sprite + card with **canned lines**                |

**Exit criteria — all true on device, airplane mode, three consecutive runs, zero crashes:**

- [ ] Clean launch → open or shape a furnished venue → set the crowd → alarm → fire and emotions → live escalation banner → verdict, score and reasons **with units**
- [ ] **RALLY names a geometry fix → Apply → re-run → visibly better score**
- [ ] Score formula reproduces the §2.8 worked examples (Concert Crush = 7, Office = 98)
- [ ] Verdict order correct across all 6 branches
- [ ] **Faster-is-slower reproduces** — non-monotonic throughput across a panic sweep
- [ ] Determinism: same seed → identical clearance
- [ ] Tag **`golden-core`** and archive the build

> **Trigger:** if S2 exit criteria are not met and time is short, cut S3 items in the §6.7 order and ship S2. A complete S2 with a good recording outscores an incomplete S3.

## 6.6 S3 — Evidence-grade (this is where 4s and 5s come from)

Ordered by points-per-hour, highest first. **Do them in this order.**

|  #  | Item                                                                                                                                           | Owner | Criterion |
| :-: | ---------------------------------------------------------------------------------------------------------------------------------------------- | :---: | --------- |
|  1  | **States and recovery** — empty, loading, offline, unavailable-feature, failure/degradation (§E.2)                                             |   B   | 02        |
|  2  | **Accessibility pass** on the primary path — labels, values, canvas summary element, Dynamic Type, Reduce Motion, pattern fills, 44 pt targets |   B   | 04        |
|  3  | **On-device coach** — `CoachingService`, `@Generable` schemas, the **V1–V8 validation gate**, fallback wiring, streaming UI                    |   B   | 03        |
|  4  | **Anticipatory dodge + stumble** (§2.13.4–5)                                                                                                   |   A   | 02 · 05   |
|  5  | **Aisle clear-width analysis + verdict reason 4d** (§2.13.7)                                                                                   |   A   | 01 · 02   |
|  6  | Haptics: `.sensoryFeedback` + 3 CoreHaptics patterns, 1 per 0.5 s                                                                              |   B   | 03        |
|  7  | Three SFX cues only (§3.6)                                                                                                                     |   A   | 04        |
|  8  | Debug touch-indicator overlay for the recording                                                                                                |   B   | 06        |

**Exit criteria:**

- [ ] RALLY renders on-device model text in airplane mode; a **forced-fallback run produces an identical layout with canned lines**
- [ ] V1–V8 validation gate green, each with a crafted malformed-output fixture
- [ ] Every state in §E.2 reachable and visually resolved
- [ ] VoiceOver completes the primary journey end to end with no dead end
- [ ] Accessibility Inspector clean on Results, RALLY and Spaces; AX5 Dynamic Type without truncation
- [ ] Tag `golden-evidence`; **PIN the toolchain** — record the exact Xcode build number and device OS build; no Xcode or OS updates afterwards

## 6.7 S4 — Evidence production

> **R-19 rule: record a complete, usable take the day S2 exits.** Do not let the first take be the last task. Every subsequent take is an improvement on something already submittable.

| Step | Detail                                                                                                     |
| ---- | ---------------------------------------------------------------------------------------------------------- |
| 1    | Device setup checklist (§E.5)                                                                              |
| 2    | **One unbroken take of the core journey** — repeat until clean; this is the only beat that must not be cut |
| 3    | Coach + deliberate fallback beat                                                                           |
| 4    | States reel + audible VoiceOver                                                                            |
| 5    | Limitations, spoken                                                                                        |
| 6    | Voiceover recorded separately and laid over                                                                |
| 7    | 30-minute soak: no crash, no memory growth, thermal below `.serious`                                       |

**Exit criteria:** a complete video exists that would score acceptably if submitted immediately. Tag `release-candidate`. **CODE FREEZE.**

## 6.8 S5 — Lock and submit

- [ ] Submission form completed (§E.4) — problem, user, product explanation; platforms and technologies **that actually run on the demo device**; third-party and AI-tool disclosure; track evidence; **known limitations and judging instructions with the timestamp index**
- [ ] Secret scan clean
- [ ] Video uploaded and the link verified from a logged-out browser
- [ ] Submitted **before** 7 Aug 11:59 PM IST, not at it

## 6.9 Cut order — first to go, last to go

**widget / Siri → `.egress` export → AI heatmap → Monte Carlo → PDF report → Learn quiz and case studies → flood → replay-seek + ring buffer → Metal glow → audio bus graph → Liquid Glass / toolbar / reorderable grid / symbol effects → expressive emotes → obstacle memory → freehand drawing → SFX beyond 3 cues.**

Everything up to and including "symbol effects" is **already cut in v3** — deleted, not deferred. The list is retained so the decision is not re-litigated under pressure.

**The floor — never cut:** the parametric editor · fire and smoke · agent emotions · furnished venues · the verdict engine · **Apply & re-run** · RALLY (degrading to a static sprite with canned text before disappearing) · **the states matrix** · **the accessibility pass** · **the recording**.

> **Ranking note.** In v2 the cut order protected features. In v3 it protects _evidence_. States, accessibility and the recording sit **above** every remaining feature, because criterion 06 gates the visibility of criteria 01–04 and a feature nobody can verify scores as Weak.

## 6.10 Daily discipline _(unchanged)_

| Ritual                  | When               | Purpose                                                                                                                                                                                                        |
| ----------------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 15-minute standup       | each morning       | yesterday · today · blockers · **which stage are we in**                                                                                                                                                       |
| **Explain-back review** | 20 min, end of day | Each dev walks the other through their diffs. Anything neither can explain is rewritten or deleted. This is the enforcement mechanism for "AI-generated code is untrusted until reviewed, compiled and tested" |
| Green-main rule         | every merge        | feature branches; `swift test` green before merging; main always compiles                                                                                                                                      |
| **Daily device run**    | end of day         | the app runs on the physical iPhone 16, not just the Simulator                                                                                                                                                 |
| Golden build            | at each stage exit | tag plus archive — you can always fall back to the last golden build                                                                                                                                           |
| Secret hygiene          | continuous         | no keys, tokens or sensitive test data committed                                                                                                                                                               |

## 6.11 Toolchain discipline

Demo device stays on **stable iOS 26**; build toolchain remains Xcode 27 / Swift 6.4 / iOS 27 SDK. Updates are permitted only immediately after a stage exit, never mid-stage, and **never after the S3 pin**. If anything breaks after the pin, roll back to it; the last golden archive and its recording are the fallback submission.

> **v3 consequence, stated plainly.** Because the demo device runs iOS 26, every iOS-27-only API is by definition _not functional in the submitted product_. Criterion 03 gives zero for mentioning such an API. **The WWDC26 adoption table of v2 §6.9 is deleted as a goal.** List on the form only what a judge can watch working in the video.

---

# D. RISK REGISTER

**Scoring:** L(ikelihood) and I(mpact) as H/M/L. "Fallback" is what actually ships if the risk lands — never "try harder."

## D.0 v3 risk deltas

| Risk                                            | Change in v3                                                                                                                                                                                                                                                                                                   |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **R-01 Engine overrun**                         | Likelihood **rises** with the compressed window. Mitigation is no longer a descope _ladder_ to be walked under pressure — the §6.9 cuts are applied now, before they are needed.                                                                                                                               |
| **R-03 AI availability**                        | Unchanged and still retired at S0. **Note the reframe: the fallback is now a scored asset, not merely a contingency.** It is triggered deliberately on camera as criterion 02's "visible recovery from an unavailable service".                                                                                |
| **R-07 Scope creep**                            | Mitigation strengthened: §6.1 Rule 1 makes S2 a hard gate, and §6.9 lists the cuts as already-taken decisions so they are not re-litigated at 2 a.m.                                                                                                                                                           |
| **R-15 Real-incident ethics**                   | ⛔ **RETIRED.** The Learn tab's case studies are cut, which removes the entire §D.1 handling burden.                                                                                                                                                                                                           |
| **R-16 Overclaiming**                           | **Raised to H impact.** The rubric punishes unverifiable and non-functional claims in three separate criteria (02, 03, 06). Mitigations: the §E.4 timestamp index, on-screen `FUNCTIONAL / DEMO DATA` labels, and the §0.2.1 rule against overclaiming Pocket Brain essentiality.                              |
| **NEW · R-19 Evidence single-point-of-failure** | **L: M · I: H.** Video-only means one artifact carries every criterion, and it cannot be replaced after the deadline. _Mitigation:_ record a complete usable take the day S2 exits (§6.7), and treat every later take as an improvement on something already submittable. _Fallback:_ submit the earlier take. |
| **NEW · R-20 Hands-on failure at the finale**   | **L: M · I: M.** Judges may request device access and will not follow the script. _Mitigation:_ the parametric editor cannot produce a malformed venue (§5.6); the verification menu (§E.6) is rehearsed. _Fallback:_ the local backup recording, which the rules explicitly permit.                           |

| ID       | Risk                                                                                                                                              |   L   |   I   | Early warning signal                                                                          | Pre-emptive mitigation                                                                                                                                                                                                              | Concrete fallback                                                                                                                                                                                                                                                 | Owner |  Gate  |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | :---: | :---: | --------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---: | :----: |
| **R-01** | Engine complexity overruns the schedule                                                                                                           | **H** | **H** | S1 exit criteria not met                                                                      | Engine-first sequencing; `MockSimulation` unblocks Dev B; headless tests over UI debugging                                                                                                                                          | Dev B pairs onto the engine; cut Monte Carlo, A/B, PDF and quiz outright; apply the §6.9 cuts immediately and ship S2                                                                                                                                             |   A   | S1/S2  |
| **R-02** | 60 fps unattainable at 200 agents                                                                                                                 | **M** | **H** | Instruments below 55 fps sustained on device at D5                                            | Spatial hash O(n); flow field not recomputed per frame; density grid once per frame; profile on **device** from D1                                                                                                                  | Step down: 150 agents → dots instead of sprites → drop the Metal glow → background stepping with double buffering. **Floor 100 agents**                                                                                                                           |  A/B  |   S1   |
| **R-03** | **Apple Intelligence unavailable on the demo device** (device tier, region or language) — kills the Pocket-Brain track proof                      | **L** | **H** | `SystemLanguageModel.availability` is not `.available` at **S0**                              | 🟡 The iPhone 16 is a capable device, but **device state is the only authority** — checked at S0, not assumed. Ensure Apple Intelligence is enabled and model assets are downloaded **while online**, before the airplane-mode demo | Demo runs on `CannedCoach` with **script variant B** (§E.6): reframe from "the model wrote this" to "the deterministic engine wrote this, and here is where the model plugs in." Escalate at S0: source another device or re-open the track choice                |   B   | **S0** |
| **R-04** | Beta toolchain instability or a late build break                                                                                                  |   M   |   H   | Xcode 27 crashes, archive fails, previews die                                                 | Demo device on **stable iOS 26**; build-acceptance spike at S0; **pin the toolchain at S3 exit**; golden tag at every gate                                                                                                          | Roll back to the pin; submit the **`golden-should` archive plus its recording**                                                                                                                                                                                   |   A   | S0/S3  |
| **R-05** | API churn between betas breaks working code                                                                                                       |   M   |   M   | Compile errors after an Xcode update                                                          | No updates mid-stage; updates only immediately post-gate; every iOS-27 call availability-gated with the fallback already shipping                                                                                                   | Delete the gated enhancement — the fallback is already the default path. Zero core impact by construction                                                                                                                                                         |   A   |   S3   |
| **R-06** | Foundation Models output is poor, slow or refuses                                                                                                 |   M   |   M   | Latency above 4 s, or V1–V8 failures in testing                                               | Number-free prose plus `MetricKey` substitution; the V1–V8 gate with crafted malformed fixtures; a streaming UI so latency is felt as typing                                                                                        | `CannedCoach` — **identical card layout, different words**. The user sees no broken UI                                                                                                                                                                            |   B   |   S3   |
| **R-07** | Scope creep / tier violation                                                                                                                      | **H** |   M   | Work starting on a Should item before S2 signs off                                            | The MoSCoW gate is a hard rule; the daily standup names the current tier; the cut order is pre-agreed                                                                                                                               | Enforce the cut order top-down, same day. Golden builds mean a cut never costs the demo                                                                                                                                                                           | Both  |  all   |
| **R-08** | A developer is lost for days (illness, exam, outage)                                                                                              |   M   |   H   | Any multi-day absence                                                                         | Green-main plus the daily explain-back means neither dev's work is a black box; both can build and run the whole app                                                                                                                | The remaining dev defends the **Must tier only**; everything Should-and-above is cut without discussion                                                                                                                                                           | Both  |   S2   |
| **R-09** | **The physics does not produce the wow** — jams look like sludge, faster-is-slower does not emerge, crowds look like particles rather than people |   M   | **H** | The faster-is-slower test does not reproduce at S2 exit; playtests read as "dots drifting"    | Constants are tunable in one file; the validation test is a **gate criterion**, not an afterthought; emotion is multi-channel (aura plus emote glyph plus gait) so humanity reads even at dot scale                                 | Raise `K_FRIC` and `K_BODY`; narrow the demo exit to force a visible jam; **worst case, demo the Nightclub preset tuned by hand** — a preset that reliably jams is honest, because it is a real layout with a real flaw, and the seeded RNG makes it reproducible |   A   |   S2   |
| **R-10** | Demo device fails on the day (crash, thermal, battery, notification, call)                                                                        |   M   | **H** | Any crash in the 30-minute soak at S4                                                         | Airplane mode (which also kills notifications) plus Do Not Disturb, battery above 80%, a cool device and fixed brightness; three-consecutive-run stability is a S2 criterion; haptic and audio engine restart handlers              | **The recording is the submission.** Record at least 5 good takes on D16 so no live performance is ever load-bearing                                                                                                                                              |   B   |   S4   |
| **R-11** | The recording runs long, or the journey does not fit 3 minutes                                                                                    |   M   |   M   | First take over 3:30                                                                          | A beat sheet with timestamps (§E.2); rehearse with the fixed seed; voiceover recorded separately so the edit can breathe                                                                                                            | Cut the A/B re-run to a **split-screen still** (before and after numbers) — saves about 20 s and keeps the payoff                                                                                                                                                 |   B   |   —    |
| **R-12** | Audio or haptics silently die after an interruption                                                                                               |   M   |   M   | A silent app after backgrounding in testing                                                   | `stoppedHandler` / `resetHandler` restart plus session reactivation on `.active`; explicitly tested in the S4 soak                                                                                                                  | Master sound toggle off; the visual twin of every cue already carries the meaning                                                                                                                                                                                 |   B   |   S4   |
| **R-13** | Memory growth or thermal throttling over a long session                                                                                           |   L   |   M   | Ring buffer above 16 MB; `thermalState ≥ .serious` in the soak                                | Ring buffer capped with 5 Hz decimation; degradation touches **rendering only**, never the physics                                                                                                                                  | Shorten the demo run; disable shader effects; the 30-minute soak at S4 is the proof                                                                                                                                                                               |   A   |   S4   |
| **R-14** | Work lost (repo, disk or a bad merge)                                                                                                             |   L   |   H   | —                                                                                             | Remote push after every merge; tag plus archive at every gate; the plan itself lives in `EGRESS_PLAN.md` in-repo                                                                                                                    | Restore the last golden tag; at most one day lost                                                                                                                                                                                                                 | Both  |  all   |
| **R-15** | **Real-disaster content handled insensitively** — Itaewon and Astroworld killed real people                                                       |   M   | **H** | Any copy that reads as a game level, a leaderboard, or blame                                  | See §D.1 — this is a product-integrity risk, not a PR one                                                                                                                                                                           | Ship **static text case studies with no playable recreation**. The Wellness overlay survives intact; the interactive recreation is expendable                                                                                                                     |   B   |   S4   |
| **R-17** | **Dodging destabilises the crowd** — dense furniture plus predictive steering plus contact forces produces gridlock, jitter or side-oscillation   |   M   |   M   | Playtest at D10 shows agents vibrating, deadlocking in aisles, or flip-flopping between sides | `DODGE_COMMIT` enforces side commitment; dodge strength is gated by `awareness_eff`; obstacle memory decays; presets authored to clear the aisle minima; a dedicated stability test in the §2.13.11 suite                           | **Set `A_DODGE = 0`** — agents revert to pure flow-field routing plus the existing wall force, which is the behaviour already validated at S1 and S2. One constant, no code change, no regression                                                                 |   A   |   S3   |
| **R-18** | **Expressive emotes read as trivialising** — crying badges over a simulated mass-casualty event                                                   |   L   | **H** | Any playtest reaction of "this feels like a game about people dying"                          | The §2.13.6 tone rules are binding: no gore, no screaming, a restrained teardrop badge, and **total suppression on real-incident presets** (matching §D.1)                                                                          | Ship only the existing "?" and "!" badges. The display layer is separate from the physics, so removal costs nothing                                                                                                                                               |   B   |   S4   |
| **R-16** | Overclaiming — output mistaken for certified engineering advice                                                                                   |   L   | **H** | Any UI string implying compliance, approval or certification                                  | A persistent disclaimer string; RALLY is named a **coach**, never an inspector or marshal; the PDF report carries the disclaimer in its header                                                                                      | Strengthen the wording; put the disclaimer on the results card, in the PDF, in the README, and spoken in the demo voiceover                                                                                                                                       |   B   |   S4   |

## D.1 R-15 handling rules — ⛔ RETIRED IN v3

The Learn tab's real-incident case studies are **cut** (§6.9). The playable recreations, the difficulty-chip suppression rules, the sourcing requirements and the RALLY-silence rule all fall away with them.

**Why cutting was the right call under this rubric, not merely the safe one:** the case studies sat off the core journey, so criterion 02 gave them nothing; they read as "documentation volume" to criterion 06; and they carried the single highest reputational risk in the plan. Removing them retires R-15 entirely and returns roughly a day of authoring to the states and accessibility work, which _is_ scored.

**If the finale window permits an expanded build (§E.7), the case studies may return as static, sourced, dated text only** — never as playable recreations, and always under the original §D.1 framing rules, which are preserved in v2 for that purpose.

## D.2 Residual risk after mitigation

| Risk area                       | Post-mitigation exposure                                                                                                                                                                   |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Schedule (R-01 / R-07 / R-08)   | **Moderate.** The descope ladder guarantees _something_ complete ships; it does not guarantee the Should tier. Most likely landing zone: Must tier plus RALLY with AI plus partial Should. |
| Track proof (R-03 / R-06)       | **Low**, because it is retired on **Day 1** rather than discovered on Day 16.                                                                                                              |
| Demo failure (R-04 / R-10)      | **Low** — golden builds plus a pre-recorded demo mean no single failure on Aug 7 can sink the submission.                                                                                  |
| Product integrity (R-15 / R-16) | **Low**, provided §D.1 is treated as binding.                                                                                                                                              |

---

# E. EVIDENCE PLAN — VIDEO, SUBMISSION FORM, FINALE

> **v3 rewrites this section completely.** v2 planned a 180-second demo for an ambiguous "live demo or recording" deliverable on 7 August. The reality is: **a video is the only evidence for both asynchronous rounds**, and the live demo is a separate artifact twelve days later on 22 August.

## E.1 What the evidence must prove

Criterion 06's "Exceptional" anchor is _"the evidence is exceptionally efficient and trustworthy: every material claim is easy to verify without unnecessary production."_ Read the exclusions alongside it: **cinematic editing, expensive equipment and presenter charisma earn nothing.** This is not a pitch video. It is a verification instrument.

Five judges will watch it — two at preliminary, three more scoring fresh at semifinals — with no author present and no opportunity to ask a question.

## E.2 States and recovery — ship them, then show them

Criterion 02 asks directly whether the product handles _loading, empty, permission, offline and failure_ states, and rewards _visible recovery from relevant failures or unavailable services_. In v2 these lived only in a Definition-of-Done checklist. In v3 they are **shipped features with screen time**.

| State                     | Implementation                                                                                                          | Screen time                   |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| **Empty**                 | No saved spaces → dimmed blueprint grid, `NO SPACE LOADED`, one primary CTA. Never a blank screen                       | ~2 s                          |
| **Loading**               | First flow-field solve / model warm-up → determinate indicator, never a frozen canvas                                   | ~2 s                          |
| **Offline**               | Airplane mode on for the entire recording — this _is_ the product, not a limitation                                     | throughout                    |
| **Unavailable feature** ★ | Foundation Models unavailable → `CannedCoach`, **identical card layout, different words**                               | ~10 s, deliberately triggered |
| **Failure / recovery**    | Thermal or frame-rate pressure → visible agent-count step-down notice; above-budget agent count → a quiet mono HUD line | ~5 s                          |
| **Paused on return**      | Returning from background never auto-resumes; calm centred `PAUSED` panel                                               | ~2 s                          |
| **Permission**            | **Egress requests no permissions and holds no network entitlement.** State this plainly                                 | ~3 s, spoken                  |

> ⚠️ **Correction carried into the Definition of Done.** v2 listed "motion permission denied → on-screen trigger" as a state. **Shake detection and raw accelerometer access do not prompt for permission on iOS** — the Motion & Fitness prompt covers activity and pedometer data, which Egress does not use. Verify in Xcode before writing any copy about it. _"This app asks for nothing and sends nothing"_ is a stronger privacy answer than a fabricated denial screen, and inventing one would be precisely the unverifiable claim criterion 02 punishes.

**The deliberately-triggered fallback is the highest-value ten seconds in the video.** Almost no team shows their product degrading gracefully on purpose, and it converts an architectural decision into watchable evidence.

## E.3 The video — structure

**Target 3:00–4:00.** Efficiency is scored; length is not. There is no published cap — confirm via §E.7.

| Time          | Beat                                   | Content                                                                                                                                                                                                                                                                                                                                                                              | Why                                                                                                             |
| ------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| 0:00–0:15     | **Problem + user**                     | The specific user and situation, stated once, concretely. Airplane-mode indicator visible in the status bar from the first frame                                                                                                                                                                                                                                                     | Criterion 01. Plants the offline proof before it is needed                                                      |
| **0:15–2:15** | ★ **CORE JOURNEY — ONE UNBROKEN TAKE** | Launch → open or shape a furnished venue → crowd chips → alarm → evacuation (crowd threads between props, then smoke degrades awareness and they clip furniture and stumble) → escalation banner at the threshold crossing → verdict, score, reasons with units → RALLY names the fix → **Apply** → re-run → **improved score, side by side**. **No cuts anywhere in this segment.** | Criteria 01 + 02. An unbroken take is self-authenticating; a stitched one invites doubt about every claim in it |
| 2:15–2:35     | **On-device coach**                    | The model writing in airplane mode, then the **deliberate fallback**                                                                                                                                                                                                                                                                                                                 | Criterion 03 + track proof, in one beat                                                                         |
| 2:35–2:50     | **States reel + accessibility**        | The §E.2 states, then ~15 seconds of **VoiceOver audible** completing part of the journey                                                                                                                                                                                                                                                                                            | Criteria 02 + 04                                                                                                |
| 2:50–3:10     | **Limitations, spoken**                | Time-compressed hazard rates; the model writes language, the engine supplies every number; iPhone only; educational analysis, not certified engineering advice                                                                                                                                                                                                                       | Criterion 02 "honest limitations" + criterion 06 "honest disclosure"                                            |

**Never cut, whatever the runtime:** the unbroken core journey, the offline callout, the fallback beat, the disclaimer.

**Production rules**

- **Voiceover, not a presenter.** The organisers recommend voiceover _or_ picture-in-picture; the rubric gives nothing for charisma. Choose voiceover. Record it separately and lay it over — live narration into a phone mic while tapping is the classic ruined take.
- **On-screen labels** marking anything not live: `FUNCTIONAL` / `DEMO DATA` / `NOT BUILT`. This is the literal wording of criterion 02's "clear separation between functional, mocked, and planned behavior". Most teams blur it; labelling costs nothing and reads as integrity.
- **Touch-indicator overlay** so no tap is unexplained — a 32 pt translucent `accent.dataGreen` circle on touch-down, behind a `#if DEBUG` flag.
- **Fixed simulation seed** so every take is identical and reproducible.
- **Do not narrate frameworks.** Narrate what the user gets. _"This runs with no signal, and the floor plan never leaves the phone"_ scores under criterion 03. _"We used Foundation Models, Metal, CoreHaptics and Swift Charts"_ is framework count — worth zero.
- **Claim nothing that is not on screen.** Anything cut is not mentioned, not described as planned, not hinted at.

## E.4 The submission form is a scored artifact

The declared fields are: a new working native project · team and contact details · problem, target user and product explanation · TestFlight link **or working screen recording** · Apple platforms and WWDC26 technologies used · third-party APIs, SDKs, packages, libraries, models and AI tools disclosed · track selection and track-specific evidence · **known limitations and setup or judging instructions**.

**That last field is an open invitation to hand judges a verification map. Use it.**

```
JUDGING INSTRUCTIONS — timestamp index

Core journey, unbroken, no cuts .............. 0:15 – 2:15
150 agents at 60 fps on device ............... 0:48   (HUD, in take)
Crowd reroutes around fire, unscripted ....... 1:12
Smoke degrades awareness → collisions ........ 1:24
Aisle width drives the verdict reason ........ 1:40
Apply fix → re-run → improved score .......... 1:52 – 2:15
On-device model writing, airplane mode ....... 2:18
Model unavailable → deterministic fallback ... 2:26   (deliberately triggered)
VoiceOver completes the primary journey ...... 2:41
Limitations, spoken .......................... 2:52
```

**Why this is worth the twenty minutes it costs.** Criterion 06 asks _"does the evidence cover the claims that matter to the score?"_ — this answers it line by line. And because a **15-point spread between two judges, or a two-level gap on any single criterion, triggers a third reviewer**, ambiguity costs twice: once in the score, once in the re-review. The index is variance suppression.

**Known limitations — write real ones.** Hazard rates are plausible and time-compressed, not validated fire modelling · the model writes language, the engine supplies every number · no LiDAR capture · iPhone only · educational analysis, not certified engineering advice. Honesty is scored positively in two separate criteria; nothing in this rubric rewards pretending.

**Technologies field — list only what runs on the demo device.** Criterion 03 gives zero for "mentioning an API that is not functional in the submitted product". A short honest list outscores a long aspirational one.

**Disclosure.** AI coding assistance was used and all submitted code was reviewed, compiled and tested by the team. Third-party dependencies: none. All pixel art and audio original.

## E.5 Recording setup checklist

**Capture:** QuickTime Player on the Mac → New Movie Recording → source = iPhone over USB-C. Preferred over Control Centre recording because it consumes no device CPU or thermal headroom during a sustained 60 fps run and leaves no in-frame recording indicator. 🟡 Confirm the capture frame rate; if it cannot hold 60 fps, fall back to on-device Screen Recording and accept the extra load — test both during S3, not on the last day.

**Device:** airplane mode on · Do Not Disturb · battery above 80%, plugged in · brightness fixed, auto-brightness off · **Low Power Mode off** (it degrades to 30 fps) · device cool before each take · True Tone and Night Shift off · **Apple Intelligence assets confirmed downloaded while online, before airplane mode goes on** · demo venues pre-seeded · fixed seed set.

**Audio:** voiceover recorded separately (Voice Memos or a USB mic) and laid over the edit.

## E.6 The Bengaluru finale (22 Aug) — a separate artifact

Five judges. **Five minutes of demonstration, then five minutes of questions or verification. Scores start fresh.** Finalists bring a working physical Apple device with the finalist build installed, or a Mac that can run the app in a simulator, **plus a local backup recording**.

**The 5-minute live version is not the 3-minute video played slower.** It has live risk, and it must leave room for the judges' half.

**Rehearse a verification menu** — the five things judges most plausibly ask, each answerable in under a minute:

1. _"Change something and run it again."_ → parametric editor, one stepper, re-run, new score.
2. _"Show me it works offline."_ → airplane mode is already on; open Settings and show no network entitlement.
3. _"What happens when the model isn't there?"_ → the deliberate fallback.
4. _"Where does that number come from?"_ → the score formula and the test that pins it to the worked examples.
5. _"Can I use it?"_ → hand over the phone. The parametric editor cannot produce a malformed venue (§5.6).

**Failure protocol.** The rules distinguish two cases: organiser, venue, display, power or shared-network failures **pause the clock and allow a fair restart**; product failures **remain part of the evidence**, but the team may continue from the local backup recording. Rehearse the switch to backup as a calm, ten-second move, not an improvisation.

**Logistics:** travel and accommodation are self-funded. One member may represent the team.

## E.7 Questions to email the organisers (ab@indehub.org) — send immediately

1. ★ **May the finalist build differ from the build submitted on 7 August?** The "no new build, video, feature or clarification" rule is written under _Online semifinals_, and the finale is twelve days after finalists are announced. **If yes, the 7 August submission should be scoped purely to survive the asynchronous rounds, and deferred work lands before 22 August. This single answer changes §6 and §6.9.**
2. Is there a maximum video length or file-size limit?
3. Is supporting material (a one-page PDF, screenshots) accepted alongside the video, and is it scored? The rubric refers to "permitted supporting material" without defining it.

## E.8 Contingency — variant B if the model is unavailable at recording time

Do not fake it and do not hide it. Replace the 2:15–2:35 beat with:

> _"Egress separates its safety spine from its intelligence layer. Everything you have seen — the physics, the thresholds, the verdict — is deterministic and always works. On an Apple-Intelligence-capable device the on-device model turns these numbers into plain-language coaching; here you are seeing the deterministic fallback, which is what every user gets when the model is not available. Same interface, same numbers, different words."_

Then show the canned RALLY card and continue to the Apply & re-run payoff, which is engine-side and unaffected. This costs the Pocket-Brain showcase but keeps the demo honest and the product intact — and graceful degradation is itself criterion 02 evidence. **Use only as a last resort; R-03 is retired at S0 so that it never arises.**

## E.9 README — collapsed

**Source code is not submitted and no judge reads the repository.** "Documentation volume" earns nothing. Keep a short internal README (setup, how to run, pinned toolchain build numbers, test invocation) for the team's own use, and put everything a judge needs into the submission form fields instead. The elaborate public README of v2 §E.5 is **deleted**.

---

# F. SWIFT LEARNING NOTES · DISCIPLINE · DEFINITION OF DONE

## F.1 How to use these notes

Two devs, intermediate programmers, new to Swift, learning **while** shipping. The rule that makes that safe: **learn the concept the day before you need it, not the day you're stuck.** Each stage below lists the minimum Swift surface required for that stage's tasks — deliberately _minimum_. Anything not listed is not needed yet, and chasing it is scope creep in disguise.

Verification is per stage and concrete: if you cannot answer the "check yourself" question without looking it up, you do not understand the code you are about to ship — which is exactly what the explain-back review catches.

## F.2 Per-stage learning map

| Stage               | Days    | Dev | Swift / SwiftUI surface                                                                                                                                                        | Where it appears in Egress                          | Newcomer trap                                                                                                        | Check yourself                                                            |
| ------------------- | ------- | :-: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| **S1 Foundations**  | D1–D2   |  A  | `struct` versus `class`, **value semantics**, `let` / `var`, optionals with `if let` / `guard let`, `enum` with associated values, `Codable`, computed properties              | `Vec2`, `GridCoord`, `VenueType`, `SafetyStandards` | Assuming a `struct` passed to a function can be mutated by it                                                        | Why does mutating a copied `VenueModel` not affect the original?          |
|                     | D1–D2   |  B  | A SwiftUI view is a **value**, not an object; `body` recomputation; `@State`, `@Binding`; `TabView` / `NavigationStack`; view modifiers return new views                       | App shell, `ColorTokens`, `Motion`                  | Thinking `body` runs once, or storing mutable state in a plain `var` on a `View`                                     | Why does a plain `var` on a `View` reset every redraw?                    |
| **S2 Algorithms**   | D3–D5   |  A  | `Array` performance and `reserveCapacity`, `ContiguousArray`, index-based loops, `inout`, `simd` operators, generics basics, custom `Comparable` for a heap                    | `FlowField` Dijkstra, `SpatialHash`, social force   | `[[Int]]` nested arrays in a hot loop; `enumerated()` inside per-frame code                                          | What is the cost of appending to an array you did not reserve?            |
|                     | D3–D5   |  B  | `Canvas` with `GraphicsContext`, `TimelineView(.animation)`, `GeometryReader`, coordinate spaces, `DragGesture` / `MagnifyGesture`, `SimultaneousGesture`                      | `SimCanvasView`, camera, gestures                   | Doing layout work per frame inside `Canvas`; fighting gesture composition instead of composing it                    | Why is `Canvas` faster than 200 `Circle()` views?                         |
| **S3 State & data** | D6–D9   |  A  | Protocols and protocol witnesses, `some` / `any`, error handling with `throws`, `Result`, access control (`public` versus `internal` — the package boundary is enforced by it) | Engine public API surface, `VerdictRules`           | Marking everything `public`; the package boundary only holds if you are deliberate                                   | Why does the app fail to compile if it touches an `internal` engine type? |
|                     | D6–D9   |  B  | **`@Observable`** (Observation), `@Environment`, `@Bindable`, sheets with `presentationDetents`, `ViewThatFits`, `@ScaledMetric`                                               | Editor, tool sheet, Results, HUD                    | Using `@Published` / `ObservableObject` habits from older tutorials — this project uses **Observation**, not Combine | What causes a view to re-render under `@Observable`?                      |
| **S4 Concurrency**  | D10–D11 |  A  | `async` / `await`, `Task`, `TaskGroup`, **actor isolation**, `@MainActor`, `Sendable`, `Task.checkCancellation()`, `AsyncStream`                                               | Monte Carlo, audio setup                            | **The big one — see §F.3**                                                                                           | Why can a `@MainActor` type not be constructed inside `Task.detached`?    |
|                     | D10–D11 |  B  | `async` in SwiftUI (`.task`), structured output decoding, streaming updates to the UI, avoiding `MainActor.run`                                                                | `CoachingService`, RALLY streaming                  | Awaiting on the main actor and freezing the sim loop                                                                 | Where exactly does the model call hop off the main actor?                 |
| **S5 Polish**       | D12–D15 |  A  | `AVAudioEngine` node graph, Swift Charts marks, PDFKit drawing, memory and retain cycles (`[weak self]` in closures and handlers)                                              | Audio, charts, PDF                                  | Strong-capture cycles in audio and haptic engine handlers → leaks                                                    | Which closures in `AudioEngine` need `[weak self]`, and why?              |
|                     | D12–D15 |  B  | Accessibility modifiers, `@Environment(\.accessibility*)`, `.symbolEffect`, `ScenePhase`                                                                                       | Accessibility pass, motion, lifecycle               | Adding labels without testing with VoiceOver actually on                                                             | Can you complete the whole loop with the screen curtain on?               |

## F.3 Swift 6 strict concurrency — the crash course (read on D1, not D10)

This is the single largest source of confusing compiler errors for newcomers, and it is the area where AI-generated code most often produces something that compiles under Swift 5 mode and fails under Swift 6.

| Concept                           | What it means here                                                                                 | Rule for this project                                                                                                                                     |
| --------------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Isolation**                     | A type marked `@MainActor` can only be touched from the main actor.                                | Only _UI-facing_ types are `@MainActor`. **`Simulation` is not** — it is a plain class used from exactly one context at a time.                           |
| **`Sendable`**                    | Safe to hand across isolation boundaries. Value types of `Sendable` members qualify automatically. | Every type crossing engine → UI (`SimulationSnapshot`, `VenueModel`, `Metrics`, `Verdict`) is a `Sendable` value type. That is why the boundary is clean. |
| **Compile-time data-race safety** | The compiler rejects shared mutable state across actors.                                           | If you are fighting the compiler, the design is usually wrong: pass a _copy_ (a snapshot); do not share the simulation.                                   |
| **`nonisolated`**                 | Opts a member out of its type's isolation.                                                         | Use sparingly, and only on pure functions.                                                                                                                |
| **`Task` versus `Task.detached`** | Structured versus unstructured; detached inherits nothing.                                         | Monte Carlo uses `withTaskGroup`, and each child builds its **own** `Simulation`. Never share one.                                                        |
| **Cancellation**                  | Tasks must check it to actually stop.                                                              | Monte Carlo checks `Task.isCancelled` every N steps and on scene backgrounding.                                                                           |

> **The mental model to carry:** the engine is a fast, single-threaded machine; concurrency exists only to run _several independent copies_ of it (Monte Carlo) and to keep the UI responsive. There is **no shared mutable simulation state anywhere** — that design choice is what makes Swift 6 strict concurrency painless instead of painful.

## F.4 Swift 6.4 conveniences worth adopting (and what to skip)

| Feature                                            | Use it?                    | Why                                                                                                                           |
| -------------------------------------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `anyAppleOS` availability shorthand                | 🟡 **skip**                | iPhone-only — one platform, so `@available(iOS 27, *)` is already minimal                                                     |
| Optional `any` / `some` without parentheses        | ✅ yes                     | Free readability in the `CoachingService` protocol surface                                                                    |
| `@diagnose` per-declaration warning control        | ⚪ only if needed          | Useful to silence one known-noisy warning; never to hide real ones                                                            |
| Module selectors (`::`)                            | ⚪ unlikely                | Only if `EgressEngine` and the app collide on a type name — prefer renaming                                                   |
| `UniqueArray` / borrow-based `Iterable`            | 🟡 **skip for v1**         | Real performance tools, but ownership semantics are a poor first-week Swift topic. Revisit only if profiling at G1 demands it |
| `async` cleanup in `defer`                         | ✅ if it fits              | Handy for audio and haptic engine teardown                                                                                    |
| **Swift Testing** (`@Test`, `#expect`, `#require`) | ✅ **yes, as the default** | The recommended framework; XCTest interop exists if needed. All engine tests use it                                           |

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

| Rule                                                                                 | Mechanism in this project                                                                                                                                                                                                    |
| ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Smallest end-to-end path first**                                                   | G1 walking skeleton: launch → spawn → path → evacuate. No editor, no hazards, no UI polish until that runs on device.                                                                                                        |
| **Inspect before building; preserve existing work**                                  | Greenfield here, so this becomes: do not rewrite a passing module to make it prettier mid-sprint.                                                                                                                            |
| **Reuse sound code; native Swift naming**                                            | Engine API names are locked in §A.3 — use them verbatim so both devs read the same vocabulary.                                                                                                                               |
| **Small increments; report what changed · what was verified · next action**          | The daily standup format, literally these three fields.                                                                                                                                                                      |
| **Compile and test after each meaningful increment**                                 | The green-main rule; `swift test` green before every merge.                                                                                                                                                                  |
| **An honest local seam when blocked**                                                | `MockSimulation` (D2) and `CannedCoach` (D10) are both real seams — documented and shipped, not hacks. Demo mode is separated and disclosed.                                                                                 |
| **Do not declare success until it compiles and the primary flow has been exercised** | Gate criteria are all "on the physical iPhone 16", not "builds clean".                                                                                                                                                       |
| **AI-generated code is untrusted until reviewed, compiled and tested**               | **Explain-back review**, daily, 20 minutes: each dev walks the other through their diffs; anything neither can explain is rewritten or deleted. This is the enforcement mechanism for "the team must understand every line". |

## F.8 DEFINITION OF DONE — v3 final checklist

Confirm every row before submitting. Verified on the **physical device**, from a **clean install**. Grouped by the criterion each row defends, because that is what it is for.

### Criterion 01 · Problem and user value (20)

- [ ] One specific user and situation is stated in one sentence, and the demonstrated journey addresses it directly.
- [ ] **At least one product decision traceably reflects a real conversation with a real venue operator**, and is named as such. Criterion 01 gives zero for "generic personas or invented research" — replace the persona with two conversations (§F.9).
- [ ] **Apply & re-run works**: the coach names a geometry fix, the user applies it, the re-run scores measurably better, and both scores are visible together. This is the criterion's "credible outcome visible in the build".
- [ ] No market-size claim appears anywhere.

### Criterion 02 · Working product and technical execution (25 · tie-break #1)

- [ ] Primary journey works from a clean launch — no hidden setup, no manual steps, no pre-warmed state.
- [ ] Launch → design → simulate → verdict → fix → re-run completes without a crash, **three consecutive times**, in airplane mode.
- [ ] **Every state in §E.2 exists and is reachable**: empty, loading, offline, unavailable-feature, failure/degradation, paused-on-return.
- [ ] ⚠️ The permission row says **"Egress requests no permissions and holds no network entitlement"** — verified in Xcode. The v2 claim about a denied motion permission is removed; shake and accelerometer access do not prompt on iOS.
- [ ] Full test suite green: determinism, flow-field correctness, integrator stability, metrics, score worked examples, verdict branches, **faster-is-slower**, V1–V8 validation fixtures.
- [ ] 60 fps target met (55 floor) at the shipped agent count; 30-minute soak with no crash, no unbounded memory growth, thermal below `.serious`.
- [ ] Every measurable value displays in real SI units with its unit shown.
- [ ] **No unnecessary infrastructure remains** — Monte Carlo, ring buffer, Metal glow, audio bus graph and PDFKit are gone, not commented out.
- [ ] Limitations are stated honestly in-app, in the form, and spoken in the video.

### Criterion 03 · Apple-platform craft (20)

- [ ] Every iOS-27 API is availability-gated and its fallback is the default path; removing any single gated feature breaks nothing.
- [ ] **Nothing is claimed that does not run on the demo device.** The technologies field, the video, and the voiceover list only what a judge can watch working.
- [ ] The on-device coach runs in airplane mode, and the forced-fallback run produces an identical layout with canned lines.
- [ ] No decorative WWDC26 adoption remains as a deliverable.
- [ ] Toolchain pinned; the final archive built from the pin.

### Criterion 04 · Experience design and accessibility (15)

- [ ] **VoiceOver completes the primary journey end to end with no dead end** — parametric authoring included, not routed around.
- [ ] The sim canvas is a single accessibility element with a meaningful spoken summary, not 150 unlabelled children.
- [ ] Verdict reasons are read with their units.
- [ ] Reduce Motion, Reduce Transparency and Differentiate Without Color verified.
- [ ] Dynamic Type to AX5 with no truncation on reading surfaces.
- [ ] Contrast audited with Accessibility Inspector; all text at or above WCAG AA.
- [ ] No state signalled by colour alone; no safety event signalled by audio or haptic alone.
- [ ] 44 × 44 pt minimum on every control.

### Criterion 05 · Originality and product judgment (10)

- [ ] The cuts in §6.9 are visible as discipline, not absence — the shipped product is coherent, and nothing half-built is on screen.
- [ ] The distinctive claim is demonstrable in one sentence: _the crowd's competence degrades with its perception, so clutter becomes dangerous exactly when the smoke arrives._

### Criterion 06 · Demonstration evidence (10 · gates everything above)

- [ ] The core journey is **one unbroken take**.
- [ ] Voiceover throughout; **no unexplained taps** (touch-indicator overlay on).
- [ ] `FUNCTIONAL / DEMO DATA / NOT BUILT` labels applied wherever relevant.
- [ ] The **timestamp index** is written into the form's judging-instructions field.
- [ ] Airplane mode visible in the status bar throughout.
- [ ] A complete usable take existed before the final day (R-19).

### Eligibility and hygiene (pass/fail)

- [ ] **Team registered before 31 July, 11:59 PM IST.**
- [ ] Native Apple client; no cross-platform or web wrapper.
- [ ] One project, one track.
- [ ] **No secrets, keys or sensitive test data committed** (scan run, result recorded).
- [ ] Third-party dependencies: none — stated explicitly.
- [ ] AI development-tool usage disclosed; all submitted code reviewed, compiled and tested.
- [ ] All pixel art and audio original; no copyrighted assets.
- [ ] Submitted **before** the deadline, not at it.

## F.9 The cheapest twenty points in the plan — two conversations

Criterion 01 is worth 20 points and is tie-break #2, and its exclusion list names **"generic personas or invented research"**. "Small-venue operator / event organiser" is currently a persona.

**Spend one afternoon.** Talk to two real operators in Bengaluru — a pub or restaurant manager, a co-working or event space. Ask three questions: what do you actually do today about capacity and exits; what would you have to show a fire officer; what would make you open an app like this twice. Take **one concrete constraint** from those conversations and let it visibly shape a product decision — a default value, a unit, a preset, a piece of wording. Then say so, in one sentence, in the video and in the form.

Cost: about three hours. It converts criterion 01 from _asserted_ to _supported by the demonstrated journey_, and it is the one finale question — _"who did you build this for?"_ — that no competing team will be able to answer with a name.

# APPENDIX 1 — APPLIED PATCH LOG

Every PATCH emitted during Phases 1–8 that targets a section of this file, with its effect. All are **already applied inline above** — this table is provenance, not a to-do list.

| ID           | Issued  | Target                    | Change                                                                                                                                                                                                                                                                                                                |
| ------------ | :-----: | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P1a**      | Phase 1 | §0.4 "Selected platforms" | Rewritten to iPhone-only; iPad, Pencil, macOS, visionOS, Watch and TV explicitly out of scope                                                                                                                                                                                                                         |
| **P1b**      | Phase 1 | §0.4 tech table           | `NavigationSplitView` row replaced with `TabView` + `NavigationStack` (iPhone-only)                                                                                                                                                                                                                                   |
| **P1c**      | Phase 1 | §0.4 tech table           | PencilKit / PaperKit row deleted                                                                                                                                                                                                                                                                                      |
| **P5a**      | Phase 5 | §3.6 audio vocabulary     | Added `sfx_ui_confirm` (export / save complete, max 1 per 2 s)                                                                                                                                                                                                                                                        |
| **P5b**      | Phase 5 | §4.3 layout diagram       | Scrubber annotation now states both modes (live progress versus post-run seek)                                                                                                                                                                                                                                        |
| **P5c**      | Phase 5 | §4.6 RALLY placement      | Added the reachability rule (44 pt pill in the natural thumb zone)                                                                                                                                                                                                                                                    |
| **PATCH-01** | Phase 8 | §A.3, §A.7                | ⚠️ **Load-bearing fix.** `Simulation` was declared `@MainActor` while Monte Carlo instantiates it off-main — mutually exclusive under Swift 6 strict concurrency, and it would have surfaced as a compiler error around D10. `Simulation` is now a plain `final class` with an explicit single-context isolation rule |
| **PATCH-02** | Phase 8 | §A.3, §2.9, §2.10         | Preset agent counts of 250–350 exceeded the 200-agent count validated at G1/G2. Added `maxValidatedAgents` (default 200); all presets clamp on load; above-budget counts show a HUD notice; the demo never exceeds the budget                                                                                         |
| **PATCH-03** | Phase 8 | §4.9, scope               | The isometric Engineering Sandbox view had no allocated day. Cut to Stretch and unscheduled; the `cube.transparent` toggle removed; the cyan dimension overlay carries the engineering identity instead. Crowd theme packs likewise Stretch                                                                           |
| **PATCH-08** | Phase 8 | §6.5 (D12)                | A half-day rest had been scheduled against a full day of work. D12 is now morning-only work for both devs, with SFX assets and scrubber replay-seek moved to D13                                                                                                                                                      |

| **PATCH-09** | User req. | §2.13 (new), §A.3, §A.4, §3.3, §3.5.2, §3.5.3, §3.6, §6.4–6.6, §D, §E.2 | **Obstacle interaction, NPC behavioural intelligence and expressive emotion.** Adds: furnished-by-default venues with `Obstacle.isRelocatable`; anticipatory dodge steering gated by `awareness_eff`; bump / stumble / obstacle memory; obstacle-derived aisle clear-width analysis (reusing `FlowField.wallDist`) surfacing as WARN reason 4d and `MetricKey.aisleClearWidth`; a display-only expressive emote layer; fire and water as editor-placeable hazard props via the existing `HazardSeed`. Records the **no-LLM-per-agent** decision. Funded by demoting Monte Carlo in the cut order. New risks R-17 and R-18 |

**Consistency items verified clean (no patch needed):** the Safety Score worked examples reproduce exactly (Concert Crush = 7, Office = 98); `SIM_TIME_CAP` matches `clamp(3 × target, 300, 600)` for all six venues; the §3.2 disagreement band is arithmetically 5.0–6.0 p/m² as stated; ring-buffer sizings (2.4 MB and 12 MB) are correct at 4 bytes per agent per 10 Hz frame and stay under the 16 MB cap for every venue at its time cap; verdict rule 2 is reachable (maximum non-casualty penalty 60 → score 40); the escalation cooldown is stated identically in §3.1, §3.3 and §5.5; every fallback in §6.9 is scheduled earlier than its enhancement.

---

# APPENDIX 2 — AMENDMENTS TO THE MASTER PROMPT REQUIREMENT BLOCKS

These PATCHes target the source prompt's `[R-*]` blocks rather than this file. They are recorded here so the plan and the prompt stay reconciled.

| ID       | Target block                           | Amendment                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| -------- | -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A-01** | `[R-CONTEXT]` build window             | "22 July – 7 Aug 2026" is **17 calendar days (D1–D17)**, not 16.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| **A-02** | `[R-STACK]` SwiftUI line               | `NavigationSplitView` → **`TabView` + per-tab `NavigationStack`** for the iPhone-only scope.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| **A-03** | `[R-STACK]` audio line                 | Session is `.ambient` with `.mixWithOthers`; the silent switch is respected and the user's audio is never interrupted. **No background-audio mode** — Egress has no reason to play while backgrounded, and claiming that capability would be an unjustified entitlement.                                                                                                                                                                                                                                                                                                                                                                                         |
| **A-04** | `[R-WWDC26]` `appearsActive` row       | **Dropped.** That refinement dims custom glass cards when a window is inactive — an iPad/macOS multi-window concern with no meaning at iPhone-only scope; adopting it would be scorecard-chasing. The automatic Liquid Glass refresh is retained.                                                                                                                                                                                                                                                                                                                                                                                                                |
| **A-05** | `[R-WWDC26]` beta discipline           | The single demo device runs **stable iOS 26**, not the iOS 27 beta. The Must and Should tiers are entirely iOS-26-capable, so a beta OS would risk the whole submission for Stretch-tier features only. Build toolchain unchanged (Xcode 27 / Swift 6.4 / iOS 27 SDK). Pin on Aug 3. If a second device is available it takes the beta and the Stretch showcase.                                                                                                                                                                                                                                                                                                 |
| **A-06** | `[R-VISUAL]` item 1                    | `hazard.flood` is `#1E63D6`, deliberately deeper than `accent.cyan` `#4FD8FF`, so water never reads as a dimension line. Cyan is reserved exclusively for measurement and carries no safety semantics.                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| **A-07** | `[R-VISUAL]` item 3                    | The isometric extruded-wall sandbox is **cut to Stretch and unscheduled**; the app ships the top-down Sim View plus the cyan dimension overlay. A static isometric thumbnail is the cheap version if G3 lands early.                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| **A-08** | GLOBAL RULES MoSCoW                    | **Must** = drawn rooms + crowd sim + emotions + fire + score + verdict banners with canned messages. **Should** = flood, Monte Carlo, A/B compare, mascot with AI coaching and jokes, retro SFX, quiz, Liquid Glass polish. **Stretch** = AI heatmap debrief, apply-&-re-run, widget / Siri, `.egress` sharing, isometric thumbnail. **Cut entirely: RoomPlan** (no LiDAR on the demo device), **Pencil authoring, iPad and macOS reach**.                                                                                                                                                                                                                       |
| **A-10** | `[R-VISUAL]` item 4 · `[R-SIM]` item 2 | Props are not optional dressing: **every System Preset ships furnished**, and an empty rectangle is never a shippable venue. Props gain `isRelocatable`, distinguishing movable furniture from structural elements the coach may never propose relocating. Agents actively **dodge** obstacles (predictive steering gated by awareness) and **collide** with them when perception fails, with stumble, arousal spike and obstacle memory. Emotional expression is extended beyond "?" and "!" with a **display-only** reaction-emote layer that never touches the physics. Fire and water become **editor-placeable hazard props**. Full specification in §2.13. |
| **A-09** | SECONDARY FEATURES                     | The "daily drill" notification and widget are **out of scope** — no notification permission, scheduling or WidgetKit extension is planned or built. Shipping a permission prompt for a feature that does not exist would violate the Definition of Done. Real-incident case studies are governed by §D.1.                                                                                                                                                                                                                                                                                                                                                        |

---

# APPENDIX 3 — VERIFICATION REGISTER (RESOLVE AT S0)

Every load-bearing claim tagged 🔴 or 🟡 across the plan, in one place. **S0 exit requires each 🔴 to be resolved to ✅ or replaced by its named fallback.**

|  #  | Item                                                                                                                         | Tag | How to verify                                                   | Fallback if it fails                                                                                           |
| :-: | ---------------------------------------------------------------------------------------------------------------------------- | :-: | --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
|  1  | `@Generable` / `@Guide` constraint spellings (`.count`, `.range`, description form)                                          | 🔴  | Compile the §3.5.2 schemas in Xcode 27                          | Plain `@Generable` structs with prompt-level constraints plus stricter V1–V8 checks                            |
|  2  | SwiftUI Metal shader modifier names (`.colorEffect` / `.layerEffect` / `.distortionEffect`)                                  | 🔴  | Xcode autocomplete plus a trivial shader                        | Plain SwiftUI gradients and fills for glow and smoke                                                           |
|  3  | `ConcentricRectangle` / `.rect(corner:)`                                                                                     | 🔴  | Xcode autocomplete                                              | `RoundedRectangle(style: .continuous)` (already the shipping default)                                          |
|  4  | `gauge.medium` symbol string                                                                                                 | 🔴  | SF Symbols 7 app                                                | `gauge`                                                                                                        |
|  5  | `play.rectangle.fill`, `cube.fill`, `water.waves`, `cross.case.fill`, `door.left.hand.closed`, `figure.roll`, `figure.child` | 🟡  | SF Symbols 7 app                                                | `play.fill`, `square.fill`, `drop.fill`, `bandage.fill`, `door.left.hand.open`, `figure.stand`, `figure.stand` |
|  6  | `SystemLanguageModel.availability` result on the demo device                                                                 | 🔴  | **Run on the physical iPhone 16, D1**                           | `CannedCoach` plus demo script variant B (§E.6) — and escalate                                                 |
|  7  | Whether Low Power Mode suppresses haptics on iPhone 16                                                                       | 🟡  | Toggle Low Power Mode, fire each pattern                        | The visual twin already covers every haptic                                                                    |
|  8  | `AccessibilityNotification.Announcement` priority API spelling                                                               | 🟡  | Xcode autocomplete plus a VoiceOver test                        | Post plain announcements with manual throttling                                                                |
|  9  | iPhone 16 safe-area insets (59 / 34 pt) and thumb-zone boundaries                                                            | 🟡  | Simulator plus on-device measurement                            | Read insets dynamically from `GeometryReader`; never hard-code                                                 |
| 10  | Contrast ratios in the §4.8 token table                                                                                      | 🟡  | Accessibility Inspector on device                               | Darken or lighten the token until AA passes                                                                    |
| 11  | QuickTime USB capture frame rate at 60 fps                                                                                   | 🟡  | **Test at G4, not on D16**                                      | On-device Screen Recording, accepting the extra load                                                           |
| 12  | Swift 6.4 syntax specifics in §F.4                                                                                           | 🔴  | Compile each before relying on it                               | Use the Swift 6.0-era equivalent; none is load-bearing                                                         |
| 14  | §2.13.10 dodge, bump and emote constants                                                                                     | 🟡  | Playtest at D10; the §2.13.11 stability and no-tunnelling tests | `A_DODGE = 0` reverts to the G1/G2-validated behaviour (R-17)                                                  |
| 15  | Furnished presets still reproduce the §2.8 worked examples (Office = 98 / PASS)                                              | 🔴  | Preset regression test at **G2**, run after prop authoring      | Re-author the offending prop layout to clear the aisle minimum                                                 |
| 13  | All numeric constants in `SimConstants` (force coefficients, hazard rates, score weights)                                    | 🟡  | Playtest tuning; the faster-is-slower test at G2                | Raise `K_FRIC` / `K_BODY`; hand-tune the Nightclub preset (R-09)                                               |

---

_End of `EGRESS_PLAN.md`. Planning complete through Phase 8; the build begins at D1 (22 July 2026). The first item on the critical path is the Day-1 Apple Intelligence availability spike — the one open risk that could still change the track._

---

# APPENDIX 4 — v3 RUBRIC REVISION LOG

Every change made on 29 July 2026 when the plan was revised against IndeHub Rubric v1.0 and the Hacker Guide.

| ID        | Section         | Change                                                                                                                                                                        | Rubric justification                                                                                                                                                                                              |
| --------- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **V3-01** | Header, §0.1 #4 | Hard dates added; registration deadline elevated to a pass/fail banner; deliverable corrected to **video only, submission 7 Aug, finale 22 Aug**                              | Eligibility is pass/fail and checked before scoring                                                                                                                                                               |
| **V3-02** | New §R          | Scoring model added: the 0–5 dial, the 60/100 all-3s trap, the tie-break ordering, criterion 06 as a multiplier, the exclusion list mapped to v2 items                        | Governs every trade below                                                                                                                                                                                         |
| **V3-03** | §0.1 #10        | The "Smaller Version" is **promoted from fallback to plan**                                                                                                                   | "Prefer a narrow, complete vertical slice"; criterion 02 penalises incomplete core journeys                                                                                                                       |
| **V3-04** | New §0.2.1      | Pocket Brain **essentiality** tension stated and resolved — argue on user-facing grounds, never overclaim                                                                     | Overclaiming is punished by criteria 02, 03 and 06                                                                                                                                                                |
| **V3-05** | §2.13.12        | Re-tiered: dodge, stumble and aisle analysis **promoted to Must**; obstacle memory, expressive emotes and stall re-decision **cut**                                           | Criterion 02 "claims directly demonstrated" over invisible refinements                                                                                                                                            |
| **V3-06** | §3.6            | Audio reduced to **three cues**; the five-bus `AVAudioEngine` graph cut                                                                                                       | "Unnecessary architectural complexity"                                                                                                                                                                            |
| **V3-07** | §5.3            | Replay-seek and the **16 MB snapshot ring buffer cut**; live progress only                                                                                                    | Real engineering for an affordance a re-run reproduces free on a deterministic engine                                                                                                                             |
| **V3-08** | §5.6            | ★ **The parametric editor becomes the primary authoring path**; freehand demoted to optional                                                                                  | One path instead of two; deletes the criterion 04 accessibility gap rather than disclosing it; more credible for the stated user; makes Apply & re-run nearly free; removes a hands-on failure mode at the finale |
| **V3-09** | §6 (whole of B) | Calendar D1–D17 replaced by **dependency-ordered stages S0–S5** with exit criteria; Rule 1 (core journey first) and Rule 2 (evidence outranks features after S2) added        | A drifted schedule is worse than none; criterion 06 gates 01–04                                                                                                                                                   |
| **V3-10** | §6.5            | **Apply & re-run promoted from Stretch to Must**                                                                                                                              | The only thing that converts a claimed benefit into criterion 01's "credible outcome visible in the build"                                                                                                        |
| **V3-11** | §6.9            | Cut order rewritten; everything through "symbol effects" **deleted rather than deferred**; the floor now includes the states matrix, the accessibility pass and the recording | Criterion 05 rewards "deliberate omissions that protect the core experience"                                                                                                                                      |
| **V3-12** | §6.11           | WWDC26 adoption table deleted as a goal; only device-functional APIs may be claimed                                                                                           | Criterion 03: mentioning a non-functional API earns zero                                                                                                                                                          |
| **V3-13** | §D.0            | R-16 raised to H impact; **R-19 (evidence single-point-of-failure)** and **R-20 (hands-on failure at the finale)** added                                                      | Video-only, unreplaceable after the deadline                                                                                                                                                                      |
| **V3-14** | §D.1            | **R-15 retired** — real-incident case studies cut entirely                                                                                                                    | Off the core journey, reads as documentation volume, highest reputational risk in the plan                                                                                                                        |
| **V3-15** | §E.2            | States and recovery promoted from a DoD checklist row to **shipped features with screen time**; the AI fallback is triggered deliberately on camera                           | Criterion 02 names these states explicitly and rewards visible recovery                                                                                                                                           |
| **V3-16** | §E.2            | ⚠️ **Correction:** the v2 "motion permission denied" state is removed — shake and accelerometer access do not prompt on iOS                                                   | Inventing a permission state is exactly the unverifiable claim criterion 02 punishes                                                                                                                              |
| **V3-17** | §E.3            | Video restructured around **one unbroken take** of the core journey, plus a states reel, audible VoiceOver and spoken limitations; voiceover chosen over presenter PiP        | An unbroken take is self-authenticating; charisma earns nothing                                                                                                                                                   |
| **V3-18** | §E.4            | The submission form treated as a scored artifact; **timestamp index** written into the judging-instructions field                                                             | Criterion 06 "does the evidence cover the claims that matter"; suppresses the ≥15-point split that triggers a third reviewer                                                                                      |
| **V3-19** | §E.6            | Finale treated as a **separate artifact**: 5 + 5 format, rehearsed verification menu, failure protocol, hands-on-safe build                                                   | Finale scores start fresh; judges may request device access                                                                                                                                                       |
| **V3-20** | §E.7            | Three questions to the organisers, led by **"may the finalist build differ from the submitted build?"**                                                                       | A twelve-day gap whose rules are ambiguous; the answer changes §6 and §6.9                                                                                                                                        |
| **V3-21** | §E.9            | Public README **deleted**; content moved into the form fields                                                                                                                 | Source code is not submitted; documentation volume earns nothing                                                                                                                                                  |
| **V3-22** | §F.8            | Definition of Done regrouped **by criterion**, so each row defends a specific score                                                                                           | Makes the checklist an instrument rather than a ritual                                                                                                                                                            |
| **V3-23** | New §F.9        | Two real operator conversations added as a required input                                                                                                                     | Criterion 01 gives zero for generic personas or invented research                                                                                                                                                 |

**Superseded by v3:** §0.1 #4 and #10 · §2.13.12 tiering · §3.6 audio graph · §5.3 replay mode · §5.6 freehand-primary decision · the whole of §B (D1–D17, gates G0–G5, §6.6 ladder, §6.9 adoption table) · §D.1 · the whole of §E · §F.8. **Everything else in this document stands unchanged.**

---

_Egress Build Plan v3 · rubric-aligned 29 July 2026 · IndeHub Rubric v1.0 (freezes 1 Aug 2026)._
