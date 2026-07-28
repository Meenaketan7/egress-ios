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
}
