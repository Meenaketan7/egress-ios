import Foundation

/// The fire cellular automaton (§2.7). Every cell cycles `unburnt → igniting → burning → burnt`.
/// Each tick, burning cells try to ignite flammable neighbours with `p = 1 − exp(−FIRE_SPREAD·Δt)`
/// (diagonals at 0.7× the rate); a fresh cell smoulders for `IGNITION_DELAY` before it burns and can
/// spread, and burns for `BURN_DURATION` before it is spent. Burning and igniting cells are both
/// impassable and harmful. A pure, seeded value: the caller supplies the flammable mask and the
/// ignition seeds and reads back the active-fire set, so it unit-tests with no `Simulation`.
public struct FireAutomaton: Sendable, Equatable {
    /// A cell's place in the burn cycle.
    public enum Cell: Sendable, Equatable {
        case unburnt, igniting, burning, burnt
    }

    public let size: GridSize
    /// Per-cell burn state, indexed by `size.index(of:)`.
    public private(set) var cells: [Cell]
    /// Seconds the cell has spent in its current state — drives the igniting/burning transitions.
    private var elapsed: [Double]
    /// Which cells can catch at all (walls and off-floor cells never burn).
    private let flammable: [Bool]

    /// Seeds start as `igniting`, so a placed fire takes `IGNITION_DELAY` to fully catch.
    public init(size: GridSize, flammable: [Bool], ignition: [GridCoord]) {
        self.size = size
        self.flammable = flammable
        cells = [Cell](repeating: .unburnt, count: size.count)
        elapsed = [Double](repeating: 0, count: size.count)
        for seed in ignition {
            if let index = size.index(of: seed) { cells[index] = .igniting }
        }
    }

    /// Advance the automaton one hazard tick. `rng` is drawn only for live spread attempts, in a fixed
    /// cell/neighbour order, so a given seed reproduces the run exactly.
    public mutating func tick(dt: Double, rng: inout SeededRNG) {
        guard !size.isEmpty, dt > 0 else { return }

        // Phase 1 — spread from the cells burning at the START of the tick.
        let pOrthogonal = 1 - exp(-SimConstants.fireSpread * dt)
        let pDiagonal = 1 - exp(-SimConstants.fireSpread * 0.7 * dt)
        var newlyIgnited: [Int] = []
        var claimed = [Bool](repeating: false, count: size.count)
        for index in cells.indices where cells[index] == .burning {
            for (neighbour, diagonal) in neighbours(of: size.coord(atIndex: index)) {
                guard let target = size.index(of: neighbour),
                      flammable[target], cells[target] == .unburnt, !claimed[target] else { continue }
                if Double.random(in: 0 ..< 1, using: &rng) < (diagonal ? pDiagonal : pOrthogonal) {
                    claimed[target] = true
                    newlyIgnited.append(target)
                }
            }
        }

        // Phase 2 — advance timers on the pre-tick states.
        for index in cells.indices {
            switch cells[index] {
            case .igniting:
                elapsed[index] += dt
                if elapsed[index] >= SimConstants.ignitionDelay {
                    cells[index] = .burning
                    elapsed[index] = 0
                }
            case .burning:
                elapsed[index] += dt
                if elapsed[index] >= SimConstants.burnDuration {
                    cells[index] = .burnt
                    elapsed[index] = 0
                }
            case .unburnt, .burnt:
                break
            }
        }

        // Phase 3 — apply this tick's ignitions (they wait a full IGNITION_DELAY from next tick).
        for index in newlyIgnited {
            cells[index] = .igniting
            elapsed[index] = 0
        }
    }

    /// The burn state of a cell (off-grid reads as unburnt).
    public func state(at cell: GridCoord) -> Cell {
        guard let index = size.index(of: cell) else { return .unburnt }
        return cells[index]
    }

    /// Burning + igniting cells — the set that is both impassable (flow field routes around it) and
    /// harmful (an agent standing here is being burned).
    public var activeFire: Set<GridCoord> {
        var result: Set<GridCoord> = []
        for index in cells.indices where cells[index] == .burning || cells[index] == .igniting {
            result.insert(size.coord(atIndex: index))
        }
        return result
    }

    /// Cells actively burning — the smoke sources (igniting cells smoulder but don't yet produce).
    public var burningCells: [GridCoord] {
        cells.indices.filter { cells[$0] == .burning }.map { size.coord(atIndex: $0) }
    }

    /// Fire intensity per lit cell for the render snapshot — igniting dimmer than a full burn.
    public var intensity: [GridCoord: Double] {
        var result: [GridCoord: Double] = [:]
        for index in cells.indices {
            switch cells[index] {
            case .igniting: result[size.coord(atIndex: index)] = 0.4
            case .burning: result[size.coord(atIndex: index)] = 1.0
            case .unburnt, .burnt: break
            }
        }
        return result
    }

    /// The 8-neighbourhood in a fixed order (orthogonal first), each tagged whether it is diagonal.
    private func neighbours(of cell: GridCoord) -> [(GridCoord, Bool)] {
        [
            (GridCoord(cell.x, cell.y - 1), false),
            (GridCoord(cell.x, cell.y + 1), false),
            (GridCoord(cell.x - 1, cell.y), false),
            (GridCoord(cell.x + 1, cell.y), false),
            (GridCoord(cell.x - 1, cell.y - 1), true),
            (GridCoord(cell.x + 1, cell.y - 1), true),
            (GridCoord(cell.x - 1, cell.y + 1), true),
            (GridCoord(cell.x + 1, cell.y + 1), true),
        ]
    }
}
