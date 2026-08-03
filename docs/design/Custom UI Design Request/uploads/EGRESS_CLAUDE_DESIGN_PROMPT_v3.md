# CLAUDE DESIGN PROMPT — "EGRESS" iOS APP UI  ·  v3

*(Paste everything below into Claude Design. Attach all reference screenshots alongside it — they are mapped in §2.)*

> **What changed in v3:** the build plan gained §2.13 — furnished venues, anticipatory dodging, collisions, aisle clear-width analysis, editor-placeable hazards, and a six-glyph expressive emote layer. Rooms are no longer empty boxes, so the world layer is now a first-class design surface. New/changed sections are marked **🆕**.

---

## 0. ROLE & DELIVERABLE

Design the complete high-fidelity mobile UI for **Egress**, a shipping-quality iOS app. Produce **pixel-accurate iPhone 16 frames (393 × 852 pt)**, a design-system frame, and two sprite sheets. Portfolio-grade — a real product, not a concept sketch.

**Design the Sim Canvas mid-escalation and the Editor first.** Every other screen inherits its language from those two.

---

## 1. PRODUCT CONTEXT

**Egress** is an offline, 100% on-device crowd-evacuation simulator for iPhone. The user draws or opens a **furnished** venue, populates it with simulated people, triggers an emergency, and watches a physics-based crowd try to get out. The app then delivers a verdict grounded in published crowd-safety thresholds.

**Core loop: Design → Simulate → Verdict.** Every screen serves one of those three beats.

- The grid is **0.25 m per cell**. Everything on canvas is metrically true. This is an **engineering instrument that happens to look like a game** — never a game pretending to be engineering. That sentence governs every decision below.
- Permanent disclaimer on Results, in Settings, and in the exported report: **"Educational analysis, not certified engineering advice."** Never imply certification, compliance, or approval.
- The mascot is a **coach** — never an inspector, marshal, or authority.
- No network, no account, no cloud. Design nothing implying one: no sync badges, no avatars, no login, no pull-to-refresh.

**🆕 The crowd is intelligent, and that must read visually.** Agents anticipate obstacles and swerve *early* when they can see; when smoke blinds them or panic takes over, they clip the furniture and stumble instead. Nothing about that is scripted — it emerges from perception. The design's job is to make that legible: furniture must look solid, paths must look deliberate, and collisions must look like consequences.

**Tone:** calm, credible, precise. Retro craft in the *world*; drafting-room discipline in the *chrome*.

---

## 2. REFERENCE MAP — WHAT TO TAKE FROM EACH SCREENSHOT

Each reference contributes a specific layer. **Take only what is listed; leave the rest.**

| Reference | TAKE THIS | LEAVE THIS |
|---|---|---|
| **A — Grocery app (cream/editorial)** | The **typographic voice and compositional restraint**: heavy condensed all-caps display headings; tiny letterspaced uppercase micro-labels for metadata; hairline rules instead of card shadows; flat matte surfaces; enormous breathing room; **a single accent colour used only on numerals**; a flat tab bar with one tinted active state. | The cream palette as the app-wide ground (see §5.1 for where warmth *is* allowed), the pencil-sketch medium, and the e-commerce layout patterns. |
| **B — Egress mockup set** | The **character craft and screen layout**: chunky expressive pixel sprites; the green-tinted robot coach; the Results section stack; the Spaces card anatomy; the monospace technical voice (`TOOL: Draw Wall`, `HIGH_DENSITY`, `1 PIXEL BLOCK = 0.25 m × 0.25 m`); the seven-segment score numeral. | Blue playback buttons (not in the palette); photographic thumbnails; the legged two-eyed robot (§9 governs); the solid tan alert card; **the empty unfurnished room** — §7 now governs. |
| **C — Isometric "Engineering Sandbox"** | The **dimension-annotation language only**: cyan extension lines with fine arrowheads, rotated labels riding the geometry, `Width: 2.0 m` / `Length: 4.25 m` / `Clear Exit Width: 1.2 m`, the scale caption chip, selection handles. | **The isometric 3-D editing mode itself** — cut from the product (top-down only). One static isometric frame is permitted as a marketing/thumbnail asset, clearly labelled. |
| **D — Top-down Metro Platform B** | The **canonical Sim Canvas**: glass HUD pill with `EGRESS │ venue ⌄ │ 60 FPS │ 312 Agents │ t + 14.2s │ ⚙`; edge-to-edge tiled floor with pixel crowd streaming toward an exit; a floating rounded tool bar; the selected-element handle box. | The blown-out orange fire bloom — far too hot. Bring hazards to the §5 opacities. |

> **A gives it the voice. B gives it the characters and the bones. C gives it the engineering credibility. D gives it the stage.**

---

## 3. AESTHETIC DIRECTION

### 3.1 Concept

**A drafting-room datasheet that a 16-bit crowd lives inside.**

Editorial-technical typography and hairline structure — the calm of a well-set printed spec sheet — wrapped around a dark blueprint canvas where chunky, readable pixel people move through real furniture. Advance Wars / Game Boy Color clarity in the sprites; Swiss print discipline in the chrome.

### 3.2 THE LOAD-BEARING RULE — where pixels live

> **The simulated world is pixel art. The interface around it is not.**

| Layer | Treatment |
|---|---|
| **World** — crowd agents, RALLY, **props and furniture**, decor tiles, fire/smoke/flood sprites, hazard seeds, exit and obstacle glyphs, venue thumbnails | **Pixel art.** Hard edges, nearest-neighbour scaling, zero anti-aliasing, no soft shadows, limited palette per sprite. |
| **Chrome** — HUD, sheets, cards, chips, buttons, tab bar, all body copy, all readouts | **Modern iOS.** Glass/frosted material, native type, SF Symbols, continuous-corner squircles, 1 pt hairlines. |
| **Overlay** — the cyan dimension layer | Vector-crisp, **not** pixelated. It sits between the two worlds as the measuring instrument. |
| **Seam** — deliberate, sparing | The score numeral (seven-segment), verdict badge words, the wordmark, 2 px pixel-notched HUD corner ticks, a **stepped** sparkline, the 1 px dot grid. Nothing else. |

**Never set body text, labels, metrics, or controls in a pixel/bitmap face.**

### 3.3 Subdued, not neon — enforce quantitatively

1. **≥ 85% of every screen is dark neutral** — `#0A0E14`, `#161E2A`, `#1B2430`, `#2A3644`. At a glance the screen reads almost monochrome.
2. **Any single accent hue occupies < 8% of screen area.** If a screen looks colourful, it is wrong.
3. **No glow, bloom, or outer shadow on chrome.** Glow exists only on density bands and hazard sprites, at the §5 opacities — diffuse and dim, never a fireball.
4. **No gradients** except the density ramp and the fire sprite core.
5. **Depth comes from hairlines and elevation, never lighting.** Prefer a 1 pt `separator` rule over a drop shadow every time — the strongest thing to carry over from Reference A.
6. **No decorative colour, ever.** If a colour is on screen, it means something (§5).
7. **Air is a feature.** Copy Reference A's generosity with empty space in the chrome. *(The canvas is the exception — a furnished room is legitimately dense. Air belongs to the chrome, not the venue.)*

### 3.4 Constraints on the retro influence

- **Original artwork only.** Nintendo-era craft is a *stylistic* reference. Do not use, copy, redraw, or evoke any existing character, logo, sprite, typeface, or trade dress.
- No CRT scanlines, VHS aberration, vaporwave, or arcade-cabinet framing. The retro-ness comes from **pixel geometry and palette restraint**, not filters.
- No skeuomorphic wood, metal, or paper textures.

---

## 4. TYPOGRAPHY — THREE VOICES, STRICTLY SEPARATED

Three faces, each with one job. All **native to iOS** — no bundling, no licensing, full Dynamic Type.

| Voice | Face | Used for | Treatment |
|---|---|---|---|
| **DISPLAY** | **SF Pro Display, Compressed or Condensed, Bold/Heavy** | Screen titles, venue names, verdict headlines, section headers | **ALL CAPS**, tight tracking (−1 to −2%), large. Reference A's voice, rendered natively. |
| **DATA** | **SF Mono, Medium** | All metrics, units, status chips, tool state, dimension labels, timestamps, the scale caption | ALL CAPS for chips and labels; sentence case for readouts. Letterspaced +4 to +8% on micro-labels. **Monospaced digits always**, so readouts don't jitter mid-run. |
| **BODY** | **SF Pro Text** | Diagnoses, verdict reasons, Learn articles, settings — any sentence a human reads | Regular/Medium. Full Dynamic Type, uncapped. Never all-caps. |
| *(Accent)* | One bitmap/seven-segment face | **Only** the `EGRESS` wordmark, the big score numeral, and the PASS/WARN/FAIL badge words | Nothing else. Ever. |

**Rules:**

- **Micro-label pattern (use relentlessly):** metadata is tiny letterspaced uppercase mono in `text.tertiary`, sitting directly above its value in a larger weight — `CAPACITY` over `200`, `MODIFIED` over `2m ago`, `CLEARANCE` over `168 s`. This single pattern is the biggest contributor to the "professional datasheet" feel.
- **Units always shown**, always metric: `p/m²`, `s`, `m`. **Never a bare number in a verdict reason.**
- **Dynamic Type principle: chrome scales, the map does not.** Sprites, grid, and dimension geometry are fixed to world scale; canvas labels cap at `.large`.
- HUD numerics `.semibold`; empty-state hero glyphs 48 pt `.light`.
- The seven-segment score gets a **dim "ghost" numeral behind the live value** (all segments lit at ~12% opacity), as in Reference B.

---

## 5. COLOUR SYSTEM — USE THESE EXACT TOKENS

**Two governing rules:**

1. **Hue carries meaning; shape carries affordance.** There is exactly **one green**. Primary actions differ from status by *shape* — a filled capsule, 44 pt, elevated — never by inventing a second green. Destructive = red; neutral = plain grey text. **No decorative green anywhere.**
2. **Cyan is reserved exclusively for measurement** — dimension lines, clear-width callouts, aisle constriction callouts, the ruler overlay. Cyan carries **no safety meaning** and appears nowhere else.

| Token | Hex (dark) | Light mode | Use |
|---|---|---|---|
| `canvas.base` | `#0A0E14` | **unchanged** | blueprint ground |
| `canvas.grid` | `#1B2430` | unchanged | faint dot grid (0.25 m cells) |
| `canvas.gridMajor` | `#26323F` | unchanged | every 4 cells = 1.0 m |
| `surface.glass` | material + `#131A24` @ 72% | light material | glass chrome |
| `surface.raised` | `#161E2A` | `#F5F7FA` | cards, sheets |
| `separator` | `#2A3644` | `#D8DEE6` | 1 pt hairlines |
| `text.primary` | `#E8EEF5` | `#0E1620` | headlines, metrics, **emote glyphs** |
| `text.secondary` | `#9AA9BA` | `#4A5766` | labels, captions |
| `text.tertiary` | `#74849A` | `#6B7889` | micro-labels, metadata |
| `accent.dataGreen` | `#34E27A` | `#0F9D52` | scores, sparklines, primary actions, PASS |
| `accent.cyan` | `#4FD8FF` | `#0A7EA4` | **dimension & measurement only** |
| `density.comfortable` (< 1.8 p/m²) | `#1E5C46` @ 25% | unchanged | glow band |
| `density.congested` (2–4) | `#C98A2E` @ 45% | unchanged | glow band |
| `density.atRisk` (≥ 5) | `#E8632B` @ 65% | unchanged | glow band |
| `density.crush` (≥ 7) | `#FF2D4B` @ 85% | unchanged | glow band |
| `hazard.fire` / `fireCore` | `#FF6B1A` / `#FFD24A` | unchanged | flame sprite |
| `hazard.smoke` | `#8B95A3` @ variable | unchanged | smoke veil |
| `hazard.flood` | `#1E63D6` | unchanged | deep blue — water must never read as a dimension line |
| `verdict.pass` | `#34E27A` | `#0F9D52` | PASS badge, RALLY visor |
| `verdict.warn` | `#F5B93B` | `#9A6B00` | WARN badge, escalation banner, **hazard-seed hatch** |
| `verdict.fail` | `#FF3B5C` | `#C2001E` | FAIL badge, casualty markers |
| `agent.calm` | `#B8C6D6` | unchanged | agent sprite tint |
| `agent.uneasy` | `#F5B93B` | unchanged | shares the caution ramp deliberately |
| `agent.panicked` | `#FF3B5C` | unchanged | shares the danger ramp deliberately |
| `agent.staff` | `#7B5CFF` | unchanged | violet — outside every semantic ramp, so staff read as "special", not "dangerous" |
| `rally.body` | `#C7D3E0` | unchanged | mascot chassis (visor/antenna take the verdict tint) |

**There is no blue in this system** other than `hazard.flood`. Reference B's blue playback buttons become neutral glass with only PLAY filled green.

**🆕 Proposed additions (mark clearly as proposals — they are outside the plan's token table and need contrast verification):**

| Proposed token | Suggested value | Use |
|---|---|---|
| `prop.fill` | `#232E3C` | relocatable obstacle body (furniture) |
| `prop.edge` | `#3A4859` | lit top edge on obstacles, so they read as solid volume |
| `prop.structural` | `#1C242F` + 1 px `#46566A` outline | non-relocatable structural elements (columns, stages, bar runs) |
| `decor.tile` | `#141C26` | sim-inert decor — flat, no edge highlight, lowest contrast |

**Dark-mode exception (deliberate — keep it):** the **Sim Canvas and its HUD stay dark even in Light Mode.** Chrome elsewhere adapts fully.

### 5.1 Optional — the "paper" surface for the reading tabs

Reference A's warmth has one honest home: the surfaces where a human sits and *reads*. Design **one optional variant** of the **Learn tab** (and its Settings sheet) on a warm paper ground — roughly `#F2EFE6`, `#1A1814` text, green accent `#0F9D52` — using the same condensed-caps + mono-micro-label system. It should feel like a printed safety briefing. Mark it as a proposal. **Do not apply it to the canvas, HUD, Spaces, or Results.**

### 5.2 Colour-blind safety is not optional

The four density bands have monotonically increasing luminance *and* saturation, so in greyscale **brighter always means worse.** Every band also carries a pattern fill — always on, never a toggle:

| Band | Pattern | Extra redundancy |
|---|---|---|
| Comfortable < 1.8 | no fill | — |
| Congested 2–4 | sparse dots | numeric chip |
| At risk ≥ 5 | diagonal hatch | chip + amber banner |
| Crush ≥ 7 | cross-hatch | chip + red banner + warning triangle glyph |

**No state anywhere may be signalled by hue alone.**

---

## 6. DEVICE, LAYOUT & MOTION

**Canvas:** iPhone 16 — **393 × 852 pt.** Dark Mode is primary.
**Safe areas:** top 59 pt (Dynamic Island), bottom 34 pt (home indicator), tab bar ≈ 49 pt above that.

> **Governing rule: the simulation canvas ignores the safe area; every control respects it.**

```
┌───────────────────────────────┐  ← canvas bleeds to all edges
│ ░ EGRESS │ Nightclub ▾ │ 60fps│  glass HUD: top inset +8, height 44, side inset 12
│ ░ 200 agents │ t+ 42.7s │ ⚙   │
│                               │
│        [ SIM CANVAS ]         │  free zone — never occluded
│                               │
│   ┌─────────────────────┐     │  RALLY card: max width 361, side inset 16
│   │ ▣ RALLY  BOTTLENECK │     │
│   └─────────────────────┘     │
│ ▓▓▓ timeline scrubber ▓▓▓▓▓▓▓ │  height 56
│  ◀◀   ▶   ⏸   ⟲   ⚙          │  playback row height 60
├───────────────────────────────┤
│  Spaces    Simulate    Learn  │  tab bar 49 + 34 inset
└───────────────────────────────┘
```

**Radius scale (exact tokens; all continuous/squircle corners):**

| Token | Radius | Applied to |
|---|---:|---|
| `radius.xs` | 8 | chips, density pills, tool buttons |
| `radius.sm` | 12 | inline fields, sparkline tiles, thumbnails |
| `radius.md` | 16 | HUD bar, timeline container |
| `radius.lg` | 20 | library cards |
| `radius.xl` | 26 | RALLY card |
| `radius.sheet` | 28 | all sheets |

**Concentric rule:** nested radius = outer radius − padding (a 26 pt card with 10 pt padding holds a 16 pt inner element).

**Touch targets:** minimum **44 × 44 pt**, at every type size.

**Thumb zones (right-handed, from the bottom edge):**

| Zone | Range | Contents |
|---|---|---|
| Natural | 0–260 pt | tab bar, playback row, scrubber, tool sheet, primary CTA |
| Stretch | 260–520 pt | RALLY action chips, density chips |
| Hard | 520–852 pt | HUD readouts (display-only), nav titles, **destructive actions — deliberately far from the thumb** |

### 6.1 🆕 Motion tokens — design to these, don't invent values

Every animation in the product comes from one token set. If you produce any prototype or motion spec, use these `spring(response, dampingFraction)` values verbatim:

| Token | Spring | Applied to | Character |
|---|---|---|---|
| `motion.tap` | `0.25, 0.85` | button/chip press, tool arm | snappy, no overshoot |
| `motion.chip` | `0.30, 0.80` | config chips, density chip expand | slight life |
| `motion.sheet` | `0.45, 0.85` | tool / results / settings sheets | system-like |
| `motion.banner` | `0.35, 0.75` | escalation banner in and out | urgent, not jarring |
| `motion.card` | `0.50, 0.60` | **RALLY entrance** | visible overshoot — the mascot has personality |
| `motion.emote` | `0.28, 0.55` | **emote badge pop-in**, scale 0.6 → 1.0 | tiny playful overshoot |
| `motion.dismiss` | `0.30, 1.00` | any exit transition | critically damped — nothing bounces on the way out |
| `motion.toolSheet` | `0.40, 0.85` | tool sheet detent change | — |

**Not springs:** the score-ring reveal is a **1.2 s `.easeOut` sweep** with a synchronised count-up numeral, then `motion.card` on the verdict badge. RALLY's talk loop is an **8 fps frame cycle**, running only while text streams.

---

## 7. 🆕 THE VENUE IS FURNISHED — PROPS, DECOR & HAZARDS

**This is the biggest change in v3.** An empty rectangle is never a shippable venue. Every preset ships with an authored prop layout, and furniture is now the thing the crowd's intelligence is demonstrated *against*.

### 7.1 Three object classes, three visual treatments

| Class | Behaviour | Visual treatment |
|---|---|---|
| **Relocatable obstacle** — standing tables, benches, desks, racks, kiosks, merch stands, lockers | Blocks movement. RALLY **may** propose moving it. | `prop.fill` body, 1 px **lit top edge** (`prop.edge`), 1 px dark base line beneath. Reads as a solid volume seen from above. |
| **Structural obstacle** — columns, stages, bar runs, seating blocks, turnstile banks, lab benches | Blocks movement. RALLY may **never** propose moving it — it gets "route around" advice instead. | `prop.structural` body, heavier 1 px outline, slightly desaturated, plus a **2 px corner-notch anchor mark** at one corner. *(Proposed convention — the plan requires the distinction to exist; this is my suggestion for how to show it. Mark it as a proposal.)* |
| **Decor tile** — sim-inert floor graphics | No physics at all. | `decor.tile`, completely flat, **no edge highlight, no base line**, lowest contrast. Must be instantly distinguishable from an obstacle, or the user will mis-read the sim. |

> **The legibility test:** at 8 pt per cell, a user must be able to tell in under a second whether a thing will stop a person. Edge highlight = solid. Flat = walk-through.

### 7.2 Per-venue prop sets — draw these

Design a **pixel prop library** covering all six presets. Props are top-down footprints snapped to the 0.25 m grid.

| Venue | Footprint | Agents | Props | **Structural (non-relocatable)** |
|---|---|---:|---|---|
| **Nightclub** | 20 × 15 m | 200 | bar run, stage block, standing tables, speaker stacks | stage block, bar run |
| **Gym** | 25 × 20 m | 90 | rack rows, benches, treadmill bank | — |
| **Concert Hall** | 30 × 24 m | 200 | stage, seating blocks, crowd barriers, merch stand | stage, seating blocks |
| **Office** | 24 × 18 m | 80 | desk pods, meeting pod, printer bank, lockers | — |
| **Metro Platform** | 60 × 6 m | 200 | benches, kiosk, turnstile bank, **columns** | columns, turnstile bank |
| **School** | 30 × 20 m | 180 | desk rows, lockers, lab benches | lab benches |

Use these exact capacity figures on the Spaces cards — they come from the plan, not from the mockups.

### 7.3 Hazard seeds are placeable props — and must look dangerous while inert

The editor palette gains a **Hazards group, visually separated from Construction and Props** so nobody drops a fire into a room by accident.

| Palette item | Places | Config chip | Symbol |
|---|---|---|---|
| Ignition source | fire seed | `IGNITION DELAY` (s) | `flame.fill` |
| Water source | flood seed | `FILL RATE` (m/s) | `water.waves` |

**Seed appearance while inert:** a **warning-hatched footprint** — diagonal hatch in `verdict.warn` at low opacity — with the SF Symbol centred and a mono chip showing its config value. It must read unmistakably as "armed but not yet running." Once the sim starts, the seed is replaced by the live hazard sprite.

### 7.4 🆕 Aisle constriction callouts — and the one rule that must not be broken

The engine measures the narrowest aisle the crowd actually walks through, and flags it when it falls below the standard. Design this as a **cyan double-arrow spanning the gap between two obstacle edges**, with the measurement label (`0.7 m`) riding the arrow.

> **Critical rule: the measurement is cyan; the violation is not.** Cyan carries no safety semantics — ever. When an aisle is below minimum, signal it with a small **amber `exclamationmark.triangle.fill`** at the label and the verdict reason text. **Never recolour the dimension line to amber or red.** This is exactly the rule that gets broken by accident; don't.

---

## 8. SCREENS TO DESIGN

Three tabs, each with its own nav stack, max 2 push levels.
**Tab bar: Spaces · Simulate · Learn** — `square.grid.2x2.fill` · `play.rectangle.fill` · `graduationcap.fill`. Flat, unfilled, one tinted active state.

### 8.1 Spaces — Workspace Library *(root, display-caps title "SPACES")*

Subtitle: *"Library of saved environments."* Sectioned: **System Presets** / **Custom Templates**. Searchable. Toolbar `+` and `gearshape.fill`.

**Card anatomy — build this exactly:**

```
┌──────────────────────────────────────────┐  radius 20, surface.raised, 1pt separator
│ ┌────────┐  NIGHTCLUB              ← display caps
│ │ pixel  │  CAPACITY      MODIFIED  ← mono micro-labels, tertiary
│ │ venue  │  200           2m ago    ← mono values, primary
│ │vignette│  ┌──────────────┐ ┌───────────┐
│ └────────┘  │ HIGH_DENSITY │ │ ● ● ○     │  ← status chip + difficulty dots
│             └──────────────┘ └───────────┘
│ ╭─╯╰─╮╭──╯ stepped green sparkline, full card width
└──────────────────────────────────────────┘
```

- Thumbnails are **pixel-art venue vignettes showing the furniture** — a nightclub tile must read as a nightclub because you can see the bar run and the stage. Not photographs.
- Status chips: `STABLE` (green outline) · `HIGH_DENSITY` (amber outline) · `IDLE` (grey outline) — outlined, never filled.
- **Difficulty dots** (from the scenario presets): Kitchen Fire ● ● ○ · Burst Pipe ● ● ○ · Blocked Main Exit ● ● ● · Concert Crush ● ● ● · School Drill ● ○ ○.
- Sparkline **stepped, not smoothed** — sampled data, and the steps echo the pixel grid.
- Swipe: Duplicate (leading) · Export / Delete (trailing, confirmed).
- **Fictional venues only** get difficulty chips and personal bests. Real-incident presets never do — see §8.9.

### 8.2 Spaces — Space Detail *(push, inline title)*

Large pixel vignette, sparkline, capacity block in micro-label pattern, four actions: **Edit · Simulate · Duplicate · Export**.

### 8.3 Spaces — Editor ★ *(push, editable inline venue name)*

- **Header card:** venue name in display caps + live status in mono: `◉ TOOL: Draw Wall`. Below it, the scale caption in mono tertiary: **`1 PIXEL BLOCK = 0.25 m × 0.25 m`**.
- **Canvas:** dark blueprint, 0.25 m dot grid, brighter major line every 4 cells, **furnished with the venue's prop set** per §7.
- **Cyan dimension overlay:** fine extension lines, small arrowheads, labels riding and rotating with the geometry — `8.5 m`, `Width: 2.0 m`, **`Clear Exit Width: 1.2 m`** — snapped to 0.25 m. Selected elements get square handles at corners and midpoints.
- **🆕 Tool sheet — now three visually separated groups**, pinned at `.height(140)`, drag-collapsible to a 56 pt handle, **never fully dismissible** (you must draw while it's open):

| Group | Tools |
|---|---|
| `CONSTRUCTION` | Wall `pencil.and.ruler` · Exit `door.left.hand.open` · Freehand `hand.draw` · Erase `eraser.fill` |
| `PROPS` | Obstacle `cube.fill` · Decor `paintbrush.fill` |
| **`HAZARDS`** ⚠️ | Ignition `flame.fill` · Water `water.waves` — **set apart by a hairline divider and extra padding.** This separation is a safety affordance, not decoration. |

Plus persistent toggles: Dimension overlay `ruler.fill` (cyan) · Grid snap `square.grid.3x3.fill` · Undo/Redo floating at the trailing edge.
- **Armed-tool state must be unmistakable:** the active chip fills `accent.dataGreen` and the header echoes the tool name.
- **🆕 Long-press context menu on a structural prop** shows a disabled/greyed `Move` row labelled `LOCKED — STRUCTURAL`, alongside Edit width · Duplicate · Delete. Design that state.

### 8.4 Simulate — Pre-run Config *(`.medium` sheet)*

Chips: **agent count · crowd mix · alarm delay · scenario**. Crowd mix shows population types as tiny pixel icons — adult, child, elderly, wheelchair user, staff.

### 8.5 Simulate — Sim Canvas ★ *(root, nav bar hidden)*

Reference D is the canonical composition. The glass HUD replaces the nav bar entirely.

**HUD pill:** `EGRESS` │ venue + chevron │ `60 FPS` │ `200 AGENTS` `person.3.fill` │ `t + 42.7s` `timer` │ `⚙`. Mono, monospaced digits.

**🆕 Design five states — the two hero frames are (b) and (c):**

- **(a) Armed / pre-run** — furnished room, crowd idle and calm, amber `bell.fill` alarm trigger visible, dimension overlay readable, hazard seeds showing their warning hatch.
- **(b) ★ Early run — the crowd is competent.** Fire just ignited at the kitchen corner, little smoke. Agents **thread cleanly between the bar run and the standing tables**, swerving early and decisively. Density mostly green/amber. A few `?` badges. *This frame's job: the crowd looks like it's thinking.*
- **(c) ★ Late run — perception fails.** Smoke veil thick across the room, an exit blocked and the flow visibly rerouted, density glow amber → orange with pattern fill, agents **clipping furniture and stumbling**, a jam at the main exit, floating density chip `6.8 p/m²`, amber **`BOTTLENECK DETECTED`** banner, emote badges including a teardrop near the jam, and the RALLY card citing the 0.7 m aisle. *This frame's job: the crowd looks like it's failing — and you can see why.*
- **(d) First-launch empty** — dimmed blueprint grid, `NO SPACE LOADED` in display caps, one primary button to Spaces. Never a blank screen.
- **(e) 🆕 Paused-on-return overlay** — returning from background never auto-resumes. Show a calm centred glass panel: `PAUSED` + *"Tap to resume"*. Low-key, non-alarming.

**🆕 Also design the above-budget HUD notice** — a single quiet mono line appearing when agent count exceeds the validated budget: *"Above the validated performance budget — frame rate may drop."* Informative, not a warning banner.

**Timeline scrubber (h 56):** waveform filling left→right with event markers at ignition, jam formation, casualties, threshold crossings; elapsed time in mono trailing. **Two modes with visibly different affordances:** *during a run* it is progress + live event log only (**no thumb**, dragging does not seek; markers tappable for a tooltip); *post-run* it seeks (**thumb visible**, markers jump). Renders 20 pt tall inside a 44 pt hit area.

**Playback row (h 60):** restart · step back · **play/pause** · step forward · settings. **Neutral glass squares, radius 8** — only the primary play action is green-filled.

**Z-order (bottom → top):** canvas → **decor** → **obstacles** → density glow → hazards → agents → **emote badges** → dimension overlay → density chips → RALLY card → HUD/scrubber → escalation banner → sheets.

### 8.6 Simulate — Results *(`.medium` → `.large` sheet)*

Use Reference B's section stack:

1. **Header** — venue name + `SIM RESULTS` in display caps.
2. **Score hero** — seven-segment numeral with the dim ghost `888` behind it, a thin arc ring tracking 0–100, and the verdict badge chip beside it: `PASS` `checkmark.seal.fill` / `WARN` `exclamationmark.triangle.fill` / `FAIL` `xmark.octagon.fill`, palette rendering.
3. **KEY FINDINGS** — RALLY sprite left, headline, two-to-three-line diagnosis in body text.
4. **REASONS** — every row renders **metric + threshold + value + unit + location**:
   - "3 casualties at Exit A (fire)"
   - "Peak density 6.8 p/m² at the north corridor (caution ≥ 5.0 p/m²)"
   - "Clearance 168 s exceeds the 120 s target for a nightclub"
   - **🆕** "The aisle between the bar and the standing tables is 0.7 m — below the 1.2 m assembly-corridor minimum"
5. **EVACUATION CURVES** — line chart, Baseline vs Optimized, axes `POPULATION` / `TIME` in mono micro-caps, hairline gridlines only.
6. **DELTA ANALYSIS** — A/B compare, two-up: `CLEARANCE TIME 168s → 94s`, `CASUALTIES 3 → 0`, each with a green down-arrow. This is the emotional payoff; give it room.
7. **EXPORT REPORT** — green filled capsule, `doc.richtext`.
8. **Disclaimer** in `text.tertiary`.

**🆕 Two hierarchy rules to design for explicitly:**

- When the verdict level and the score band disagree, the card **leads with the violated threshold, not the number** — the score drops to secondary.
- The aisle reason (4d) is **score-neutral by design** — it appears in the reasons list but does not move the number. Design a subtle mono affordance for this, e.g. a `NO SCORE IMPACT` micro-tag on that row, so a user doesn't try to reconcile it arithmetically.

### 8.7 Learn — Home *(root, display-caps title "LEARN")*

Quiz card, preparedness tips `lightbulb.fill`, case-study list `books.vertical.fill`. **The reading surface** — take Reference A's editorial restraint furthest here: generous line height, hairline dividers, almost no chrome, no game furniture.

### 8.8 Learn — Case Study, fictional *(push, inline)*

Sober narrative typography. "Play this scenario" action present.

### 8.9 🆕 Learn — Case Study, real incident *(push, inline)* — design this as a distinct frame

Real incidents killed real people. The plan makes the handling rules binding, and they are visible design constraints:

- **No score. No leaderboard. No difficulty chip. No personal best.** Those exist for fictional venues only.
- **No "Play this scenario" button** if the recreation isn't shipping — static text only.
- **RALLY does not appear.** No mascot, no personality, no jokes.
- **Expressive emotes are suppressed entirely** in any accompanying visualisation — dots, density and geometry only. Never crying cartoons.
- **Sourced and dated**, with a line stating the recreation is approximate and educational.
- Neutral, non-blaming language. No casualty imagery.

Visually: strip the frame back further than 8.8 — no accent colour except a single hairline rule, no chips, no sparkline. The restraint *is* the design.

### 8.10 Settings *(`.large` sheet)*

Grouped rows:

- **Audio** — master toggle + sub-toggles (Ambience / Agents / Alerts / Mascot voice)
- **Intensity** — Reduce Audio Intensity · Reduce Haptic Intensity
- **🆕 Experimental** — `Trip and fall under crowd pressure`, **off by default**, with a mono caption directly beneath: *"Experimental. Excluded from the Safety Score and verdict."* Design this caption as load-bearing, not fine print — it is the honesty mechanism.
- **About** — units · "How scoring works" · accessibility note (including the freehand-drawing limitation) · AI-availability note · the disclaimer.

### 8.11 Sheet specification (all sheets)

Visible drag indicator, 28 pt corner, glass background. **Editor tools** and the **expanded RALLY sheet** allow background interaction (you keep drawing / the sim keeps running); every other sheet dims and disables it.

---

## 9. CHARACTERS — RALLY, THE CROWD, AND THE EMOTE LAYER

Reference B has the right **craft level**: chunky, high-contrast, readable at small size, expressive faces from very few pixels. Match that quality. The silhouettes below are the spec.

### 9.1 RALLY — the coach

**Name:** RALLY. **Designation:** RP-25 (*Rally Point, 0.25 m grid*). **Role:** safety coach — never an inspector or authority.

**Silhouette — original artwork, 16 × 16 px source rendered at 3–4× (48–64 pt):**
chunky rounded-square head with **one wide visor** (two eyes mush at dot scale — a legibility decision, not a style one); stubby antenna with a bulb; boxy torso with a **3-pip chest grid**; short arms; **hover base instead of legs**. Maximum **6 colours**, all from §5. Chassis `rally.body #C7D3E0`; visor and antenna bulb take the verdict tint.

**Five states — deliver as a sprite sheet:**

| State | Frames | Pose / tells |
|---|:--:|---|
| `idle` | 2 | gentle hover bob; antenna bulb pulses slowly |
| `talk` | 4 | visor waveform animates; antenna blinks per syllable |
| `concerned` | 3 | leans forward, antenna droops, visor narrows, one arm raised pointing |
| `alert` | 2 | rigid posture, antenna bulb strobes |
| `celebrate` | 4 | arms up, hover bounce, 6 pixel-confetti sprites |

**Never colour-alone:** each state also differs by pose, antenna shape, an SF Symbol badge on the card, and the headline — so it reads in greyscale.

### 9.2 The RALLY card

Radius 26, glass, **56 pt sprite at left**, max width 361, side inset 16.

```
┌─────────────────────────────────────────────┐
│ ▣ RALLY   BOTTLENECK DETECTED          [×]  │
│  (48pt)   The aisle between the bar and the │  ← exactly ONE metric sentence
│           tables is 0.7 m (minimum 1.2 m).  │
│  ┌──────────────────────┐ ┌───────────────┐ │
│  │ Widen aisle to 1.2 m │ │ Relocate tables│ │  ← primary green · secondary amber
│  └──────────────────────┘ └───────────────┘ │
└─────────────────────────────────────────────┘
```

- Placed in the canvas half **opposite** the triggering hotspot. Never occludes the hotspot + a 44 pt halo, the HUD, the scrubber, or the tab bar.
- **Maximum one instance** — cards never stack; a new event replaces the content.
- **Never modal** — no dimming scrim, the sim keeps running.
- **State tinting:** a WARN card takes a low-opacity amber wash + amber hairline over glass — **not** Reference B's solid tan fill. PASS green, FAIL red, same low opacity.
- **🆕 Fix-chip rule:** `Relocate…` may only ever target a **relocatable** prop. For a structural element the secondary chip reads `Route around the columns` instead. Show both variants.
- Verbatim content to use: **`BOTTLENECK DETECTED`** (above) and **`EVACUATION SUCCESSFUL`** — *"Everyone cleared in 94 s, peak density 2.2 p/m². Below the 120 s target."*
- Primary chip green-filled; secondary amber-outlined. **Never two green chips, never duplicates.**
- **Reachability:** if the card lands more than 520 pt from the bottom, a persistent 44 pt `RALLY` pill appears in the natural thumb zone and re-opens the card as a bottom sheet. Design that pill.

### 9.3 The crowd

Pixel agents at world scale, readable at 3–40 pt per cell. Emotion is **multi-channel by design**: aura colour **plus** emote glyph shape **plus** gait. Five population types must be distinguishable **by silhouette** — adult, child, elderly, wheelchair user, staff. **Staff use violet `#7B5CFF` plus a distinct silhouette**, deliberately outside every semantic ramp.

**🆕 Show the intelligence in the sprite sheet:** include a small annotated strip demonstrating (i) an agent **swerving early** around a table with a clean arc, and (ii) the same agent in smoke **clipping the corner and stumbling** — a 2-frame hitch with a reduced-speed pose. This contrast is the product's single best proof that the crowd is simulated, not animated.

Keep expressions **restrained, not comic** — this depicts people in danger. Concerned, not cartoonishly terrified.

### 9.4 🆕 The expressive emote layer — six glyphs, shape-only

A **display-only** layer, drawn as a **2-frame 8 × 8 px badge above the sprite**, popping in with `motion.emote`.

| Emote | Glyph | Trigger | Duration |
|---|---|---|---|
| `astonished` | wide-eye **!** | first hazard sighting, or first bump | 1.2 s |
| `confused` | **?** | at a decision point with two similar-cost routes | 1.0 s |
| `frustrated` | steam puff | repeat bumps, or a queue stalled | 1.0 s |
| `distressed` | single teardrop | casualty nearby, sustained high density, or trapped | 1.5 s |
| `relieved` | exhale | crossing an exit threshold | 0.8 s |
| `resolute` | steady chevron | **staff only**, on calming a neighbour | 1.0 s |

**Binding rules — these are ethics constraints, not style preferences:**

1. **Shape carries the meaning; colour carries none.** Render all six in a single neutral tint (`text.primary`) on a dark 1 px-outlined chip so they read at any density. No emote is colour-coded.
2. **No gore, no screaming, no anguish.** `distressed` is a small teardrop. Nothing more.
3. **Suppressed entirely on real-incident presets** (§8.9).
4. **Max 12 on screen at once**, priority `distressed > astonished > frustrated > confused > relieved`.
5. **Hidden entirely below 8 pt per cell** — at dot scale a field of badges is soup, not information. Show a zoomed-out frame proving this.
6. **Reduce Motion:** fade in without overshoot; `distressed` does not pulse.

---

## 10. ACCESSIBILITY VARIANTS TO DESIGN

Part of the deliverable, not an afterthought.

1. **Reduce Transparency** — every glass surface becomes solid `surface.raised #161E2A` with a 1 pt `separator` border. Text contrast must hold.
2. **Differentiate Without Colour** — pattern opacity +40%; agent auras gain outline rings (calm none / uneasy dashed / panicked solid double); verdict badges gain inline text labels.
3. **Dynamic Type at AX3+** — the HUD collapses to a **single summary line** (`t+42.7s · 200 · 6.8 p/m²`) with full stats in a tap-to-expand sheet; canvas dimension labels hide and become tap-to-reveal callouts; a 2-column chip row stacks full-width. **Sprites, grid, props, and dimension geometry never scale with text.**
4. **🆕 The parametric edit form** — the accessible authoring path, since freehand drawing is not VoiceOver-operable. A plain form sheet: exit clear width (stepper, 0.1 m), add an exit on wall N/E/S/W, a **list of obstacles with reposition/remove actions**, agent count / mix / alarm delay. It must look like a deliberate, first-class screen — not a fallback. Design it.

**SF Symbol rendering:** default **hierarchical**. Use **palette** only where a symbol carries semantic state (verdict badges, hazard toggles, the cyan dimension toggle). **Multicolour is never used** — it would import Apple's palette and break the reserved-hue rule.

---

## 11. HARD "DO NOT" LIST

- ✗ **No empty rooms.** Every venue frame shows furniture.
- ✗ **No cyan on a violation.** Cyan measures; amber warns. Never recolour a dimension line to signal danger.
- ✗ **No relocation advice for a structural prop.** Columns and stages get "route around."
- ✗ **No colour-coded emotes.** Shape only.
- ✗ **No emotes, mascot, score, or difficulty chip on a real-incident case study.**
- ✗ No second green. No decorative green. No green on destructive or neutral actions.
- ✗ **No blue chrome** — playback buttons are neutral glass; only PLAY is green.
- ✗ No multicolour SF Symbols.
- ✗ No neon glow, bloom, scanlines, CRT filters, or chromatic aberration.
- ✗ No pixel/bitmap font on body text, labels, metrics, or controls.
- ✗ No isometric *editing* mode. Top-down only. (One labelled marketing frame excepted.)
- ✗ No photographic thumbnails — pixel vignettes only.
- ✗ No existing IP: characters, logos, typefaces, or trade dress.
- ✗ No gore or casualty imagery.
- ✗ No icon-only control for any destructive or state-critical action.
- ✗ No number without its unit in any verdict reason.
- ✗ No pull-to-refresh, sync indicators, login, or avatars.

---

## 12. DELIVERABLES CHECKLIST

1. **Design-token sheet** — colour swatches with hex + use (including the four proposed prop tokens, marked), radius scale, the three-voice type scale with specimens, the motion token table, spacing, density-band pattern swatches.
2. **Component library** — HUD pill, RALLY card (PASS / WARN / FAIL, plus the structural-prop chip variant), density chip, status chip set, difficulty dots, tool chip (armed + idle), library card, verdict badge set, seven-segment score + ring, timeline scrubber (both modes), playback row, primary/secondary/destructive buttons, tab bar, micro-label metric block, **hazard-seed footprint**, **aisle constriction callout**.
3. **🆕 Prop sprite library** — all six venues' prop sets per §7.2, showing relocatable vs structural treatment and decor tiles side by side at 8 pt and 24 pt per cell.
4. **Twelve screen frames** per §8, including the Sim Canvas in all five states — with **(b) early/competent** and **(c) late/failing** as the two hero frames.
5. **RALLY sprite sheet** — 5 states at 1× pixel grid and 4× render size.
6. **Crowd sprite sheet** — 5 population types × 3 arousal states, **plus the six 8 × 8 emote badges**, plus the annotated swerve-vs-stumble strip.
7. **Accessibility variants** — Reduce Transparency, Differentiate Without Colour, one AX3 Dynamic Type frame, and the parametric edit form.
8. **Optional paper-mode frame** — Learn tab per §5.1, labelled as a proposal.
9. **One labelled isometric frame** — marketing/thumbnail asset only.
10. **The hero shot** — Sim Canvas state (c), Nightclub: bar run, stage block, standing tables, speaker stacks; crowd threading then jamming; fire at the kitchen corner; smoke veil; blocked exit and visible reroute; `6.8 p/m²` chip; `BOTTLENECK DETECTED` banner; teardrop emote near the jam; RALLY citing the 0.7 m aisle. **This is the frame the product will be judged on.**
