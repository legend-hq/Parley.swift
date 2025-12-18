import Foundation

extension Array {
    public func stablePartition(predicate: (Element) -> Bool) -> [Element] {
        let matching = filter(predicate)
        let nonMatching = filter { !predicate($0) }

        return matching + nonMatching
    }
}
