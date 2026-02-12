extension Folio {
    public func resolved() -> Folio {
        var result = self
        for (trigger, patchList) in self.patches {
            guard completionStatuses[trigger] != true else { continue }
            for patch in patchList {
                let current =
                    result.balances[patch.target]
                    ?? Amount(0, decimals: patch.delta.decimals)
                result.balances[patch.target] = current + patch.delta
            }
        }
        return result
    }
}
