extension Result {
    public var failure: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
