extension Sequence where Element: AdditiveArithmetic {
    public func sum() -> Element {
        return reduce(.zero, +)
    }
}
