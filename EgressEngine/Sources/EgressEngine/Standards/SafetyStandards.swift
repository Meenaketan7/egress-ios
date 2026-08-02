import Foundation

/// Single source of truth for published crowd-safety constants.
///
/// The engine computes truth; the UI renders it; the AI only explains it —
/// no number, dimension, or standard originates anywhere but here.
public enum SafetyStandards {
    /// Grid cell edge length, in metres. Everything on the grid is metrically true.
    public static let cellSize: Double = 0.25

    /// Nominal agent body radius, in metres.
    public static let bodyRadius: Double = 0.22

    // Fruin crowd-density bands, persons·m⁻² (§2.8) — citable, so the coach quotes these verbatim.
    /// Below this: comfortable free movement.
    public static let densityComfortable: Double = 1.8
    /// At or above this: congested.
    public static let densityCongested: Double = 2.0
    /// At or above this: the at-risk band — where at-risk dwell begins to accrue.
    public static let densityAtRisk: Double = 5.0
    /// At or above this: the crush band — casualty risk.
    public static let densityCrush: Double = 7.0

    // Minimum clear widths, metres (§2.13.7) — citable assembly-egress minima the coach quotes.
    /// Door leaf minimum.
    public static let minDoorWidth: Double = 0.9
    /// Exit doorway minimum.
    public static let minExitWidth: Double = 1.2
    /// Assembly-corridor / aisle minimum.
    public static let minCorridorWidth: Double = 1.2
}
