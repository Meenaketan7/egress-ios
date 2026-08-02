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
                if let draft = model.draft {
                    drawDraft(draft, projection: projection, into: &context)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        model.dragChanged(
                            from: projection.world(value.startLocation),
                            to: projection.world(value.location)
                        )
                    }
                    .onEnded { value in
                        let outcome = model.dragEnded(
                            from: projection.world(value.startLocation),
                            to: projection.world(value.location)
                        )
                        switch outcome {
                        case .placed: feedback?.haptics.play(.elementPlaced)
                        case .erased: feedback?.haptics.play(.deleteConfirmed)
                        case .rejected: feedback?.haptics.play(.invalidPlacement)
                        case .none: break
                        }
                    }
            )
            // The canvas is a drawing surface; VoiceOver users author through the inspector below. The
            // label summarises the current layout so the drawn state is still legible without sight.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Venue layout")
            .accessibilityValue("\(model.walls.count) walls, \(model.exits.count) exits, \(model.obstacles.count) objects")
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

    /// The in-progress element, drawn dashed in the tool's tint.
    private func drawDraft(_ draft: EditorDraft, projection: CanvasProjection, into context: inout GraphicsContext) {
        let tint = draft.tool.tint
        switch draft.tool {
        case .wall:
            var path = Path()
            path.move(to: projection.point(draft.start))
            path.addLine(to: projection.point(draft.current))
            let width = max(3, projection.length(SafetyStandards.cellSize * 1.6))
            context.stroke(path, with: .color(tint.opacity(0.7)),
                           style: StrokeStyle(lineWidth: width, lineCap: .round, dash: [6, 4]))

        case .exit:
            var path = Path()
            path.move(to: projection.point(draft.start))
            path.addLine(to: projection.point(draft.current))
            context.stroke(path, with: .color(tint.opacity(0.85)),
                           style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [6, 4]))
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

        case .erase:
            break
        }
    }

    private func boxRect(_ a: Vec2, _ b: Vec2, projection: CanvasProjection) -> CGRect {
        let p1 = projection.point(a)
        let p2 = projection.point(b)
        return CGRect(x: min(p1.x, p2.x), y: min(p1.y, p2.y), width: abs(p2.x - p1.x), height: abs(p2.y - p1.y))
    }
}
