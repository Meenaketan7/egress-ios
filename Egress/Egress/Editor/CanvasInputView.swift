import EgressEngine
import SwiftUI
import UIKit

/// The editor canvas's input layer. A single transparent `UIView` owns every touch, so one-finger
/// drawing — which SwiftUI's `DragGesture` can't distinguish from a two-finger camera move (it reports
/// no touch count) — coexists cleanly with two-finger pan and pinch-zoom, the ReactFlow-style camera the
/// design calls for. It paints nothing; the SwiftUI `Canvas` beneath draws. Every screen→world
/// conversion goes through the same `CanvasProjection(camera:viewSize:)` the canvas renders with, so the
/// finger and the ink never drift apart.
struct CanvasInputView: UIViewRepresentable {
    let model: EditorModel
    var feedback: FeedbackServices?

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model, feedback: feedback)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let coordinator = context.coordinator
        coordinator.view = view

        // One finger drives the active tool (draw / move); a tap selects, drops fire, or erases.
        let toolPan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleToolPan(_:)))
        toolPan.maximumNumberOfTouches = 1
        toolPan.delegate = coordinator
        view.addGestureRecognizer(toolPan)

        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = coordinator
        view.addGestureRecognizer(tap)

        // Two fingers move the camera; pinch zooms it — recognised together, like a map.
        let cameraPan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleCameraPan(_:)))
        cameraPan.minimumNumberOfTouches = 2
        cameraPan.maximumNumberOfTouches = 2
        cameraPan.delegate = coordinator
        view.addGestureRecognizer(cameraPan)

        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = coordinator
        view.addGestureRecognizer(pinch)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.model = model
        context.coordinator.feedback = feedback
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var model: EditorModel
        var feedback: FeedbackServices?
        weak var view: UIView?
        init(model: EditorModel, feedback: FeedbackServices?) {
            self.model = model
            self.feedback = feedback
        }

        private func projection() -> CanvasProjection? {
            guard let size = view?.bounds.size, size.width > 0, size.height > 0 else { return nil }
            return CanvasProjection(camera: model.camera, viewSize: size)
        }

        // MARK: One finger — the active tool

        @objc func handleToolPan(_ gesture: UIPanGestureRecognizer) {
            guard let view, let projection = projection() else { return }
            let location = gesture.location(in: view)
            // A UIPanGestureRecognizer only *begins* after a few points of slop, so its `.began` location
            // is already past the finger-down point. Recover the true start by subtracting the gesture's
            // cumulative translation — otherwise every wall/box starts short and drawn corners never meet.
            let translation = gesture.translation(in: view)
            let start = projection.world(CGPoint(x: location.x - translation.x, y: location.y - translation.y))
            let current = projection.world(location)
            switch gesture.state {
            case .began, .changed:
                if model.tool == .select {
                    if gesture.state == .began {
                        model.beginMove(near: start)
                    }
                    model.updateMove(from: start, to: current)
                } else {
                    model.dragChanged(from: start, to: current)
                }
            case .ended:
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
                    play(model.dragEnded(from: start, to: current))
                }
            case .cancelled, .failed:
                if model.tool == .select {
                    model.endMove()
                } else {
                    _ = model.dragEnded(from: current, to: current) // clears the in-progress ghost
                }
            default:
                break
            }
        }

        // MARK: Tap — select / drop fire / erase

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view, let projection = projection() else { return }
            let p = projection.world(gesture.location(in: view))
            switch model.tool {
            case .select:
                model.select(near: p)
                if model.selection != nil {
                    feedback?.haptics.play(.toolTap)
                }
            case .fire, .erase:
                play(model.dragEnded(from: p, to: p)) // a tap drops fire / erases the nearest element
            default:
                break // wall / exit / object / water need a drag — a tap does nothing
            }
        }

        // MARK: Two fingers — pan and pinch the camera

        @objc func handleCameraPan(_ gesture: UIPanGestureRecognizer) {
            guard let view else { return }
            let translation = gesture.translation(in: view)
            model.camera.pan(byScreen: CGSize(width: translation.x, height: translation.y))
            gesture.setTranslation(.zero, in: view)
            model.clearSelection() // keep a moving camera from fighting a lingering selection pad
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let view, let projection = projection() else { return }
            guard gesture.state == .began || gesture.state == .changed else { return }
            let anchor = projection.world(gesture.location(in: view))
            model.camera.zoom(by: gesture.scale, aroundWorld: anchor)
            gesture.scale = 1
        }

        private func play(_ outcome: EditPlacement) {
            switch outcome {
            case .placed: feedback?.haptics.play(.elementPlaced)
            case .erased: feedback?.haptics.play(.deleteConfirmed)
            case .rejected: feedback?.haptics.play(.invalidPlacement)
            case .none: break
            }
        }

        /// Let the two-finger pan and the pinch fire together (map-style). One-finger gestures can't
        /// overlap the two-finger ones by touch count, so this stays out of the drawing path.
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
