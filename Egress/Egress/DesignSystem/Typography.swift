import SwiftUI

/// Three voices, each with one job (design spec §4). All native — no bundling except the accent face.
enum EgressFont {
    /// DISPLAY base — SF Pro, heavy. Apply width/caps/tracking via `.egDisplay()`.
    static func display(_ style: Font.TextStyle = .largeTitle, weight: Font.Weight = .heavy) -> Font {
        .system(style, design: .default, weight: weight)
    }
    /// DATA base — SF Mono, medium.
    static func data(_ style: Font.TextStyle = .body, weight: Font.Weight = .medium) -> Font {
        .system(style, design: .monospaced, weight: weight)
    }
    /// BODY base — SF Pro Text.
    static func body(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }

    /// ACCENT — the bitmap/seven-segment face. ONLY for the wordmark, big score, PASS/WARN/FAIL.
    /// TODO: bundle the font, register it in Info.plist (UIAppFonts), confirm its PostScript name in Font Book,
    ///       then switch the fallback below to `.custom(accentName, size:relativeTo:)`.
    static let accentName = "REPLACE-WITH-BITMAP-FONT-POSTSCRIPT-NAME"
    static func accent(size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        // return .custom(accentName, size: size, relativeTo: style)   // ← once bundled (relativeTo = Dynamic Type)
        return .system(size: size, weight: .heavy, design: .monospaced) // temporary fallback
    }
}

extension View {
    /// DISPLAY: condensed (or compressed), heavy, ALL CAPS, tight tracking. Titles & headlines.
    func egDisplay(_ style: Font.TextStyle = .largeTitle, width: Font.Width = .condensed) -> some View {
        self.font(EgressFont.display(style))
            .fontWidth(width)          // SF Pro condensed/compressed (iOS 16+)
            .textCase(.uppercase)
            .tracking(-0.4)            // ≈ −1 to −2%
    }
    /// DATA: SF Mono, monospaced digits. Metrics, units, chips, timestamps.
    func egData(_ style: Font.TextStyle = .body, weight: Font.Weight = .medium) -> some View {
        self.font(EgressFont.data(style, weight: weight))
            .monospacedDigit()
    }
    /// BODY: SF Pro Text, sentence case, uncapped Dynamic Type. Prose a human reads.
    func egBody(_ style: Font.TextStyle = .body) -> some View {
        self.font(EgressFont.body(style))
    }
    /// MICRO-LABEL: tiny letterspaced uppercase mono in tertiary. Place directly above its value.
    func egMicroLabel() -> some View {
        self.font(.system(.caption2, design: .monospaced, weight: .medium))
            .textCase(.uppercase)
            .tracking(0.5)             // +4–8%
            .foregroundStyle(Color.egTextTertiary)
    }
}