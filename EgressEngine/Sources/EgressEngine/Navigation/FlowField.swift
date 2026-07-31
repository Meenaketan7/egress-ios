/// A static navigation field over the venue grid: for every cell, the shortest walking distance
/// (in cells, routing around walls and obstacles) to the *nearest* exit, plus the downhill
/// direction agents steer along. Built once per run with a multi-source breadth-first search
/// seeded from every exit cell at distance 0 — unit edge costs make Dijkstra collapse to BFS,
/// which is why the field is exact and free of local minima: an agent that always steps downhill
/// reaches an exit whenever one is reachable at all.
public struct FlowField: Sendable {
    public let size: GridSize
    /// BFS distance in cells from the nearest exit; `Int.max` marks blocked or unreachable cells.
    private let steps: [Int]

    public init(size: GridSize, blocked: Set<GridCoord>, exits: [GridCoord]) {
        self.size = size
        var dist = [Int](repeating: .max, count: max(0, size.count))
        var frontier: [GridCoord] = []

        // Seed every open exit cell at distance 0.
        for exit in exits {
            guard let index = size.index(of: exit), !blocked.contains(exit) else { continue }
            if dist[index] != 0 {
                dist[index] = 0
                frontier.append(exit)
            }
        }

        // Flood outward. `frontier` + `head` is a FIFO queue; BFS settles cells shortest-first.
        var head = 0
        while head < frontier.count {
            let cell = frontier[head]
            head += 1
            guard let cellIndex = size.index(of: cell) else { continue }
            let next = dist[cellIndex] + 1
            for neighbour in cell.vonNeumannNeighbours {
                guard let neighbourIndex = size.index(of: neighbour),
                      !blocked.contains(neighbour),
                      dist[neighbourIndex] > next else { continue }
                dist[neighbourIndex] = next
                frontier.append(neighbour)
            }
        }
        steps = dist
    }

    /// Distance in cells to the nearest exit; `Int.max` if blocked, unreachable, or out of bounds.
    public func cost(at cell: GridCoord) -> Int {
        guard let index = size.index(of: cell) else { return .max }
        return steps[index]
    }

    public func isReachable(_ cell: GridCoord) -> Bool {
        cost(at: cell) != .max
    }

    /// Unit vector pointing downhill toward the nearest exit; `.zero` at an exit, or on a blocked,
    /// unreachable, or perfectly flat cell (there the caller holds its current heading).
    public func direction(at cell: GridCoord) -> Vec2 {
        let here = cost(at: cell)
        guard here != .max, here > 0 else { return .zero }

        // A blocked/off-grid neighbour reads as "same cost as here" — it neither pulls nor pushes.
        func sample(_ neighbour: GridCoord) -> Double {
            let value = cost(at: neighbour)
            return value == .max ? Double(here) : Double(value)
        }
        let costLeft = sample(GridCoord(cell.x - 1, cell.y))
        let costRight = sample(GridCoord(cell.x + 1, cell.y))
        let costUp = sample(GridCoord(cell.x, cell.y - 1))
        let costDown = sample(GridCoord(cell.x, cell.y + 1))

        let gradient = Vec2(costRight - costLeft, costDown - costUp) // points toward *higher* cost
        return (-gradient).normalized // ...so negate to head toward the exit
    }
}
