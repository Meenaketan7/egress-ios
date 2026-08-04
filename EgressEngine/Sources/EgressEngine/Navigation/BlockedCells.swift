/// Rasterises a venue's impassable geometry — every wall segment and every obstacle
/// footprint — onto the grid, producing the `Set<GridCoord>` that `FlowField` floods
/// around (build plan §2.4: "Impassable = walls, obstacle footprints, active fire cells").
///
/// A prop's `isRelocatable` flag is deliberately ignored here: it governs only whether RALLY may
/// later propose *moving* a prop, not whether it blocks movement. A relocatable table and a
/// structural column are equally impassable while they sit where they are. Decor is the one class
/// that does not block — `blocksMovement` is `false` — so it is skipped (design: "Sim-inert").
public enum BlockedCells {
    public static func of(_ venue: VenueModel) -> Set<GridCoord> {
        var blocked: Set<GridCoord> = []
        for wall in venue.walls {
            rasterise(wall, of: venue.geometry, into: &blocked)
        }
        for obstacle in venue.obstacles where obstacle.blocksMovement {
            rasterise(obstacle, of: venue.geometry, into: &blocked)
        }
        return blocked
    }

    /// Every in-bounds cell an axis-aligned obstacle box overlaps. The far edges are half-open
    /// (matching `Obstacle.contains`), so a box flush with a cell boundary does not spill into
    /// the next cell.
    private static func rasterise(_ obstacle: Obstacle, of geometry: GridGeometry, into blocked: inout Set<GridCoord>) {
        let minCell = geometry.cell(for: obstacle.origin)
        let maxCell = geometry.cell(for: obstacle.origin + obstacle.size - Vec2(1e-9, 1e-9))
        guard minCell.x <= maxCell.x, minCell.y <= maxCell.y else { return }
        for gridY in minCell.y ... maxCell.y {
            for gridX in minCell.x ... maxCell.x {
                let cell = GridCoord(gridX, gridY)
                if geometry.size.contains(cell) {
                    blocked.insert(cell)
                }
            }
        }
    }

    /// Every cell a wall segment crosses, via a Bresenham grid walk. The 8-connected chain it
    /// produces is enough to seal the wall against `FlowField`'s 4-connected flood: to slip
    /// past a diagonal step the flood would have to move orthogonally through one of the two
    /// blocked corner cells, which it cannot.
    private static func rasterise(_ wall: Wall, of geometry: GridGeometry, into blocked: inout Set<GridCoord>) {
        let start = geometry.cell(for: wall.a)
        let end = geometry.cell(for: wall.b)
        let stepX = start.x < end.x ? 1 : (start.x > end.x ? -1 : 0)
        let stepY = start.y < end.y ? 1 : (start.y > end.y ? -1 : 0)
        let dx = abs(end.x - start.x)
        let dy = abs(end.y - start.y)
        var cell = start
        var err = dx - dy
        while true {
            if geometry.size.contains(cell) {
                blocked.insert(cell)
            }
            if cell == end {
                break
            }
            let e2 = 2 * err
            if e2 > -dy {
                err -= dy
                cell.x += stepX
            }
            if e2 < dx {
                err += dx
                cell.y += stepY
            }
        }
    }
}
