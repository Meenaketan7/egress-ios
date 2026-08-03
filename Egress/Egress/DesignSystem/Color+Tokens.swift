import SwiftUI
import UIKit

// MARK: - Hex initialisers

extension UIColor {
    /// 24-bit hex, e.g. 0x34E27A.
    convenience init(hexValue: UInt, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hexValue >> 16) & 0xFF) / 255,
            green: CGFloat((hexValue >> 8) & 0xFF) / 255,
            blue: CGFloat(hexValue & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    /// 24-bit hex, e.g. 0x0A0E14.
    init(hex: UInt, opacity: Double = 1) {
        self.init(uiColor: UIColor(hexValue: hex, alpha: opacity))
    }
}

/// Resolves dark vs light automatically. Used only for chrome that adapts.
private func egDynamic(dark: UInt, light: UInt) -> Color {
    Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hexValue: dark)
            : UIColor(hexValue: light)
    })
}

// MARK: - Tokens (design spec §5)

extension Color {
    // Canvas & grid — FIXED. The sim canvas + HUD stay dark even in Light Mode
    // (enforced at the view level with .preferredColorScheme(.dark) on that subtree).
    static let egCanvasBase = Color(hex: 0x0A0E14)
    static let egCanvasGrid = Color(hex: 0x1B2430) // 0.25 m dot grid
    static let egCanvasGridMajor = Color(hex: 0x26323F) // every 4 cells = 1.0 m
    static let egGlassTint = Color(hex: 0x131A24, opacity: 0.72) // over a material

    // Chrome surfaces & text — ADAPTIVE
    static let egSurfaceRaised = egDynamic(dark: 0x161E2A, light: 0xF5F7FA)
    static let egSeparator = egDynamic(dark: 0x2A3644, light: 0xD8DEE6) // 1 pt hairlines
    static let egTextPrimary = egDynamic(dark: 0xE8EEF5, light: 0x0E1620)
    static let egTextSecondary = egDynamic(dark: 0x9AA9BA, light: 0x4A5766)
    static let egTextTertiary = egDynamic(dark: 0x74849A, light: 0x6B7889)

    // Accents — the ONLY green; cyan is measurement-only
    static let egDataGreen = egDynamic(dark: 0x34E27A, light: 0x0F9D52)
    static let egCyan = egDynamic(dark: 0x4FD8FF, light: 0x0A7EA4)

    // Density bands — FIXED, opacity baked in (comfortable renders NO fill; color kept for reference)
    static let egDensityComfortable = Color(hex: 0x1E5C46, opacity: 0.25)
    static let egDensityCongested = Color(hex: 0xC98A2E, opacity: 0.45)
    static let egDensityAtRisk = Color(hex: 0xE8632B, opacity: 0.65)
    static let egDensityCrush = Color(hex: 0xFF2D4B, opacity: 0.85)

    // Density colour-blind textures (§5.6) — a brighter tint of each band, drawn as dots/hatch over the
    // fill so the crowding band reads by pattern as well as hue.
    static let egDensityCongestedPattern = Color(hex: 0xFFDD8A, opacity: 0.7)
    static let egDensityAtRiskPattern = Color(hex: 0xFFB48A, opacity: 0.8)
    static let egDensityCrushPattern = Color(hex: 0xFFC2CE, opacity: 0.9)

    // Hazards — FIXED
    static let egHazardFire = Color(hex: 0xFF6B1A)
    static let egHazardFireCore = Color(hex: 0xFFD24A)
    static let egHazardSmoke = Color(hex: 0x8B95A3) // opacity applied per-use (variable)
    static let egHazardFlood = Color(hex: 0x1E63D6) // deep blue — never reads as a dimension line

    // Verdict — ADAPTIVE
    static let egVerdictPass = egDynamic(dark: 0x34E27A, light: 0x0F9D52)
    static let egVerdictWarn = egDynamic(dark: 0xF5B93B, light: 0x9A6B00)
    static let egVerdictFail = egDynamic(dark: 0xFF3B5C, light: 0xC2001E)

    // Agents — FIXED (uneasy/panicked deliberately share caution/danger ramps; staff = violet)
    static let egAgentCalm = Color(hex: 0xB8C6D6)
    static let egAgentUneasy = Color(hex: 0xF5B93B)
    static let egAgentPanicked = Color(hex: 0xFF3B5C)
    static let egAgentStaff = Color(hex: 0x7B5CFF)

    /// RALLY chassis — FIXED (visor/antenna take the verdict tint)
    static let egRallyBody = Color(hex: 0xC7D3E0)

    // PROPOSED — outside the plan's token table; pending contrast verification (spec §5).
    static let egPropFill = Color(hex: 0x232E3C)
    static let egPropEdge = Color(hex: 0x3A4859)
    static let egPropStructural = Color(hex: 0x1C242F)
    static let egPropStructuralOutline = Color(hex: 0x46566A)
    static let egDecorTile = Color(hex: 0x141C26)
}
