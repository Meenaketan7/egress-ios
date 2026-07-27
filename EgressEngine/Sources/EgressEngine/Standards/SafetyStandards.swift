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
}
