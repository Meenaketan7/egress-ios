/// 2-D vector in metres, backed by SIMD2<Double> for vectorised math.
public typealias Vec2 = SIMD2<Double>

public extension SIMD2 where Scalar == Double {
    /// Euclidean length ‖v‖.
    var length: Double { (x * x + y * y).squareRoot() }

    /// Squared length — cheaper than `length` (no square root). Use it when only comparing magnitudes.
    var lengthSquared: Double { x * x + y * y }

    /// Unit vector. Returns `.zero` for a (near-)zero vector, so force accumulation never yields NaN.
    var normalized: Vec2 {
        let len = length
        return len > 1e-12 ? self / len : .zero
    }

    func distance(to other: Vec2) -> Double { (self - other).length }

    func dot(_ other: Vec2) -> Double { x * other.x + y * other.y }
}
