import Foundation

/// A uniform-grid spatial hash for O(1)-average neighbour queries. The social force only needs the
/// handful of agents within its interaction range, not all N — so each substep we bin every agent
/// by position and look up only the bins overlapping that range. Without this, pairwise forces
/// would be O(N²) and the 200-agent budget would miss frame (build plan R-02).
///
/// Bins are keyed by a coarse cell coordinate at `binSize` (chosen ≈ the interaction range).
/// `candidates` returns indices into the array the hash was built from; the caller still checks
/// true distance and skips self, since a block of bins holds a little more than a disc.
public struct SpatialHash {
    private let binSize: Double
    private var bins: [GridCoord: [Int]]

    /// Builds the hash from one position per agent; the returned candidate indices index straight
    /// back into this array (and therefore into the agent array it came from).
    public init(positions: [Vec2], binSize: Double) {
        self.binSize = max(binSize, 1e-6)
        bins = [:]
        for (index, position) in positions.enumerated() {
            bins[bin(for: position), default: []].append(index)
        }
    }

    private func bin(for position: Vec2) -> GridCoord {
        GridCoord(Int(floor(position.x / binSize)), Int(floor(position.y / binSize)))
    }

    /// Every index whose bin lies within the block covering `radius` around `position` — a superset
    /// of the true neighbours, never missing one. Search half-width is `floor(radius/binSize) + 1`,
    /// because two points exactly `radius` apart can straddle a bin boundary and land two bins away.
    public func candidates(near position: Vec2, radius: Double) -> [Int] {
        let centre = bin(for: position)
        let reach = Int((radius / binSize).rounded(.down)) + 1
        var result: [Int] = []
        for dy in -reach ... reach {
            for dx in -reach ... reach {
                if let bucket = bins[GridCoord(centre.x + dx, centre.y + dy)] {
                    result.append(contentsOf: bucket)
                }
            }
        }
        return result
    }
}