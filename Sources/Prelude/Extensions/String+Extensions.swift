import Foundation

extension String {
    /// Shortens a string, uses prefix characters, a ... separator and then suffix characters if
    /// the string is longer than prefix + suffix
    ///
    /// ```
    ///"0xd8da6bf26964af9d7eed9e03e53415d37aa96045".shortened(withPrefix: 5, andSuffix: 3)
    ///// Returns "0xd8d...045"
    ///
    /// ```
    public func shortened(withPrefix prefix: Int, andSuffix suffix: Int) -> String {
        if prefix + suffix < count {
            return "\(self.prefix(prefix))...\(self.suffix(suffix))"
        }

        return self
    }

    /// String equality ignoring the case
    public func equalIgnoringCase(_ other: String) -> Bool {
        self.uppercased() == other.uppercased()
    }
}
