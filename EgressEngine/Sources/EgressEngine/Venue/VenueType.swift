/// Category of venue — drives presets, defaults, and display.
public enum VenueType: String, CaseIterable, Hashable, Sendable {
    case office
    case nightclub
    case concertHall
    case retail
    case transitHub
    case classroom
    case stadium

    public var displayName: String {
        switch self {
        case .office: "Office"
        case .nightclub: "Nightclub"
        case .concertHall: "Concert Hall"
        case .retail: "Retail"
        case .transitHub: "Transit Hub"
        case .classroom: "Classroom"
        case .stadium: "Stadium"
        }
    }

    /// Reasoned egress goal for this venue's preset footprint (§2.9), in seconds — the target the
    /// Safety Score's time term and the run cap are measured against. An educational default, **not**
    /// a certified standard.
    public var clearanceTarget: Double {
        switch self {
        case .office: 150
        case .nightclub: 120
        case .concertHall: 180
        case .retail: 150
        case .transitHub: 240
        case .classroom: 180
        case .stadium: 240
        }
    }
}
