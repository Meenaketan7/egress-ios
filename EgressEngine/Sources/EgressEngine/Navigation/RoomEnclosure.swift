/// Works out a venue's *true* floor when its walls form an enclosure. The editor is a free-form board
/// (design: "walls decide the shape and size"), so a room can be any polygon — L, T, angled — not just
/// the bounding rectangle. This floods the grid inward from its outer border through open cells,
/// treating **walls and exits as barriers** (so the flood can't leak in through a doorway), and returns
/// the cells the flood reaches: the *outside*. Feeding those into `VenueModel.blockedCells` leaves only
/// the enclosed interior as walkable floor, so people spawn and move only inside the shape the walls draw.
///
/// When the walls don't seal anything off — a bare preset with no walls, or an unfinished sketch —
/// there is no interior, so it returns an empty set and the whole grid stays floor exactly as before.
/// That keeps every wall-less venue (and every existing test) byte-for-byte unchanged.
public enum RoomEnclosure {
    /// The "outside" cells to block so only the walls' enclosed interior remains floor — or `[]` when the
    /// walls enclose nothing (in which case the caller should treat the whole grid as floor, as before).
    public static func exterior(walls: [Wall], exits: [Exit], geometry: GridGeometry) -> Set<GridCoord> {
        let size = geometry.size
        guard !size.isEmpty else { return [] }

        // Barriers: walls and exits, rasterised 8-connected so a 4-connected flood can't slip through.
        var barrier: Set<GridCoord> = []
        for wall in walls {
            rasterise(wall.a, wall.b, geometry: geometry, into: &barrier)
        }
        for exit in exits {
            rasterise(exit.a, exit.b, geometry: geometry, into: &barrier)
        }
        guard !barrier.isEmpty else { return [] } // no walls/exits ⇒ nothing can enclose ⇒ whole grid floor

        // Flood inward from every open border cell through open cells → the "outside".
        var exterior: Set<GridCoord> = []
        var stack: [GridCoord] = []
        func seed(_ c: GridCoord) {
            guard size.contains(c), !barrier.contains(c), !exterior.contains(c) else { return }
            exterior.insert(c)
            stack.append(c)
        }
        for x in 0 ..< size.width {
            seed(GridCoord(x, 0))
            seed(GridCoord(x, size.height - 1))
        }
        for y in 0 ..< size.height {
            seed(GridCoord(0, y))
            seed(GridCoord(size.width - 1, y))
        }
        while let c = stack.popLast() {
            for n in c.vonNeumannNeighbours where size.contains(n) && !barrier.contains(n) && !exterior.contains(n) {
                exterior.insert(n)
                stack.append(n)
            }
        }

        // If no open cell is sealed off from the border, there's no enclosure — leave the grid as floor.
        let interiorCount = size.count - barrier.count - exterior.count
        return interiorCount > 0 ? exterior : []
    }

    /// 8-connected Bresenham line rasterisation — the same watertight walk `BlockedCells` uses for walls.
    private static func rasterise(_ a: Vec2, _ b: Vec2, geometry: GridGeometry, into cells: inout Set<GridCoord>) {
        let start = geometry.cell(for: a)
        let end = geometry.cell(for: b)
        let stepX = start.x < end.x ? 1 : (start.x > end.x ? -1 : 0)
        let stepY = start.y < end.y ? 1 : (start.y > end.y ? -1 : 0)
        let dx = abs(end.x - start.x)
        let dy = abs(end.y - start.y)
        var cell = start
        var err = dx - dy
        while true {
            if geometry.size.contains(cell) {
                cells.insert(cell)
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
