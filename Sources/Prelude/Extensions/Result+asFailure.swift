public extension Result {
    var asFailure: Failure {
        if case .failure(let e) = self { return e }
        preconditionFailure("asFailure used on success")
    }
}
