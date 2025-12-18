import Charter

/// For ``ActionContext``s as they are convertible to ``Action``s with data from ``Portfolio``s.
public protocol ActionConvertible {
    func toAction(portfolios: [Portfolio]) -> Action?
}
