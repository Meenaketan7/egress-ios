import EgressEngine
import SwiftUI

/// The editor's drawing surface — a free-form, pannable/zoomable board (design's ReactFlow-style
/// canvas). It paints the working venue with the same `VenueScenery` the live simulation uses — so what
/// you draw is exactly what runs — over an infinite dot grid, plus a translucent ghost of the element
/// under your finger and a dashed outline of the auto-derived room that will simulate. All touch input
/// lives in the overlaid `CanvasInputView`: one finger draws, two fingers pan, pinch zooms.
struct EditorCanvasView: View {
    let model: EditorModel
    @Environment(FeedbackServices.self) private var feedback: FeedbackServices?

    var body: some View {
        GeometryReader { geo in
            let projection = CanvasProjection(camera: model.camera, viewSize: geo.size)
            ZStack {
                Canvas { context, _ in
                    VenueScenery.drawEditorGrid(projection: projection, viewSize: geo.size, into: &context)
                    drawRoomShape(projection: projection, into: &context)
                    drawDerivedBounds(projection: projection, into: &context)
                    VenueScenery.drawWater(model.waterZones, projection: projection, into: &context)
                    VenueScenery.drawObstacles(model.obstacles, projection: projection, into: &context)
                    VenueScenery.drawWalls(model.walls, projection: projection, into: &context)
                    VenueScenery.drawExits(model.exits, projection: projection, labelled: true, into: &context)
                    drawIgnitions(model.ignitions, projection: projection, into: &context)
                    if let selection = model.selection {
                        drawSelection(selection, projection: projection, into: &context)
                        drawSelectionDimension(selection, projection: projection, into: &context)
                    }
                    if let draft = model.draft {
                        drawDraft(draft, projection: projection, into: &context)
                    }
                }
                CanvasInputView(model: model, feedback: feedback)
            }
            // The canvas is a drawing surface; VoiceOver users author through the inspector below. The
            // label summarises the current layout so the drawn state is still legible without sight.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Venue layout")
            .accessibilityValue(
                "\(model.walls.count) walls, \(model.exits.count) exits, \(model.obstacles.count) objects, "
                    + "\(model.waterZones.count) water zones, \(model.ignitions.count) fire points"
            )
        }
    }

    /// Dim the area *outside* the walls' enclosed room, so a non-rectangular shape (L, T, angled) reads
    /// at a glance — the bright, un-dimmed floor is the room people will actually occupy. Nothing to draw
    /// when the walls enclose nothing (the whole grid is floor), so bare presets look unchanged.
    private func drawRoomShape(projection: CanvasProjection, into context: inout GraphicsContext) {
        VenueScenery.drawExteriorShade(
            model.roomExterior, origin: model.contentBounds.origin,
            cellSize: SafetyStandards.cellSize, projection: projection, into: &context
        )
    }

    /// A dashed teal rectangle marking the room the engine will actually simulate — the base floor
    /// unioned with everything drawn. It follows the walls: draw beyond the starting floor and it grows,
    /// so the user always sees exactly what will run. A small caption reads out its metric size.
    private func drawDerivedBounds(projection: CanvasProjection, into context: inout GraphicsContext) {
        let bounds = model.contentBounds
        let rect = CGRect(
            origin: projection.point(bounds.origin),
            size: CGSize(width: projection.length(bounds.size.x), height: projection.length(bounds.size.y))
        )
        context.stroke(
            Path(rect),
            with: .color(.egCyan.opacity(0.45)),
            style: StrokeStyle(lineWidth: 1.5, dash: [7, 5])
        )
        context.draw(
            Text(String(format: "%.1f × %.1f m", bounds.size.x, bounds.size.y))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.egCyan.opacity(0.8)),
            at: CGPoint(x: rect.minX + 3, y: rect.minY - 3), anchor: .bottomLeading
        )
    }

    /// Editor-placed fire ignition points — a filled terracotta disc with a gold core, so an authored
    /// hazard reads at a glance on the dark canvas (the live run grows the actual fire from these).
    private func drawIgnitions(_ points: [Vec2], projection: CanvasProjection, into context: inout GraphicsContext) {
        let radius = max(5, projection.length(SafetyStandards.cellSize * 1.6))
        for point in points {
            let center = projection.point(point)
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.fill(Circle().path(in: rect), with: .color(.egHazardFire))
            let coreRect = rect.insetBy(dx: radius * 0.5, dy: radius * 0.5)
            context.fill(Circle().path(in: coreRect), with: .color(.egHazardFireCore))
        }
    }

    /// The teal highlight + handles around the element the Select tool has picked (design: cyan handles).
    private func drawSelection(_ selection: EditorSelection, projection: CanvasProjection, into context: inout GraphicsContext) {
        let tint = Color.egCyan
        switch selection {
        case let .obstacle(id):
            guard let object = model.obstacles.first(where: { $0.id == id }) else { return }
            strokeBox(origin: object.origin, size: object.size, tint: tint, projection: projection, into: &context)
        case let .water(id):
            guard let zone = model.waterZones.first(where: { $0.id == id }) else { return }
            strokeBox(origin: zone.origin, size: zone.size, tint: tint, projection: projection, into: &context)
        case let .exit(id):
            guard let exit = model.exits.first(where: { $0.id == id }) else { return }
            var path = Path()
            path.move(to: projection.point(exit.a))
            path.addLine(to: projection.point(exit.b))
            context.stroke(path, with: .color(tint), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        case let .ignition(index):
            guard model.ignitions.indices.contains(index) else { return }
            let center = projection.point(model.ignitions[index])
            let radius = max(9, projection.length(SafetyStandards.cellSize * 2.4))
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.stroke(Circle().path(in: rect), with: .color(tint), style: StrokeStyle(lineWidth: 2))
        }
    }

    /// A cyan selection frame + corner handles around a box (shared by objects and water zones).
    private func strokeBox(origin: Vec2, size: Vec2, tint: Color, projection: CanvasProjection, into context: inout GraphicsContext) {
        let p1 = projection.point(origin)
        let p2 = projection.point(origin + size)
        let rect = CGRect(
            x: min(p1.x, p2.x), y: min(p1.y, p2.y), width: abs(p2.x - p1.x), height: abs(p2.y - p1.y)
        ).insetBy(dx: -4, dy: -4)
        context.stroke(Path(roundedRect: rect, cornerRadius: 6), with: .color(tint), style: StrokeStyle(lineWidth: 2))
        for corner in [
            CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY)
        ] {
            let handle = CGRect(x: corner.x - 3.5, y: corner.y - 3.5, width: 7, height: 7)
            context.fill(Path(roundedRect: handle, cornerRadius: 1.5), with: .color(tint))
        }
    }

    /// The selected box's live dimensions, as a cyan pill above it (design's "Width: 2.0 m" call-out).
    /// Exits already carry their clear-width label via `drawExits`, so only boxes need this.
    private func drawSelectionDimension(_ selection: EditorSelection, projection: CanvasProjection, into context: inout GraphicsContext) {
        let box: (origin: Vec2, size: Vec2)? = switch selection {
        case let .obstacle(id): model.obstacles.first(where: { $0.id == id }).map { ($0.origin, $0.size) }
        case let .water(id): model.waterZones.first(where: { $0.id == id }).map { ($0.origin, $0.size) }
        default: nil
        }
        guard let box else { return }
        let anchor = projection.point(Vec2(box.origin.x + box.size.x / 2, box.origin.y))
        dimensionPill(
            String(format: "%.1f × %.1f m", box.size.x, box.size.y),
            at: CGPoint(x: anchor.x, y: anchor.y - 14), into: &context
        )
    }

    /// A small filled cyan pill with monospaced dark text — the design's dimension read-out chip.
    private func dimensionPill(_ text: String, at center: CGPoint, into context: inout GraphicsContext) {
        let resolved = context.resolve(
            Text(text).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.egCanvasBase)
        )
        let textSize = resolved.measure(in: CGSize(width: 260, height: 40))
        let padX: CGFloat = 5
        let padY: CGFloat = 3
        let rect = CGRect(
            x: center.x - textSize.width / 2 - padX, y: center.y - textSize.height / 2 - padY,
            width: textSize.width + padX * 2, height: textSize.height + padY * 2
        )
        context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(.egCyan))
        context.draw(resolved, at: center, anchor: .center)
    }

    /// The in-progress element, drawn dashed in the tool's tint, with a live measurement.
    private func drawDraft(_ draft: EditorDraft, projection: CanvasProjection, into context: inout GraphicsContext) {
        let tint = draft.tool.tint
        switch draft.tool {
        case .wall:
            var path = Path()
            path.move(to: projection.point(draft.start))
            path.addLine(to: projection.point(draft.current))
            let width = max(3, projection.length(SafetyStandards.cellSize * 1.6))
            context.stroke(
                path,
                with: .color(tint.opacity(0.7)),
                style: StrokeStyle(lineWidth: width, lineCap: .round, dash: [6, 4])
            )

        case .exit:
            var path = Path()
            path.move(to: projection.point(draft.start))
            path.addLine(to: projection.point(draft.current))
            context.stroke(
                path,
                with: .color(tint.opacity(0.85)),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [6, 4])
            )
            let mid = projection.point((draft.start + draft.current) / 2.0)
            context.draw(
                Text(String(format: "%.1f m", draft.start.distance(to: draft.current)))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(tint),
                at: CGPoint(x: mid.x, y: mid.y - 12), anchor: .center
            )

        case .obstacle, .water:
            let rect = boxRect(draft.start, draft.current, projection: projection)
            let shape = Path(roundedRect: rect, cornerRadius: 4)
            context.fill(shape, with: .color(tint.opacity(draft.tool == .water ? 0.3 : 0.25)))
            context.stroke(shape, with: .color(tint.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
            let w = abs(draft.current.x - draft.start.x)
            let h = abs(draft.current.y - draft.start.y)
            if w > 0.01 || h > 0.01 {
                context.draw(
                    Text(String(format: "%.1f × %.1f m", w, h))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(tint),
                    at: CGPoint(x: rect.midX, y: rect.minY - 8), anchor: .center
                )
            }

        case .select, .erase, .fire:
            break // select moves; erase acts on release; fire is a tap — none draw a ghost
        }
    }

    private func boxRect(_ a: Vec2, _ b: Vec2, projection: CanvasProjection) -> CGRect {
        let p1 = projection.point(a)
        let p2 = projection.point(b)
        return CGRect(x: min(p1.x, p2.x), y: min(p1.y, p2.y), width: abs(p2.x - p1.x), height: abs(p2.y - p1.y))
    }
}
