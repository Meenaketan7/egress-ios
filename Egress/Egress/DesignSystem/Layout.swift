import SwiftUI

/// Radius scale — exact tokens from design spec §6. All corners are continuous/squircle.
enum EgressRadius {
    static let xs: CGFloat = 8      // chips, density pills, tool buttons
    static let sm: CGFloat = 12     // inline fields, sparkline tiles, thumbnails
    static let md: CGFloat = 16     // HUD bar, timeline container
    static let lg: CGFloat = 20     // library cards
    static let xl: CGFloat = 26     // RALLY card
    static let sheet: CGFloat = 28  // all sheets
}

/// Spacing scale — 4-pt based defaults ("air is a feature" in chrome). Reconcile against final design.
enum EgressSpacing {
    static let hairline: CGFloat = 1
    static let xxs: CGFloat = 2
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
}

enum EgressLayout {
    static let minTouchTarget: CGFloat = 44   // spec §6 — at every type size
    /// Concentric rule: a nested element's radius = outer radius − its padding.
    static func innerRadius(outer: CGFloat, padding: CGFloat) -> CGFloat {
        max(0, outer - padding)
    }
}

extension RoundedRectangle {
    /// The app's default rounded rectangle — always continuous-corner.
    static func egSquircle(_ radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }
}