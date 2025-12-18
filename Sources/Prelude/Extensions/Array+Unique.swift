import Foundation

extension Array where Element: Hashable {
    /// Return the unique values in the array in the same order
    /// as the original array
    public func unique() -> [Element] {
        var uniqueValues: [Element] = []

        forEach { item in
            guard !uniqueValues.contains(item) else {
                return
            }
            uniqueValues.append(item)
        }

        return uniqueValues
    }

    /// Appends an element to the array only if the element doesn't currently exist
    public func appendUnique(_ value: Element) -> [Element] {
        var copy: [Element] = self

        if !self.contains(value) {
            copy += [value]
        }

        return copy
    }
}
