import EgressEngine
import SwiftUI

/// The editor's drawing surface. It paints the working venue with the same `VenueScenery` the live
/// simulation uses — so what you draw is exactly what runs — plus a translucent ghost of the element
/// currently under your finger. A single drag gesture, mapped back into world metres, places walls,
/// exits and objects (or erases them).
struct EditorCanvasView: View {
    let model: EditorModel
    @Environment(FeedbackServices.self) private var feedback: FeedbackServices?

    var body: some View {
        GeometryReader { geo in
            let projection = CanvasProjection(
                worldWidth: model.worldWidth,
                worldHeight: model.worldHeight,
                viewSize: geo.size
            )
            Canvas { context, _ in
                drawRoomOutline(projection: projection, into: &context)
                VenueScenery.drawGrid(venue: model.venue, projection: projection, into: &context)
                VenueScenery.drawObstacles(model.obstacles, projection: projection, into: &context)
                VenueScenery.drawWalls(model.walls, projection: projection, into: &context)
                VenueScenery.drawExits(model.exits, projection: projection, labelled: true, into: &context)
                drawIgnitions(model.ignitions, projection: projection, into: &context)
                if let selection = model.selection {
                    drawSelection(selection, projection: projection, into: &context)
                }
                if let draft = model.draft {
                    drawDraft(draft, projection: projection, into: &context)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let start = projection.world(value.startLocation)
                        let current = projection.world(value.location)
                        if model.tool == .select {
                            if !model.isMoving {
                                model.beginMove(near: start)
                            }
                            model.updateMove(from: start, to: current)
                        } else {
                            model.dragChanged(from: start, to: current)
                        }
                    }
                    .onEnded { value in
                        let start = projection.world(value.startLocation)
                        let current = projection.world(value.location)
                        if model.tool == .select {
                            let moved = model.isMoving && start.distance(to: current) > 0.2
                            model.endMove()
                            if moved {
                                feedback?.haptics.play(.elementPlaced)
                            } else {
                                model.select(near: current)
                                if model.selection != nil {
                                    feedback?.haptics.play(.toolTap)
                                }
                            }
                        } else {
                            let outcome = model.dragEnded(from: start, to: current)
                            switch outcome {
                            case .placed: feedback?.haptics.play(.elementPlaced)
                            case .erased: feedback?.haptics.play(.deleteConfirmed)
                            case .rejected: feedback?.haptics.play(.invalidPlacement)
                            case .none: break
                            }
                        }
                    }
            )
            // The canvas is a drawing surface; VoiceOver users author through the inspector below. The
            // label summarises the current layout so the drawn state is still legible without sight.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Venue layout")
            .accessibilityValue(
                "\(model.walls.count) walls, \(model.exits.count) exits, "
                    + "\(model.obstacles.count) objects, \(model.ignitions.count) fire points"
            )
        }
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

    /// A hairline rectangle marking the room's extent, so the drawable floor is unmistakable.
    private func drawRoomOutline(projection: CanvasProjection, into context: inout GraphicsContext) {
        let rect = CGRect(
            origin: projection.point(Vec2(0, 0)),
            size: CGSize(width: projection.length(model.worldWidth), height: projection.length(model.worldHeight))
        )
        context.stroke(Path(rect), with: .color(.egSeparator), lineWidth: 1)
    }

    /// The teal highlight + handles around the element the Select tool has picked (design: cyan handles).
    private func drawSelection(_ selection: EditorSelection, projection: CanvasProjection, into context: inout GraphicsContext) {
        let tint = Color.egCyan
        switch selection {
        case let .obstacle(id):
            guard let object = model.obstacles.first(where: { $0.id == id }) else { return }
            let p1 = projection.point(object.origin)
            let p2 = projection.point(object.origin + object.size)
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

    /// The in-progress element, drawn dashed in the tool's tint.
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

        case .obstacle:
            let rect = boxRect(draft.start, draft.current, projection: projection)
            let shape = Path(roundedRect: rect, cornerRadius: 4)
            context.fill(shape, with: .color(tint.opacity(0.25)))
            context.stroke(shape, with: .color(tint.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))

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
