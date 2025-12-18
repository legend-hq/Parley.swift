public protocol FormattableNumeric: Equatable {
    var isZero: Bool { get }

    func formatted() -> String
}
