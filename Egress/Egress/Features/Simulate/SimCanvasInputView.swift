import EgressEngine
import SwiftUI
import UIKit

/// The live canvas's input layer — the map-style camera for a *running* simulation. A transparent
/// `UIView` owns the touches so pan, pinch and tap coexist cleanly (SwiftUI's gestures can't tell a
/// one- from two-finger drag). It paints nothing; the `Canvas` beneath draws. Every screen→world
/// conversion goes through the same `CanvasProjection(camera:viewSize:)` the canvas renders with, so a
/// finger always lands on the person under it.
///
/// Unlike the editor there is no drawing tool here: any drag pans, a pinch zooms, and a **tap picks the
/// nearest person and follows them** (tap empty floor to let go). Buttons drive the same camera from the
/// overlay, so gesture and button stay in lock-step through the one `SimulationController.camera`.
struct SimCanvasInputView: UIViewRepresentable {
    let controller: SimulationController

    func makeCoordinator() -> Coordinator { Coordinator(controller: controller) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let coordinator = context.coordinator
        coordinator.view = view

        // Any drag (one or two fingers) pans the camera, like a map.
        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 2
        pan.delegate = coordinator
        view.addGestureRecognizer(pan)

        // Pinch zooms about the pinch centroid.
        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = coordinator
        view.addGestureRecognizer(pinch)

        // A tap picks the nearest person to follow (or lets go on empty floor).
        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = coordinator
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.controller = controller
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var controller: SimulationController
        weak var view: UIView?

        init(controller: SimulationController) { self.controller = controller }

        private func projection() -> CanvasProjection? {
            guard let size = view?.bounds.size, size.width > 0, size.height > 0 else { return nil }
            return CanvasProjection(camera: controller.camera, viewSize: size)
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view else { return }
            let translation = gesture.translation(in: view)
            controller.panCamera(byScreen: CGSize(width: translation.x, height: translation.y))
            gesture.setTranslation(.zero, in: view)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view, let projection = projection() else { return }
            guard gesture.state == .began || gesture.state == .changed else { return }
            let anchor = projection.world(gesture.location(in: view))
            controller.pinchCamera(by: gesture.scale, aroundWorld: anchor)
            gesture.scale = 1
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view, let projection = projection() else { return }
            controller.focusAgent(nearWorld: projection.world(gesture.location(in: view)))
        }

        /// Let pan and pinch fire together (map-style two-finger manipulation).
        nonisolated func gestureRecognizer(
            _ gesture: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            let hasPinch = gesture is UIPinchGestureRecognizer || other is UIPinchGestureRecognizer
            let hasPan = gesture is UIPanGestureRecognizer || other is UIPanGestureRecognizer
            return hasPinch && hasPan
        }
    }
}
