import SwiftUI

/// The canvas camera's button controls — the map-style ＋ / － / fit stack that floats on the dark
/// game-screen, mirroring the gestures on `SimCanvasInputView` through the same `SimulationController`
/// camera. Zoom steps are multiplicative so each press feels the same at any scale; "fit" frames the
/// whole floor again and lets go of any followed person.
struct SimZoomControls: View {
    let controller: SimulationController

    /// One press = ×1.5 (in) or ÷1.5 (out). Multiplicative so a press feels even at every zoom level.
    private static let step: CGFloat = 1.5

    var body: some View {
        VStack(spacing: 0) {
            button(.zoomIn, label: "Zoom in") { controller.zoomCamera(by: Self.step) }
            divider
            button(.zoomOut, label: "Zoom out") { controller.zoomCamera(by: 1 / Self.step) }
            divider
            button(.fitView, label: "Fit floor") { controller.recenterCamera() }
        }
        .frame(width: 44)
        .egCanvasSurface(cornerRadius: EgressRadius.md)
    }

    private func button(_ symbol: AppSymbol, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(app: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.egCanvasText)
                .frame(width: 44, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.egCanvasSeparator.opacity(0.6))
            .frame(height: 1)
    }
}
