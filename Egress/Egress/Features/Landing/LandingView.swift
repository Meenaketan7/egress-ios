import EgressEngine
import SwiftUI

// MARK: - LandingView

/// The front door (design: the EGRESS landing page). A cream hero screen shown on every launch: the
/// heavy pixel wordmark over an isometric evacuation diorama — a city block whose rooftops smoke while
/// green routes stream a small crowd out past a RALLY assembly sign to the exits, a lone marshal holding
/// the centre — then the single green call to action. Committed to the light shell; honours Reduce Motion.
struct LandingView: View {
    /// Raised when the user taps START — the app root cross-fades in.
    let onStart: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @Environment(FeedbackServices.self)
    private var feedback: FeedbackServices?

    /// Drives the breathing call-to-action.
    @State private var pulse = false
    /// Staggers the hero content in on first appearance.
    @State private var shown = false

    var body: some View {
        ZStack {
            Color.egGround.ignoresSafeArea()

            VStack(spacing: EgressSpacing.sm) {
                Spacer(minLength: 0)

                Text("EGRESS")
                    .font(.system(size: 66, weight: .black))
                    .tracking(1)
                    .foregroundStyle(Color.egTextPrimary)
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown ? 0 : -12)

                LandingDiorama()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 440)
                    .opacity(shown ? 1 : 0)
                    .scaleEffect(shown ? 1 : 0.96)

                Spacer(minLength: 0)

                VStack(spacing: EgressSpacing.md) {
                    Button(action: start) {
                        Text("START YOUR SIMULATION")
                            .font(EgressFont.body(.headline, weight: .heavy))
                            .foregroundStyle(Color.egSurfaceRaised)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, EgressSpacing.lg)
                            .background(
                                RoundedRectangle.egSquircle(EgressRadius.md)
                                    .fill(Color.egDataGreen)
                                    .overlay(alignment: .bottom) {
                                        RoundedRectangle.egSquircle(EgressRadius.md)
                                            .fill(Color.egDataGreenDeep)
                                            .frame(height: 5)
                                            .padding(.horizontal, 2)
                                    }
                                    .clipShape(RoundedRectangle.egSquircle(EgressRadius.md))
                            )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(pulse ? 1.02 : 1)
                    .accessibilityLabel("Start your simulation")
                    .accessibilityHint("Opens the Spaces library")

                    Text("OFFLINE . PRIVATE . PRECISE")
                        .font(.system(.subheadline, design: .monospaced, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.egTextTertiary)
                }
                .opacity(shown ? 1 : 0)
            }
            .padding(.horizontal, EgressSpacing.lg)
            .padding(.vertical, EgressSpacing.lg)
        }
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(Motion.card) { shown = true }
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private func start() {
        feedback?.haptics.play(.toolTap)
        onStart()
    }
}

// MARK: - LandingDiorama

/// The isometric vignette (design: the landing illustration). An ink-on-cream city block drawn in the
/// app's chunky charcoal line — a handful of cuboid buildings on an iso ground, smoke curling off the
/// rooftops, green escape routes flowing out to the exits, a RALLY assembly sign — with the pixel crowd
/// walking the routes and a marshal at the centre. Everything is a pure function of elapsed time, frozen
/// under Reduce Motion.
private struct LandingDiorama: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: Scene graph (isometric grid units; the hero stands at the origin)

    /// A building block on the iso ground: footprint origin + size (grid units), height (grid units),
    /// and whether its roof is on fire (smoking).
    private struct Building {
        let gx: Double, gy: Double         // footprint near corner
        let w: Double, d: Double           // footprint width (x) and depth (y)
        let h: Double                      // height in grid units
        let smoking: Bool
    }

    private static let buildings: [Building] = [
        Building(gx: -3.6, gy: -1.7, w: 1.5, d: 1.3, h: 1.9, smoking: true),
        Building(gx: -1.6, gy: -3.6, w: 1.4, d: 1.4, h: 2.4, smoking: true),
        Building(gx: 1.8, gy: -3.1, w: 1.5, d: 1.3, h: 1.6, smoking: false),
        Building(gx: 2.6, gy: 0.4, w: 1.3, d: 1.5, h: 2.1, smoking: true),
        Building(gx: -3.2, gy: 2.0, w: 1.4, d: 1.2, h: 1.4, smoking: false),
        Building(gx: 0.7, gy: 3.0, w: 1.6, d: 1.2, h: 1.7, smoking: false),
    ]

    /// Exit doors the routes flow to — a grid point on the ground in front of a building, pushed well out
    /// from the centre so the routes are long and the marshal stands alone in the middle.
    private static let exits: [CGPoint] = [
        CGPoint(x: -2.5, y: -0.9),  // front of the left block
        CGPoint(x: -0.9, y: -2.4),  // front of the top-left block
        CGPoint(x: 2.0, y: 0.5),    // front of the right block
        CGPoint(x: 0.4, y: 2.1),    // front of the bottom block
    ]

    /// The little crowd, each walking the centre→exit line on a phase-shifted loop.
    private struct Walker {
        let exit: Int
        let speed: Double
        let offset: Double
        let mobility: MobilityClass
        let emotion: EmotionalState
    }

    // One walker per route — different directions, so they can never overlap each other, and the start
    // ring keeps them clear of the marshal at the centre.
    private static let walkers: [Walker] = [
        Walker(exit: 0, speed: 0.10, offset: 0.05, mobility: .adult, emotion: .calm),
        Walker(exit: 1, speed: 0.085, offset: 0.55, mobility: .elderly, emotion: .uneasy),
        Walker(exit: 2, speed: 0.11, offset: 0.30, mobility: .child, emotion: .calm),
        Walker(exit: 3, speed: 0.115, offset: 0.75, mobility: .adult, emotion: .calm),
    ]

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let tile = min(size.width / 7.0, size.height / 5.6)
            let origin = CGPoint(x: size.width / 2, y: size.height * 0.54)

            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let t = reduceMotion ? 6.0 : timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    Canvas { context, _ in
                        drawScene(&context, origin: origin, tile: tile, t: t)
                    }

                    // The marshal (RALLY) holds the centre-front, clearly the largest figure — the star.
                    PixelCharacter(mobility: .staff, emotion: .calm, seed: 101)
                        .frame(width: 74, height: 104)
                        .position(iso(0, 0.7, origin: origin, tile: tile).offsetBy(dy: -48))

                    ForEach(Array(Self.walkers.enumerated()), id: \.offset) { index, walker in
                        walkerView(walker, index: index, t: t, origin: origin, tile: tile)
                    }
                }
            }
        }
    }

    // MARK: Crowd overlay

    @ViewBuilder
    private func walkerView(_ walker: Walker, index: Int, t: Double, origin: CGPoint, tile: CGFloat) -> some View {
        let exit = Self.exits[walker.exit]
        let progress = fract(t * walker.speed + walker.offset)
        // Travel from ~two-thirds of the way out to the door, so the crowd hugs the exits (small, distant)
        // and the marshal owns the centre — the way the reference composes it.
        let gx = lerp(Double(exit.x) * 0.64, Double(exit.x), progress)
        let gy = lerp(Double(exit.y) * 0.64, Double(exit.y), progress)
        let p = iso(gx, gy, origin: origin, tile: tile)
        // Fade in on spawn, out as they reach the door, so the loop never pops.
        let edge = min(progress / 0.16, (1 - progress) / 0.16, 1)
        PixelCharacter(
            mobility: walker.mobility,
            emotion: walker.emotion,
            seed: 11 + index * 7,
            walking: true,
            mirrored: exit.x < 0
        )
        .frame(width: 28, height: 40)
        .opacity(max(0, edge) * 0.98)
        .position(p.offsetBy(dy: -22))
    }

    // MARK: Canvas scene

    private func drawScene(_ context: inout GraphicsContext, origin: CGPoint, tile: CGFloat, t: Double) {
        drawGround(&context, origin: origin, tile: tile)

        // Escape routes fan out from the centre to each exit — under the buildings so the crowd reads on top.
        for exit in Self.exits {
            drawRoute(&context, to: exit, origin: origin, tile: tile, t: t)
        }

        // Buildings, painted back-to-front (farther = smaller gx+gy) so nearer blocks overlap farther ones.
        for building in Self.buildings.sorted(by: { $0.gx + $0.gy < $1.gx + $1.gy }) {
            drawBuilding(&context, building, origin: origin, tile: tile)
            if building.smoking {
                let roof = iso(building.gx + building.w / 2, building.gy + building.d / 2, origin: origin, tile: tile)
                    .offsetBy(dy: -CGFloat(building.h) * tile * 0.5)
                drawSmoke(&context, base: roof, tile: tile, t: t, seed: Int(building.gx * 7 + building.gy))
            }
        }

        // The RALLY assembly sign, planted to the right of the block.
        drawRallySign(&context, at: iso(3.0, -1.4, origin: origin, tile: tile), tile: tile)
    }

    /// A faint iso ground plate — a diamond of drafting dots, so the block sits on "paper" not a void.
    private func drawGround(_ context: inout GraphicsContext, origin: CGPoint, tile: CGFloat) {
        let r = 3.6
        var plate = Path()
        plate.move(to: iso(-r, -r, origin: origin, tile: tile))
        plate.addLine(to: iso(r, -r, origin: origin, tile: tile))
        plate.addLine(to: iso(r, r, origin: origin, tile: tile))
        plate.addLine(to: iso(-r, r, origin: origin, tile: tile))
        plate.closeSubpath()
        context.fill(plate, with: .color(Color.egSurfaceSunken.opacity(0.5)))
        context.stroke(plate, with: .color(Color.egSeparator), lineWidth: 1)

        // Drafting dots on the iso lattice.
        var dots = Path()
        var gx = -r
        while gx <= r {
            var gy = -r
            while gy <= r {
                let p = iso(gx, gy, origin: origin, tile: tile)
                dots.addEllipse(in: CGRect(x: p.x - 0.8, y: p.y - 0.8, width: 1.6, height: 1.6))
                gy += 1.2
            }
            gx += 1.2
        }
        context.fill(dots, with: .color(Color.egSeparator.opacity(0.7)))
    }

    /// One cuboid building in ink-on-cream: top face, two shaded side faces, all in the charcoal line.
    private func drawBuilding(_ context: inout GraphicsContext, _ b: Building, origin: CGPoint, tile: CGFloat) {
        let top = CGFloat(b.h) * tile * 0.5
        // Ground corners (near, right, far, left going clockwise) and their raised roof counterparts.
        let n = iso(b.gx, b.gy + b.d, origin: origin, tile: tile)          // near (front) corner
        let r = iso(b.gx + b.w, b.gy + b.d, origin: origin, tile: tile)    // right
        let f = iso(b.gx + b.w, b.gy, origin: origin, tile: tile)          // far
        let l = iso(b.gx, b.gy, origin: origin, tile: tile)               // left
        let nT = n.offsetBy(dy: -top), rT = r.offsetBy(dy: -top)
        let fT = f.offsetBy(dy: -top), lT = l.offsetBy(dy: -top)

        // Left face (l→n) — the shadowed side (warm tan, so the block reads as solid on the cream).
        var left = Path()
        left.move(to: l); left.addLine(to: n); left.addLine(to: nT); left.addLine(to: lT); left.closeSubpath()
        context.fill(left, with: .color(Color(hex: 0xC9B189)))

        // Right face (n→r) — the lit side.
        var right = Path()
        right.move(to: n); right.addLine(to: r); right.addLine(to: rT); right.addLine(to: nT); right.closeSubpath()
        context.fill(right, with: .color(Color(hex: 0xDFC9A0)))

        // Roof — the lightest face, so the sun clearly hits the top.
        var roof = Path()
        roof.move(to: nT); roof.addLine(to: rT); roof.addLine(to: fT); roof.addLine(to: lT); roof.closeSubpath()
        context.fill(roof, with: .color(Color(hex: 0xFBF4E4)))

        // Ink outlines over everything.
        for edge in [left, right, roof] {
            context.stroke(edge, with: .color(Color.egOutline), lineWidth: 1.6)
        }
        // A couple of window slits on the lit face, for read.
        var windows = Path()
        let wU = lerp(n, r, 0.5)
        windows.move(to: wU.offsetBy(dy: -top * 0.35)); windows.addLine(to: wU.offsetBy(dy: -top * 0.7))
        context.stroke(windows, with: .color(Color.egOutline.opacity(0.5)), lineWidth: 1.4)
    }

    /// A green escape route from centre to an exit — a curved, dash-flowing line with an arrowhead and an
    /// EXIT plate at the door.
    private func drawRoute(_ context: inout GraphicsContext, to exit: CGPoint, origin: CGPoint, tile: CGFloat, t: Double) {
        let start = iso(0, 0, origin: origin, tile: tile)
        let end = iso(Double(exit.x), Double(exit.y), origin: origin, tile: tile)
        let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 - tile * 0.5)

        var route = Path()
        route.move(to: start)
        route.addQuadCurve(to: end, control: mid)
        context.stroke(
            route,
            with: .color(Color.egDataGreen),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 7], dashPhase: -t * 26)
        )

        // Arrowhead near the door, aimed along the tangent (control→end).
        let dir = direction(from: mid, to: end)
        drawArrowhead(&context, at: lerp(mid, end, 0.86), pointing: dir)

        // EXIT plate at the door.
        drawExitPlate(&context, at: end)
    }

    private func drawArrowhead(_ context: inout GraphicsContext, at point: CGPoint, pointing dir: CGVector) {
        let len: CGFloat = 9
        let perp = CGVector(dx: -dir.dy, dy: dir.dx)
        let tip = CGPoint(x: point.x + dir.dx * len, y: point.y + dir.dy * len)
        let a = CGPoint(x: point.x + perp.dx * len * 0.6, y: point.y + perp.dy * len * 0.6)
        let b = CGPoint(x: point.x - perp.dx * len * 0.6, y: point.y - perp.dy * len * 0.6)
        var head = Path()
        head.move(to: tip); head.addLine(to: a); head.addLine(to: b); head.closeSubpath()
        context.fill(head, with: .color(Color.egDataGreen))
    }

    private func drawExitPlate(_ context: inout GraphicsContext, at point: CGPoint) {
        let w: CGFloat = 38, h: CGFloat = 16
        let rect = CGRect(x: point.x - w / 2, y: point.y - h / 2, width: w, height: h)
        context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(Color.egDataGreenDeep))
        context.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(Color.egOutline), lineWidth: 1)
        context.draw(
            Text("EXIT").font(.system(size: 9.5, weight: .heavy, design: .monospaced)).foregroundColor(.egSurfaceRaised),
            at: point
        )
    }

    /// A small assembly-point billboard reading RALLY — the mascot's namesake muster sign.
    private func drawRallySign(_ context: inout GraphicsContext, at base: CGPoint, tile: CGFloat) {
        let boardW: CGFloat = 62, boardH: CGFloat = 26
        let board = CGRect(x: base.x - boardW / 2, y: base.y - tile * 1.4 - boardH, width: boardW, height: boardH)
        // Post.
        var post = Path()
        post.move(to: CGPoint(x: base.x, y: base.y)); post.addLine(to: CGPoint(x: base.x, y: board.maxY))
        context.stroke(post, with: .color(Color.egOutline), lineWidth: 3)
        // Board.
        context.fill(Path(roundedRect: board, cornerRadius: 5), with: .color(Color.egSurfaceRaised))
        context.stroke(Path(roundedRect: board, cornerRadius: 5), with: .color(Color.egOutline), lineWidth: 2)
        context.draw(
            Text("RALLY").font(.system(size: 13, weight: .heavy, design: .monospaced)).foregroundColor(.egDataGreenDeep),
            at: CGPoint(x: board.midX, y: board.midY)
        )
    }

    private func drawSmoke(_ context: inout GraphicsContext, base: CGPoint, tile: CGFloat, t: Double, seed: Int) {
        for i in 0 ..< 5 {
            let cycle = fract(t * 0.11 + Double(i) * 0.2 + Double(seed) * 0.37)
            let rise = CGFloat(cycle) * tile * 2.4
            let drift = CGFloat(sin(t * 0.6 + Double(i) + Double(seed))) * tile * 0.25
            let radius = tile * 0.22 + CGFloat(cycle) * tile * 0.5
            let alpha = (1 - cycle) * 0.34
            let rect = CGRect(
                x: base.x + drift - radius, y: base.y - rise - radius,
                width: radius * 2, height: radius * 2
            )
            context.fill(Path(ellipseIn: rect), with: .color(Color.egHazardSmoke.opacity(alpha)))
        }
    }

    // MARK: Isometric maths

    /// Project a grid point (gx east, gy south, origin at the hero) to a 2:1 isometric screen point.
    private func iso(_ gx: Double, _ gy: Double, origin: CGPoint, tile: CGFloat) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(gx - gy) * tile * 0.5,
            y: origin.y + CGFloat(gx + gy) * tile * 0.25
        )
    }

    private func direction(from a: CGPoint, to b: CGPoint) -> CGVector {
        let dx = b.x - a.x, dy = b.y - a.y
        let m = max(0.0001, hypot(dx, dy))
        return CGVector(dx: dx / m, dy: dy / m)
    }
}

// MARK: - Free helpers

private func fract(_ x: Double) -> Double { x - floor(x) }
private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * CGFloat(t), y: a.y + (b.y - a.y) * CGFloat(t))
}

private extension CGPoint {
    func offsetBy(dx: CGFloat = 0, dy: CGFloat = 0) -> CGPoint { CGPoint(x: x + dx, y: y + dy) }
}

#Preview {
    LandingView(onStart: {})
}
