import SwiftUI
import UIKit

// MARK: - AppSymbol

/// Central registry of every SF Symbol the app uses, each with an optional fallback.
/// The single place to fix symbols the plan flags to confirm on iOS 26.
/// Zero-dependency stand-in for SFSafeSymbols.
enum AppSymbol: String, CaseIterable {
    // Tab bar
    case spaces = "square.grid.2x2"
    case simulate = "play.circle"
    case learn = "book"

    // HUD / metrics
    case density = "gauge.medium" // 🔴 confirm on iOS 26 → fallback "gauge"
    case people = "person.3.fill"
    case timer
    case exit = "figure.walk.departure" // 🟡 confirm → fallback "arrow.right.to.line"

    // Verdict
    case pass = "checkmark.seal.fill"
    case warn = "exclamationmark.triangle.fill"
    case fail = "xmark.octagon.fill"

    // Playback
    case play = "play.fill"
    case pause = "pause.fill"
    case restart = "arrow.counterclockwise"
    case stepBack = "backward.fill"

    // Editor / tools
    case wall = "pencil.line"
    case door = "door.left.hand.open" // 🟡 confirm → fallback "rectangle.portrait"
    case obstacle = "square.dashed"
    case settings = "gearshape"

    /// Fallback if the primary symbol might be unavailable on the running OS.
    var fallback: String? {
        switch self {
        case .density: "gauge"
        case .exit: "arrow.right.to.line"
        case .door: "rectangle.portrait"
        default: nil
        }
    }
}

extension Image {
    /// Registry image with runtime fallback; last resort is a visible marker (never a silent blank).
    init(app symbol: AppSymbol) {
        if UIImage(systemName: symbol.rawValue) != nil {
            self.init(systemName: symbol.rawValue)
        } else if let fb = symbol.fallback, UIImage(systemName: fb) != nil {
            self.init(systemName: fb)
        } else {
            self.init(systemName: "questionmark.square.dashed")
        }
    }
}

extension Label where Title == Text, Icon == Image {
    /// Label from a registry symbol — for tab items and rows.
    init(_ title: String, app symbol: AppSymbol) {
        self.init { Text(title) } icon: { Image(app: symbol) }
    }
}
