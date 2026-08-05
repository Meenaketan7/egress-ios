import CoreGraphics
import EgressEngine

// MARK: - WorldRect

/// An axis-aligned rectangle in world metres — the editor's content bounds and the camera's framing
/// target. Kept tiny and value-typed so `EditorModel.contentBounds` and the camera can pass it around.
struct WorldRect: Equatable {
    var origin: Vec2
    var size: Vec2

    var center: Vec2 {
        Vec2(origin.x + size.x / 2, origin.y + size.y / 2)
    }

    var maxCorner: Vec2 {
        Vec2(origin.x + size.x, origin.y + size.y)
    }
}

// MARK: - EditorCamera

/// The editor canvas camera — a pan/zoom transform over the free-form author space (design's
/// ReactFlow-style board). `pointsPerMetre` is the zoom; `center` is the world point (metres) held at
/// the middle of the viewport. `CanvasProjection(camera:viewSize:)` turns it into the same world↔screen
/// mapping the fixed simulation canvas uses, so every existing drawing / hit-test composes on top of it.
struct EditorCamera: Equatable {
    /// Zoom — screen points per world metre.
    var pointsPerMetre: CGFloat
    /// World point (metres) pinned to the centre of the viewport.
    var center: Vec2

    static let minZoom: CGFloat = 6 // ~ 66 m across a 400 pt view — the whole floor at a glance
    static let maxZoom: CGFloat = 160 // ~ 2.5 m span — fine placement
    static let defaultZoom: CGFloat = 34 // ~ 12 m across a 400 pt view — a room-sized default

    init(pointsPerMetre: CGFloat = EditorCamera.defaultZoom, center: Vec2 = Vec2(5.5, 4)) {
        self.pointsPerMetre = pointsPerMetre
        self.center = center
    }

    /// Pan by a screen-space finger delta (points). Dragging content right moves the camera centre the
    /// opposite way in world space, so the floor tracks the finger.
    mutating func pan(byScreen delta: CGSize) {
        guard pointsPerMetre > 0 else { return }
        center = Vec2(
            center.x - Double(delta.width / pointsPerMetre),
            center.y - Double(delta.height / pointsPerMetre)
        )
    }

    /// Multiply the zoom by `factor`, keeping the world point `anchor` under the same screen location
    /// (pinch-to-zoom about the pinch centroid; the ± buttons pass the view centre as the anchor).
    mutating func zoom(by factor: CGFloat, aroundWorld anchor: Vec2) {
        let target = Self.clampZoom(pointsPerMetre * factor)
        guard target != pointsPerMetre else { return }
        let ratio = Double(pointsPerMetre / target)
        center = Vec2(
            anchor.x - (anchor.x - center.x) * ratio,
            anchor.y - (anchor.y - center.y) * ratio
        )
        pointsPerMetre = target
    }

    /// Frame `bounds` centred in `viewSize`, with a little padding — the "fit to content" reset.
    mutating func fit(_ bounds: WorldRect, in viewSize: CGSize, padding: CGFloat = 36) {
        let w = max(bounds.size.x, 0.5)
        let h = max(bounds.size.y, 0.5)
        let usableW = max(1, viewSize.width - padding * 2)
        let usableH = max(1, viewSize.height - padding * 2)
        pointsPerMetre = Self.clampZoom(min(usableW / CGFloat(w), usableH / CGFloat(h)))
        center = bounds.center
    }

    static func clampZoom(_ z: CGFloat) -> CGFloat {
        min(max(z, minZoom), maxZoom)
    }
}
