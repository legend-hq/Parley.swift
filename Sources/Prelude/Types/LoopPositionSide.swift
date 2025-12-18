/// The exposure direction of a Loop position
public enum LoopPositionSide: String, Identifiable, Sendable {
    case long = "Long"
    case short = "Short"

    public var id: Self { self }

    public var isLong: Bool {
        self == .long
    }
}
