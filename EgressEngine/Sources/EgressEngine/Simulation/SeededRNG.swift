/// Deterministic `RandomNumberGenerator` — the source of every stochastic choice in the
/// engine (agent placement, trait sampling, hazard spread). A given seed reproduces a run
/// bit-for-bit, which is what makes the demo repeatable and the tests meaningful.
///
/// Algorithm: SplitMix64 — fast, well-distributed, and identical across platforms and
/// Swift versions (no dependence on the standard library's system RNG).
public struct SeededRNG: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
