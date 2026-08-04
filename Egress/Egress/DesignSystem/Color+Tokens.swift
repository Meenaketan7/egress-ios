import SwiftUI
import UIKit

// MARK: - Hex initialisers

extension UIColor {
    /// 24-bit hex, e.g. 0x2B2622.
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
    /// 24-bit hex, e.g. 0xF4E8D0.
    init(hex: UInt, opacity: Double = 1) {
        self.init(uiColor: UIColor(hexValue: hex, alpha: opacity))
    }
}

// MARK: - Tokens — "Chunky charcoal outlines · cream ground · dark game-screen"

//
// The palette is one committed warm-editorial look (Egress App UI design request), not an adaptive
// dark/light pair, so every token is a FIXED value and the app is pinned to `.light` at the root.
// The one dark region is the simulation canvas: it stays a warm near-black game-screen so agents,
// density and hazards read, while the phone, HUD, cards and controls take the friendly cream shell.
// Hex values are lifted directly from the design source.

extension Color {
    // MARK: Cream shell — the chrome (adaptive-free; always cream)

    /// Page ground behind every chrome screen — the warm cream everything floats on.
    static let egGround = Color(hex: 0xF4E8D0)
    /// Raised card fill — a shade lighter than the ground so cards lift off it.
    static let egSurfaceRaised = Color(hex: 0xFBF4E4)
    /// Sunken / inset fill — chips, fields, secondary rows.
    static let egSurfaceSunken = Color(hex: 0xEADFC7)

    /// The signature chunky outline — charcoal, drawn thick around cards & controls.
    static let egOutline = Color(hex: 0x2B2622)
    /// Hairline divider inside the cream — a soft tan, not the charcoal outline.
    static let egSeparator = Color(hex: 0xCBB899)

    // Ink — warm charcoal → brown → taupe
    static let egTextPrimary = Color(hex: 0x2B2622) // charcoal headings & body
    static let egTextSecondary = Color(hex: 0x5A4D40) // brown — captions, stats
    static let egTextTertiary = Color(hex: 0x9E8E73) // taupe — micro-labels, hints

    // MARK: Accents

    /// The ONE green — primary buttons, PASS, toggles, the app tint. Sage.
    static let egDataGreen = Color(hex: 0x8DA85A)
    /// Sage shade for pressed states / green outlines.
    static let egDataGreenDeep = Color(hex: 0x738A4A)
    /// Measurement-only accent (dimension lines, "cyan" role). Teal.
    static let egCyan = Color(hex: 0x4F9691)

    /// Amber/gold — the wordmark squiggle, WARN, the seven-segment display.
    static let egAccentGold = Color(hex: 0xD6A63C)
    /// Terracotta — fire, at-risk, the nightclub mark, live warnings.
    static let egAccentTerracotta = Color(hex: 0xC65D32)
    /// Brick red — casualties, crush, FAIL.
    static let egAccentBrick = Color(hex: 0x9E3521)
    /// Soft pink — "Featured" badges, quiz cards.
    static let egAccentPink = Color(hex: 0xF3B6C0)
    /// Plum — staff agents / a rarer categorical hue.
    static let egAccentPlum = Color(hex: 0x8A5E74)

    // MARK: Dark game-screen — the simulation canvas (FIXED dark; forced via CanvasHost)

    // Values are the "Design Tokens" sheet's GROUND · SURFACE set for the dark canvas world.

    static let egCanvasBase = Color(hex: 0x2B2622) // canvas.base — warm dark game-screen
    static let egCanvasRaised = Color(hex: 0x4C4239) // surface.raised — dark cards/menus/panels on the canvas
    static let egCanvasSeparator = Color(hex: 0x5A4D40) // separator — dividers on the dark canvas
    static let egCanvasText = Color(hex: 0xF4E8D0) // text.primary — cream text/labels on the dark canvas
    static let egCanvasGrid = Color(hex: 0x4C4239) // 0.25 m dot grid
    static let egCanvasGridMajor = Color(hex: 0x5A4D40) // every 4 cells = 1.0 m
    static let egGlassTint = Color(hex: 0x2B2622, opacity: 0.78) // over a material, on the canvas

    // Density bands — on the dark canvas; opacity baked in (comfortable renders NO fill).
    static let egDensityComfortable = Color(hex: 0x26301A, opacity: 0.25) // faint green glow
    static let egDensityCongested = Color(hex: 0xD6A63C, opacity: 0.42) // gold
    static let egDensityAtRisk = Color(hex: 0xC65D32, opacity: 0.58) // terracotta
    static let egDensityCrush = Color(hex: 0x9E3521, opacity: 0.82) // brick

    // Density colour-blind textures (§5.6) — a brighter tint of each band, drawn as dots/hatch so the
    // crowding band reads by pattern as well as hue.
    static let egDensityCongestedPattern = Color(hex: 0xE7C56E, opacity: 0.75)
    static let egDensityAtRiskPattern = Color(hex: 0xD67A52, opacity: 0.82)
    static let egDensityCrushPattern = Color(hex: 0xF3B6C0, opacity: 0.9)

    // Hazards — on the dark canvas
    static let egHazardFire = Color(hex: 0xCF6A2C) // hazard.fire — terracotta flame
    static let egHazardFireCore = Color(hex: 0xE8B84A) // gold core
    static let egHazardSmoke = Color(hex: 0x8A7B66) // warm grey-brown (opacity per-use)
    static let egHazardFlood = Color(hex: 0x356178) // deep teal-blue — never reads as a dimension line

    // Verdict — sage / gold / brick (reads on both cream and the dark canvas)
    static let egVerdictPass = Color(hex: 0x8DA85A)
    static let egVerdictWarn = Color(hex: 0xD6A63C)
    static let egVerdictFail = Color(hex: 0x9E3521)

    // Agents — on the dark canvas. Calm reads pale; unease/panic climb the caution/danger ramp; staff = plum.
    static let egAgentCalm = Color(hex: 0xE4D6B6) // pale cream pixel-person
    static let egAgentUneasy = Color(hex: 0xD6A63C) // gold
    static let egAgentPanicked = Color(hex: 0xC65D32) // terracotta
    static let egAgentStaff = Color(hex: 0x8A5E74) // plum

    /// RALLY chassis — the tan pixel-robot (visor/antenna take the verdict tint).
    static let egRallyBody = Color(hex: 0xCBB899)

    // Props & structure on the canvas — warm browns (the furniture boxes).
    static let egPropFill = Color(hex: 0x6E5140) // prop.fill · relocatable — reads on the lighter base
    static let egPropEdge = Color(hex: 0x836E50)
    static let egPropStructural = Color(hex: 0x4A4037)
    static let egPropStructuralOutline = Color(hex: 0x6B5D4E)
    static let egDecorTile = Color(hex: 0x2B2723)
}
