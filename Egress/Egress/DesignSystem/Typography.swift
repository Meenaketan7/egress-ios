import SwiftUI

// MARK: - EgressFont

//
// The design specifies four Google faces:
//   • DISPLAY  — Zilla Slab (slab serif, title-case headings)
//   • BODY     — Nunito (warm rounded humanist sans)
//   • DATA     — IBM Plex Mono (metrics, units, chips)
//   • MICRO    — Saira Condensed (letterspaced uppercase labels)
//   • ACCENT   — Press Start 2P (wordmark) + DSEG7 Classic (seven-segment score)
//
// None ship with iOS, so each maps to the closest native design that carries the same character:
// serif → New York, rounded → SF Rounded, monospaced → SF Mono, condensed → SF condensed width.
// To use the exact faces, drop the .ttf files in the target, add them to `UIAppFonts`
// (Info.plist), and swap the `.system(design:)` calls below for `.custom(_,size:relativeTo:)`.

enum EgressFont {
    /// DISPLAY base — serif (New York ≈ Zilla Slab), bold, title-case. Apply via `.egDisplay()`.
    static func display(_ style: Font.TextStyle = .largeTitle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .serif, weight: weight)
    }

    /// DATA base — monospaced (SF Mono ≈ IBM Plex Mono), medium.
    static func data(_ style: Font.TextStyle = .body, weight: Font.Weight = .medium) -> Font {
        .system(style, design: .monospaced, weight: weight)
    }

    /// BODY base — rounded humanist (SF Rounded ≈ Nunito).
    static func body(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    /// ACCENT — the seven-segment / pixel face. ONLY for the wordmark, big score, PASS/WARN/FAIL.
    /// TODO: bundle "DSEG7 Classic" (score) and "Press Start 2P" (wordmark), register them in
    ///       UIAppFonts, confirm the PostScript names in Font Book, then switch the fallback below
    ///       to `.custom(accentName, size:, relativeTo:)` (relativeTo keeps Dynamic Type scaling).
    static let accentName = "DSEG7Classic-Regular"
    static func accent(size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        // return .custom(accentName, size: size, relativeTo: style)   // ← once bundled
        return .system(size: size, weight: .heavy, design: .monospaced) // temporary fallback
    }
}

extension View {
    /// DISPLAY: serif, bold, title-case (sentence case preserved). Titles & headlines.
    func egDisplay(_ style: Font.TextStyle = .largeTitle, weight: Font.Weight = .bold) -> some View {
        self.font(EgressFont.display(style, weight: weight))
    }

    /// DATA: monospaced digits. Metrics, units, chips, timestamps.
    func egData(_ style: Font.TextStyle = .body, weight: Font.Weight = .medium) -> some View {
        self.font(EgressFont.data(style, weight: weight))
            .monospacedDigit()
    }

    /// BODY: rounded, sentence case, uncapped Dynamic Type. Prose a human reads.
    func egBody(_ style: Font.TextStyle = .body) -> some View {
        self.font(EgressFont.body(style))
    }

    /// MICRO-LABEL: tiny letterspaced uppercase condensed sans (≈ Saira Condensed) in taupe.
    /// Place directly above its value.
    func egMicroLabel() -> some View {
        self.font(.system(.caption2, weight: .semibold))
            .fontWidth(.condensed)
            .textCase(.uppercase)
            .tracking(0.8) // +6–8%
            .foregroundStyle(Color.egTextTertiary)
    }
}
