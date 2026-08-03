#if DEBUG
import SwiftUI
import UIKit

// MARK: - Touch indicators (§E.3 — recording aid, DEBUG only)

//
// Draws a translucent ring wherever a finger is touching, so a screen recording shows where taps land
// without a hardware overlay. Passive: a window-level recogniser that never enters a recognised state,
// never cancels a view's touches, and recognises simultaneously with everything — so it observes without
// altering a single gesture. The whole file is behind `#if DEBUG`; it cannot ship.

extension View {
    /// Overlay live touch rings for screen recordings. No-op in release builds (compiled out entirely).
    func touchIndicators() -> some View {
        modifier(TouchIndicatorModifier())
    }
}

private struct TouchIndicatorModifier: ViewModifier {
    @State private var points: [CGPoint] = []

    func body(content: Content) -> some View {
        content.overlay {
            ZStack(alignment: .topLeading) {
                TouchCaptureView(points: $points)
                ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(Color.egDataGreen.opacity(0.28))
                        .overlay(Circle().strokeBorder(Color.egDataGreen.opacity(0.85), lineWidth: 1.5))
                        .frame(width: 38, height: 38)
                        .position(p)
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }
}

private struct TouchCaptureView: UIViewRepresentable {
    @Binding var points: [CGPoint]

    func makeUIView(context: Context) -> CaptureView {
        let view = CaptureView()
        view.onChange = { points = $0 }
        return view
    }

    func updateUIView(_ uiView: CaptureView, context: Context) {}
}

private final class CaptureView: UIView {
    var onChange: (([CGPoint]) -> Void)?
    private var installed = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !installed, let window else { return }
        installed = true
        let recogniser = PassiveTouchRecognizer()
        recogniser.reporter = { [weak self, weak window] touches in
            guard let self, let window else { return }
            self.onChange?(touches.map { $0.location(in: window) })
        }
        recogniser.delegate = recogniser
        recogniser.cancelsTouchesInView = false
        recogniser.delaysTouchesBegan = false
        recogniser.delaysTouchesEnded = false
        window.addGestureRecognizer(recogniser)
    }
}

/// A recogniser that only *watches*: it accumulates active touches and reports their locations, but
/// never leaves `.possible`, so it never recognises, never cancels, and never blocks another gesture.
private final class PassiveTouchRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    var reporter: ((Set<UITouch>) -> Void)?
    private var active = Set<UITouch>()

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        active.formUnion(touches)
        reporter?(active)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        reporter?(active)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        active.subtract(touches)
        reporter?(active)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        active.subtract(touches)
        reporter?(active)
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldReceive _: UITouch) -> Bool {
        true
    }
}
#endif
